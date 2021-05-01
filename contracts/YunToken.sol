pragma solidity ^0.8.4;

import "./utils/Safemath.sol";
import "./extensions/Ownable.sol";
import "./extensions/ERC20.sol";
import "./extensions/Saleable.sol";

contract YunToken is ERC20, Ownable,Saleable {
    using SafeMath for uint256;

    //Casino
    uint256 private randNonceCasino = 0;

    //Selling
    uint256 public  tokenPrice;
    uint256 private tokenAvailableForSale;

    //Events
    //Casino
    //Roulette
    event Roulette(address _player, uint256 _reward);
    //SlotMachine
    event SlotMachine(address _player, uint256 _reward, uint[3] _wheelsValues);

    //Selling

    event SetTokenPrice(uint256 _tokenPrice);



    constructor(uint256 _initialSupply, uint256 _tokenPrice, uint256 _tokensAvailable) ERC20('Yunis Token', 'YUN') {
        _balances[msg.sender] = _initialSupply;
        _totalSupply = _initialSupply;
        tokenPrice = _tokenPrice;
        tokenAvailableForSale = _tokensAvailable;
    }

    //Selling Tokens
    //__________________________________________________________________________________________________________________
    function buyTokens(uint256 _numberOfTokens) public payable returns (bool){
        //Check Tokens re on the sale
        require(onSale);

        //Require that value is equal to tokens
        require(msg.value == _numberOfTokens.mul(tokenPrice));

        //Require that the available tokens is enough
        require(tokenAvailableForSale >= _numberOfTokens);

        //Send tokens
        _balances[msg.sender] += _numberOfTokens;

        //Require that a transfer is successful
        tokensSold += _numberOfTokens;

        //Reduce available tokens for selling
        tokenAvailableForSale -= _numberOfTokens;

        //Trigger Sell event
        emit Sell(msg.sender, _numberOfTokens);
        return true;
    }

    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {

        //Set token Price
        tokenPrice = _tokenPrice;
        emit SetTokenPrice(_tokenPrice);

    }


    //Casino
    //__________________________________________________________________________________________________________________
    //Random Num
    function rand(uint _modulus) private returns (uint)  {
        randNonceCasino++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonceCasino))) % _modulus;

    }

    //Roulette casino
    function roulette(uint _value, uint _color) public returns (uint _value_casino, uint _color_casino, uint256 reward){
        //Exception if account doesn't have enough
        require(_balances[msg.sender] >= 1);

        //Correctly input arguments
        require(_color < 3);
        require(_value < 37);

        //Client pay token for spinning
        _balances[msg.sender] -= 1;

        _value_casino = rand(37);
        _color_casino = rand(2);

        //  If Zero                                 //If other color or number
        if (((_value == 0) && (_value_casino == 0)) || ((_value == _value_casino) && (_color == _color_casino))) {
            // If ZERO
            //Pay reward
            reward = 1000;
            _balances[msg.sender] += reward;
        }

        emit Roulette(msg.sender, reward);
        return (_value_casino, _color_casino, reward);
    }


    //Slot-machine
    function slotMachine() public returns (uint[3] memory wheelsValues, uint reward){
        //Exception if account doesn't have enough
        require(_balances[msg.sender] >= 1);

        //Client pay token for spinning
        _balances[msg.sender] -= 1;

        reward = 0;
        wheelsValues[0] = rand(5) + 1;
        wheelsValues[1] = rand(5) + 1;
        wheelsValues[2] = rand(5) + 1;


        if ((wheelsValues[0] == 1) && (wheelsValues[1] != 1)) {
            reward = 2;
        } else if ((wheelsValues[0] == 1) && (wheelsValues[1] == 1) && (wheelsValues[2] != 1)) {
            reward = 5;
        } else if ((wheelsValues[0] == 1) && (wheelsValues[1] == 1) && (wheelsValues[2] == 1)) {
            reward = 7;
        } else if ((wheelsValues[0] == 2) && (wheelsValues[1] == 2) && ((wheelsValues[2] == 2) || (wheelsValues[2] == 3))) {
            reward = 10;
        } else if ((wheelsValues[0] == 4) && (wheelsValues[1] == 4) && ((wheelsValues[2] == 4) || (wheelsValues[2] == 3))) {
            reward = 14;
        } else if ((wheelsValues[0] == 5) && (wheelsValues[1] == 5) && ((wheelsValues[2] == 5) || (wheelsValues[2] == 3))) {
            reward = 20;
        } else if ((wheelsValues[0] == 3) && (wheelsValues[1] == 3) && (wheelsValues[2] == 3)) {
            //jackPot
            reward = 250;
        }

        //Pay reward
        _balances[msg.sender] += reward;


        emit SlotMachine(msg.sender, reward, wheelsValues);
        return (wheelsValues, reward);
    }
}
