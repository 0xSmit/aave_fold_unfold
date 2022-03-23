// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.6.12;

import "./aave/FlashLoanReceiverBaseV2.sol";
import "interfaces/v2/ILendingPoolAddressesProviderV2.sol";
import "interfaces/v2/ILendingPoolV2.sol";

contract FlashloanWind is FlashLoanReceiverBaseV2, Withdrawable {
    
    address onBehalfOf;
    uint256 LTV;
    uint16 referralCode;
    uint256 inputAmount;
    constructor(address _addressProvider)
    public
    FlashLoanReceiverBaseV2(_addressProvider)
    {}

    // function setAsset(string memory _symbol) internal returns (address, uint256) {
    //     // if(keccak256(bytes(_symbol)) == keccak256(bytes("USDT"))){
    //     //     assets[0] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    //     //     }
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("WBTC"))){
    //         return (address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599), 70);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("WETH"))){
    //         return (address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), 80);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("YFI"))){
    //         return (address(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e),50);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("ZRX"))){
    //         return (address(0xE41d2489571d322189246DaFA5ebDe1F4699F498),65);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("UNI"))){
    //         return (address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984),60);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("AAVE"))){
    //         return (address(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9),60);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("BAT"))){
    //         return (address(0x0D8775F648430679A709E98d2b0Cb6250d2887EF),75);}
    //     // if(keccak256(bytes(_symbol)) == keccak256(bytes("BUSD"))){
    //     //     assets[0] = address(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
    //     //     LTV = 7;}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("DAI"))){
    //         return (address(0x6B175474E89094C44Da98b954EedeAC495271d0F),75);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("ENJ"))){
    //         return (address(0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c),60);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("KNC"))){
    //         return (address(0xdd974D5C2e2928deA5F71b9825b8b646686BD200),60);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("LINK"))){
    //         return (address(0x514910771AF9Ca656af840dff83E8264EcF986CA),70);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("MANA"))){
    //         return (address(0x0F5D2fB29fb7d3CFeE444a200298f468908cC942),65);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("MKR"))){
    //         return (address(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2),65);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("REN"))){
    //         return (address(0x408e41876cCCDC0F92210600ef50372656052a38),60);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("SNX"))){
    //         return (address(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F),40);}
    //     // if(keccak256(bytes(_symbol)) == keccak256(bytes("sUSD"))){
    //     //     assets[0] = address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
    //     //     LTV = 7;}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("TUSD"))){
    //         return (address(0x0000000000085d4780B73119b644AE5ecd22b376),75);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("USDC"))){
    //         return (address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),80);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("CRV"))){
    //         return (address(0xD533a949740bb3306d119CC777fa900bA034cd52),45);}
    //     // if(keccak256(bytes(_symbol)) == keccak256(bytes("GUSD"))){
    //     //     assets[0] = address(0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd);
    //     //     LTV = 7;}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("BAL"))){
    //         return (address(0xba100000625a3754423978a60c9317c58a424e3D),65);}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("xSUSHI"))){
    //         return (address(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272),45);}
    //     // if(keccak256(bytes(_symbol)) == keccak256(bytes("renFIL"))){
    //     //     assets[0] = address(0xD5147bc8e386d91Cc5DBE72099DAC6C9b99276F5);
    //     //     LTV = 7;}
    //     // if(keccak256(bytes(_symbol)) == keccak256(bytes("RAI"))){
    //     //     assets[0] = address(0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919);
    //     //     LTV = 7;}
    //     // if(keccak256(bytes(_symbol)) == keccak256(bytes("AMPL"))){
    //     //     assets[0] = address(0xD46bA6D942050d489DBd938a2C909A5d5039A161);
    //     //     LTV = 7;}
    //     if(keccak256(bytes(_symbol)) == keccak256(bytes("DPI"))){
    //         return (address(0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b),60);}
    //     // if(keccak256(bytes(_symbol)) == keccak256(bytes("FRAX"))){
    //     //     assets[0] = address(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    //     //     LTV = 7;}
    //     // if(keccak256(bytes(_symbol)) == keccak256(bytes("FEI"))){
    //     //     assets[0] = address(0x956F47F50A910163D8BF957Cf5846D573E7f87CA);
    //     //     LTV = 7;}
    // }

    function setAsset(address _asset) internal returns (address) {
        return _asset;
    }

    function setLTV(uint256 _LTV) internal returns (uint256){
        return _LTV;
    }


    function setInputAmount(uint256 _x) internal returns (uint256) {
        require(_x > 0);
        inputAmount = _x;
        return (inputAmount/(100 - (LTV/100))) - inputAmount; // Let this be y
    }



    function myFlashLoanCall( 
        address _asset, 
        uint256 _inputAmount,
        uint256 _LTV,
        address _behalfAddress,
        bytes calldata _params) public {

        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        // LENDING_POOL.flashLoan(receiverAddress, assets, amounts, modes, onBehalfOf, params, referralCode);
        assets[0] = setAsset(_asset);
        LTV = setLTV(_LTV);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = setInputAmount(_inputAmount);
        
        onBehalfOf = address(_behalfAddress);
        
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        bytes memory params = "";
        referralCode = 0;

        LENDING_POOL.flashLoan(receiverAddress, assets, amounts, modes, onBehalfOf, params, referralCode);
    }

    function executeOperation (
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
    external
    override
    returns (bool)
    {
        // Contract now has funds
        // Logic below

        // Take user input x
        // Take flash loan of x(1-LTV) - x -> y
        // Deposit x + y into protocol
        IERC20(assets[0]).approve(address(LENDING_POOL), amounts[0]);
        LENDING_POOL.deposit(assets[0], amounts[0] + inputAmount, onBehalfOf, referralCode);
        // Borrow (x+y)*LTV tokens
        uint256 borrowAmount = ((inputAmount + amounts[0])*LTV)/100;
        LENDING_POOL.borrow(assets[0], amounts[0], 1, referralCode, onBehalfOf);
        
        // Pay back flash loan
        // Should have (x+y) collateral, y debt with net interest rate ((x+y)*(deposit rate) - (y)*(borrowing rate))%
        // At end, contract owes flashloaned amounts + premiums
        // Need to ensure enough contract has enough to repay amounts

        for (uint i = 0; i < assets.length; i++){
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }
        return true;
    }
}
