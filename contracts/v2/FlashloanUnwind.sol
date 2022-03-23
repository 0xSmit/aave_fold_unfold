// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.6.12;

import "./aave/FlashLoanReceiverBaseV2.sol";
import "interfaces/v2/ILendingPoolAddressesProviderV2.sol";
import "interfaces/v2/ILendingPoolV2.sol";

contract FlashloanUnwind is FlashLoanReceiverBaseV2, Withdrawable {
    address onBehalfOf;
    uint256 LTV;
    uint16 referralCode;
    uint256 inputAmount;

    constructor(address _addressProvider) public FlashLoanReceiverBaseV2(_addressProvider) {}

    function setAsset(address _asset) internal returns (address) {
        return _asset;
    }

    function setLTV(uint256 _LTV) internal returns (uint256) {
        return _LTV;
    }

    function setDebtAmount(uint256 _debtToRepay) internal returns (uint256) {
        require(_debtToRepay > 0);
        // inputAmount = _x;
        // return (inputAmount/(100 - (LTV/100))) - inputAmount; // Let this be y
        return _debtToRepay;
    }

    function myFlashLoanCall(
        address _asset,
        uint256 _debtToRepay,
        uint256 _LTV,
        address _behalfAddress,
        bytes calldata _params
    ) public {
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = _asset;
        // LENDING_POOL.flashLoan(receiverAddress, assets, amounts, modes, onBehalfOf, params, referralCode);
        assets[0] = setAsset(_asset);
        LTV = setLTV(_LTV);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = setDebtAmount(_debtToRepay);

        onBehalfOf = address(_behalfAddress);

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        bytes memory params = "";
        referralCode = 0;

        LENDING_POOL.flashLoan(receiverAddress, assets, amounts, modes, onBehalfOf, params, referralCode);
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        // Take flash loan

        // Contract now has funds

        // Repay debt using flash loan
        uint256 interestRateMode = 1; // Stable debt

        uint256 debtAmount = amounts[0];

        IERC20(assets[0]).approve(address(LENDING_POOL), debtAmount);
        LENDING_POOL.repay(assets[0], debtAmount, interestRateMode, onBehalfOf);

        // Withdraw collateral
        uint256 collateralAmount = uint256(-1); // -1 to withdraw all collateral
        address to = onBehalfOf;
        LENDING_POOL.withdraw(assets[0], collateralAmount, to);

        // Using collateral, pay back flash loan

        // At end, contract owes flashloaned amounts + premiums
        // Need to ensure enough contract has enough to repay amounts

        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }
        return true;
    }
}
