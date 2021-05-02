pragma solidity ^0.8.4;

import "./utils/Safemath.sol";
import "./extensions/Ownable.sol";
import "./extensions/ERC20.sol";
import "./extensions/Saleable.sol";


contract BtcToken is ERC20, Ownable, Saleable {
    using SafeMath for uint256;

    uint8 constant exp = 3;

    constructor(uint256 _initialSupply) ERC20('Bitcoin Token', 'BTC') {
        _balances[msg.sender] = _initialSupply;
        _totalSupply = _initialSupply;
    }

    function currentPrice() public view returns (uint256){
        return 100 ** (tokensSold / 10000 + 1);
    }

    function buyTokens(uint256 _numberOfTokens) public payable returns (bool){
        //Check Tokens re on the sale
        require(onSale);

        //Require that value is equal to tokens
        require(msg.value == _numberOfTokens.mul(currentPrice()),"Don't have enough value");

        //Send tokens
        _balances[msg.sender] += _numberOfTokens;

        //Require that a transfer is successful
        tokensSold += _numberOfTokens;

        //Trigger Sell event
        emit Sell(msg.sender, _numberOfTokens);
        return true;
    }

}
