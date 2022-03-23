// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.6.12;

import "./aave/FlashLoanReceiverBaseV2.sol";
import "interfaces/v2/ILendingPoolAddressesProviderV2.sol";
import "interfaces/v2/ILendingPoolV2.sol";

contract FlashloanWind is FlashLoanReceiverBaseV2, Withdrawable {
    address private onBehalfOf;
    uint256 private LTV;
    uint16 private referralCode = 0;
    uint256 private inputAmount;
    address public immutable receiverAddress;
    uint256[] private modes = [uint256(0)];

    constructor(address _addressProvider) public FlashLoanReceiverBaseV2(_addressProvider) {
        receiverAddress = address(this);
    }

    function windPosition(
        address _asset,
        uint256 _inputAmount,
        uint256 _LTV,
        address _behalfAddress
    ) public {
        LTV = _LTV;
        onBehalfOf = _behalfAddress;
        address[] memory assets = new address[](1);
        assets[0] = _asset;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = getLoanAmount(_inputAmount);

        bytes memory params = "";

        LENDING_POOL.flashLoan(receiverAddress, assets, amounts, modes, onBehalfOf, params, referralCode);
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator, //solhint-disable-line
        bytes calldata params //solhint-disable-line
    ) external override returns (bool) {
        // Received Flash loan

        address _asset = assets[0];

        //Receive the input tokens to self Address
        transferTokensToSelf(_asset, onBehalfOf, inputAmount);

        //AmtToLend = flahLoanAmount + initialInput amount from user
        uint256 lendAmount = amounts[0].add(inputAmount).sub(premiums[0]);

        grantAllowance(_asset, address(LENDING_POOL), lendAmount);

        LENDING_POOL.deposit(_asset, lendAmount, onBehalfOf, referralCode);

        // Borrow (x+y)*LTV tokens
        uint256 borrowAmount = lendAmount.mul(LTV).div(100);
        LENDING_POOL.borrow(_asset, borrowAmount, 1, referralCode, onBehalfOf);

        // Pay back flash loan
        // Should have (x+y) collateral, y debt with net interest rate ((x+y)*(deposit rate) - (y)*(borrowing rate))%

        uint256 amountOwed = amounts[0].add(premiums[0]);

        //Grant allowance to leanding pool to sweep funds
        grantAllowance(_asset, address(LENDING_POOL), amountOwed);
        return true;
    }

    // * ======== HELPER FUNCTIONS ======== * //

    function getLoanAmount(uint256 _x) internal view returns (uint256) {
        require(_x > 0, "Amount must be greater than 0");
        //inpAmt / (100-(LTV/100)) - inpAmt
        return _x.div(uint256(100).sub(LTV.div(100))).sub(_x);
    }

    function grantAllowance(
        address _asset,
        address spender,
        uint256 _amount
    ) internal {
        IERC20(_asset).approve(address(spender), _amount);
    }

    function transferTokensToSelf(
        address _asset,
        address _owner,
        uint256 _amount
    ) internal {
        IERC20(_asset).transferFrom(_owner, address(this), _amount);
    }
}
