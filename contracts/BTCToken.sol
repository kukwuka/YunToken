pragma solidity ^0.8.4;

import "./utils/Safemath.sol";
import "./extensions/ERC20.sol";


abstract contract BTCToken is IERC20 {
    using SafeMath for uint256;
}
