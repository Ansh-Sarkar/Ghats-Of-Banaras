pragma solidity >=0.6.0 <0.9.0;

// library to make sure that we dont overflow our integers under any circumstance . 256 bits => 32 bytes
library SafeMath {
    // check for integer overflows during addition
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        // if c < a => integer has wrapped around itself . Hence , overflow .
        require(c >= a, "SafeMath : addition overflow");
        return c;
    }
    // check for negative balances during subtraction
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
}