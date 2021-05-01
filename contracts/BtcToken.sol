pragma solidity ^0.8.4;

import "./utils/Safemath.sol";
import "./extensions/Ownable.sol";
import "./extensions/ERC20.sol";
import "./extensions/Saleable.sol";


abstract contract BtcToken is ERC20, Ownable, Saleable {
    using SafeMath for uint256;

    uint8 constant exp = 3;

    //        constructor(uint256 _initialSupply, uint256 _tokenPrice, uint256 _tokensAvailable) ERC20('Yunis Token', 'YUN') {
    //            admin = msg.sender;
    //            _balances[msg.sender] = _initialSupply;
    //            _totalSupply = _initialSupply;
    //            tokenPrice = _tokenPrice;
    //            tokenAvailableForSale = _tokensAvailable;
    //        }

    function _currentPrice() public view returns (uint256){
        return 3 ** (tokensSold / 10 + 1);
    }

    function buyTokens(uint256 _numberOfTokens) public payable returns (bool){
        //Check Tokens re on the sale
        require(onSale);

        //Require that value is equal to tokens
        require(msg.value == _numberOfTokens.mul(_currentPrice()));

        //Send tokens
        _balances[msg.sender] += _numberOfTokens;

        //Require that a transfer is successful
        tokensSold += _numberOfTokens;

        //Trigger Sell event
        emit Sell(msg.sender, _numberOfTokens);
        return true;
    }

}
