pragma solidity ^0.6.12;

contract Test {
    function run() external view returns(uint256) {
        return 18447109473327002950988 & ~0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF;
    }
}