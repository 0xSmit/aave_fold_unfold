// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import "./aave/FlashLoanReceiverBaseV2.sol";
import "interfaces/v2/ILendingPoolAddressesProviderV2.sol";
import "interfaces/v2/ILendingPoolV2.sol";
import { DataTypes } from "libraries/v2/DataTypes.sol";
import "hardhat/console.sol";

contract AaveFold is FlashLoanReceiverBaseV2 {
    uint256[] private modes = [uint256(0)];

    //solhint-disable no-empty-blocks
    constructor(address _addressProvider) public FlashLoanReceiverBaseV2(_addressProvider) {}

    function foldPosition(
        address asset,
        uint256 inputAmount,
        uint256 LTV
    ) external nonZero(inputAmount) {
        (address[] memory assets, uint256[] memory loanAmount) = (new address[](1), new uint256[](1));
        (assets[0], loanAmount[0]) = (asset, getLoanAmount(inputAmount, LTV));

        bytes memory params = abi.encode(uint8(1), msg.sender, inputAmount);

        LENDING_POOL.flashLoan(address(this), assets, loanAmount, modes, msg.sender, params, uint16(0));
    }

    function unFoldPosition(address asset) external {
        (address[] memory assets, uint256[] memory loanAmount) = (new address[](1), new uint256[](1));

        //get debt address
        DataTypes.ReserveData memory ReserveData = LENDING_POOL.getReserveData(asset);
        console.log("unfoldPosition:VarTokenAddress", ReserveData.variableDebtTokenAddress);

        //get total user debt
        uint256 totalDebt = IERC20(ReserveData.variableDebtTokenAddress).balanceOf(msg.sender);
        console.log("unfoldPosition:totalDebt", totalDebt);

        (assets[0], loanAmount[0]) = (asset, totalDebt);

        bytes memory params = abi.encode(uint8(2), msg.sender, totalDebt, uint256(0));

        LENDING_POOL.flashLoan(address(this), assets, loanAmount, modes, msg.sender, params, uint16(0));
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address,
        bytes memory params
    ) external override returns (bool) {
        // Received Flash loan
        // (uint8 txType, address onBehalfOf, uint256 inputAmount, uint256 LTV) = abi.decode(params, (uint8, address, uint256, uint256));

        (uint8 txType, address onBehalfOf, uint256 inputAmount) = abi.decode(params, (uint8, address, uint256));

        console.log("executeOp:inputAmount:", inputAmount);
        console.log("executeOp:onBehalfOf:", onBehalfOf);
        console.log("executeOp:txType:", txType);
        console.log("executeOp:asset", assets[0]);
        console.log("executeOp:loanReceived", amounts[0]);
        console.log("executeOp:premium", premiums[0]);

        // FOLD
        if (txType == uint8(1)) {
            return _foldInternal(assets[0], inputAmount, onBehalfOf, amounts[0], premiums[0]);
        }
        // UNFOLD
        else if (txType == uint8(2)) {
            return _unfoldInternal(assets[0], inputAmount, onBehalfOf, amounts[0], premiums[0]);
        }
    }

    function _foldInternal(
        address asset,
        uint256 inputAmount,
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
        console.log("_foldInternal:amountToLend", lendAmount);

        grantAllowance(asset, address(LENDING_POOL), lendAmount);

        LENDING_POOL.deposit(asset, lendAmount, onBehalfOf, uint16(0));
        console.log("_foldInternal:", "Deposit Successful");

        // Borrow (x+y)*LTV tokens
        uint256 borrowAmount = amountOwed;
        console.log("_foldInternal:amountToBorrow", borrowAmount);
        LENDING_POOL.borrow(asset, borrowAmount, uint256(2), uint16(0), onBehalfOf);
        console.log("_foldInternal:", "Borrow Successful");

        // Pay back flash loan
        // Should have (x+y) collateral, y debt with net interest rate ((x+y)*(deposit rate) - (y)*(borrowing rate))%
        grantAllowance(asset, address(LENDING_POOL), amountOwed);

        uint256 balanceLeft = IERC20(asset).balanceOf(address(this));
        console.log("_foldInternal:balanceLeft", balanceLeft);

        //Grant allowance to leanding pool to sweep funds
        return true;
    }

    function _unfoldInternal(
        address asset,
        uint256 debtToRepay,
        address onBehalfOf,
        uint256 flashAmount,
        uint256 premium
    ) private returns (bool) {
        // Repay debt using flash loan
        uint256 amountOwed = flashAmount.add(premium);
        console.log("_unfoldInternal:amountOwed", amountOwed);

        grantAllowance(asset, address(LENDING_POOL), debtToRepay);
        LENDING_POOL.repay(asset, debtToRepay, uint256(2), onBehalfOf);

        DataTypes.ReserveData memory ReserveData = LENDING_POOL.getReserveData(asset);
        uint256 totalDebt = IERC20(ReserveData.variableDebtTokenAddress).balanceOf(onBehalfOf);
        console.log("_unfoldInternal:totalDebtPendingAfterRepay", totalDebt);

        console.log("_unfoldInternal:aTokenAddress", ReserveData.aTokenAddress);

        uint256 aTokenBalance = IERC20(ReserveData.aTokenAddress).balanceOf(onBehalfOf);

        console.log("_unfoldInternal:aTokenBalance", aTokenBalance);

        transferTokensToSelf(ReserveData.aTokenAddress, onBehalfOf, aTokenBalance);

        uint256 aTokensRcvBal = IERC20(ReserveData.aTokenAddress).balanceOf(address(this));
        console.log("_unfoldInternal:aTokensRcvBal", aTokensRcvBal);

        LENDING_POOL.withdraw(asset, type(uint256).max, address(this));

        uint256 amountOfTokensRecv = IERC20(asset).balanceOf(address(this));
        console.log("_unfoldInternal:amountOfTokensRecv", amountOfTokensRecv);

        require(amountOwed <= amountOfTokensRecv, "E1");

        uint256 amountToReturn = amountOfTokensRecv - amountOwed;

        IERC20(asset).transfer(onBehalfOf, amountToReturn);

        grantAllowance(asset, address(LENDING_POOL), amountOwed);

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

//E1 - Not enough balance to repay flashloan
