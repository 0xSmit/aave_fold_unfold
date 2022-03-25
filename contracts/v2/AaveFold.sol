// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.6.12;

import "./aave/FlashLoanReceiverBaseV2.sol";
import "interfaces/v2/ILendingPoolAddressesProviderV2.sol";
import "interfaces/v2/ILendingPoolV2.sol";
import "hardhat/console.sol";

contract AaveFold is FlashLoanReceiverBaseV2, Withdrawable {
    uint256[] private modes = [uint256(0)];

    constructor(address _addressProvider) public FlashLoanReceiverBaseV2(_addressProvider) {}

    function foldPosition(
        address asset,
        uint256 inputAmount,
        uint256 LTV,
        address behalfAddress
    ) external nonZero(inputAmount) {
        (address[] memory assets, uint256[] memory loanAmount) = (new address[](1), new uint256[](1));
        (assets[0], loanAmount[0]) = (asset, getLoanAmount(inputAmount, LTV));

        bytes memory params = abi.encode(inputAmount, LTV, behalfAddress, uint8(1));

        LENDING_POOL.flashLoan(address(this), assets, loanAmount, modes, behalfAddress, params, uint16(0));
    }

    function unFoldPosition(
        address asset,
        uint256 debtToRepay,
        uint256 LTV,
        address behalfAddress
    ) external nonZero(debtToRepay) {
        (address[] memory assets, uint256[] memory loanAmount) = (new address[](1), new uint256[](1));
        (assets[0], loanAmount[0]) = (asset, debtToRepay);

        bytes memory params = abi.encode(debtToRepay, LTV, behalfAddress, uint8(2));

        LENDING_POOL.flashLoan(address(this), assets, loanAmount, modes, behalfAddress, params, uint16(0));
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address,
        bytes memory params
    ) external override returns (bool) {
        // Received Flash loan
        (uint256 inputAmount, uint256 LTV, address onBehalfOf, uint8 txType) = abi.decode(params, (uint256, uint256, address, uint8));

        console.log("executeOp:inputAmount:", inputAmount);
        console.log("executeOp:LTV:", LTV);
        console.log("executeOp:onBehalfOf:", onBehalfOf);
        console.log("executeOp:txType:", txType);
        console.log("executeOp:asset", assets[0]);
        console.log("executeOp:amount", amounts[0]);
        console.log("executeOp:premium", premiums[0]);

        // FOLD
        if (txType == uint8(1)) {
            return _foldInternal(assets[0], inputAmount, LTV, onBehalfOf, amounts[0], premiums[0]);
        }
        // UNFOLD
        else if (txType == uint8(2)) {
            return _unfoldInternal(assets[0], inputAmount, LTV, onBehalfOf, amounts[0], premiums[0]);
        }
    }

    function _foldInternal(
        address asset,
        uint256 inputAmount,
        uint256 LTV,
        address onBehalfOf,
        uint256 flashAmount,
        uint256 premium
    ) private returns (bool) {
        //Receive the input tokens to self Address
        transferTokensToSelf(asset, onBehalfOf, inputAmount);

        uint256 amountOwed = flashAmount.add(premium);
        console.log("_foldInternal:amountOwed", amountOwed);

        //AmtToLend = flahLoanAmount + initialInput amount from user
        uint256 lendAmount = flashAmount.add(inputAmount).sub(premium);
        console.log("_foldInternal:lendAmount", lendAmount);

        grantAllowance(asset, address(LENDING_POOL), lendAmount);

        //Lend the amount to Lending Pool
        LENDING_POOL.deposit(asset, lendAmount, onBehalfOf, uint16(0));
        console.log("_foldInternal:", "Deposit Successful");

        // Borrow the amount of tokens taken as flash loan - premium
        uint256 borrowAmount = amountOwed.sub(premium);
        console.log("_foldInternal:borrowAmount", borrowAmount);
        LENDING_POOL.borrow(asset, borrowAmount, uint256(2), uint16(0), onBehalfOf);
        console.log("_foldInternal:", "Borrow Successful");

        // Pay back flash loan
        // Should have (x+y) collateral, y debt with net interest rate ((x+y)*(deposit rate) - (y)*(borrowing rate))%

        //Grant allowance to leanding pool to sweep funds
        grantAllowance(asset, address(LENDING_POOL), amountOwed);

        //balance of current contract
        uint256 contractBalance = IERC20(asset).balanceOf(address(this));
        console.log("_foldInternal:contractBalance", contractBalance);

        return true;
    }

    function _unfoldInternal(
        address asset,
        uint256 debtToRepay,
        uint256 LTV,
        address onBehalfOf,
        uint256 flashAmount,
        uint256 premium
    ) private returns (bool) {
        // Repay debt using flash loan
        grantAllowance(asset, address(LENDING_POOL), debtToRepay);
        LENDING_POOL.repay(asset, debtToRepay, uint256(1), onBehalfOf);

        // Withdraw collateral
        uint256 collateralAmount = debtToRepay.add(premium); // -1 to withdraw all collateral
        LENDING_POOL.withdraw(asset, collateralAmount, onBehalfOf);

        // Using collateral, pay back flash loan

        // At end, contract owes flashloaned amounts + premiums
        // Need to ensure enough contract has enough to repay amounts

        //Grant allowance to leanding pool to sweep funds
        grantAllowance(asset, address(LENDING_POOL), collateralAmount);
        return true;
    }

    // * ======== HELPER FUNCTIONS ======== * //

    function getLoanAmount(uint256 input, uint256 LTV) internal pure returns (uint256) {
        //input = 100 * inp / 100 - ltv
        return input.mul(uint256(100)).div(uint256(100).sub(LTV));
    }

    function grantAllowance(
        address asset,
        address spender,
        uint256 amount
    ) internal {
        IERC20(asset).approve(address(spender), amount);
    }

    function transferTokensToSelf(
        address asset,
        address owner,
        uint256 amount
    ) internal {
        IERC20(asset).transferFrom(owner, address(this), amount);
    }

    // * ======== Modifiers ======== * //

    modifier nonZero(uint256 x) {
        require(x > 0, "Amount must be greater than 0");
        _;
    }
}
