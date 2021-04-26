pragma solidity ^0.8.4;

import "./Safemath.sol";

contract YunToken {
    using SafeMath for uint256;

    //Settings
    string public name = "Yunis Token";
    string public symbol = "YUN";
    string public standard = "Yunis Token v1.0";

    //ERC-20
    uint public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    //Casino
    uint256 private randNonceCasino = 0;

    //Selling
    bool public onSale = true;
    address admin;
    uint256 public  tokenPrice;
    uint256 public tokensSold;
    uint256 private tokenAvailableForSale;

    //Events

    //Transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    //Approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //Casino
    //Roulette
    event Roulette(address _player, uint256 _reward);
    //SlotMachine
    event SlotMachine(address _player, uint256 _reward, uint[3] _wheelsValues);

    //Selling
    event Sell(address _buyer, uint256 _amount);
    event StopSelling();
    event StartSelling();
    event SetTokenPrice(uint256 _tokenPrice);



    constructor(uint256 _initialSupply, uint256 _tokenPrice, uint256 _tokensAvailable) {
        admin = msg.sender;
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
        tokenPrice = _tokenPrice;
        tokenAvailableForSale = _tokensAvailable;
    }

    //ERC-20
    //__________________________________________________________________________________________________________________
    //Transfer
    function transfer(address _to, uint256 _value) public returns (bool success){
        //Exception if account doesn't have enough
        require(balanceOf[msg.sender] >= _value);
        //Transfer the balance
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        //Transfer Event
        emit Transfer(msg.sender, _to, _value);
        //Return boolean
        return true;
    }

    //Approve
    function approve(address _spender, uint256 _value) public returns (bool success){
        //allowance
        allowance[msg.sender][_spender] = _value;
        //Approve event
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //Transfer From
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        //require _from has enough tokens
        require(_value <= balanceOf[_from]);

        //require allowance is big enough
        require(_value <= allowance[_from][msg.sender]);

        //change the balance
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        //update the allowance
        allowance[_from][msg.sender] -= _value;

        //Transfer event
        emit Transfer(_from, _to, _value);

        //return true
        return true;
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
        balanceOf[msg.sender] += _numberOfTokens;

        //Require that a transfer is successful
        tokensSold += _numberOfTokens;

        //Reduce available tokens for selling
        tokenAvailableForSale -= _numberOfTokens;

        //Trigger Sell event
        emit Sell(msg.sender, _numberOfTokens);
        return true;
    }

    function stopSale() public {
        //Require admin
        require(msg.sender == admin);

        onSale = false;
        emit StopSelling();
    }

    function startSale() public {
        //Require admin
        require(msg.sender == admin);

        onSale = true;
        emit StartSelling();
    }

    function setTokenPrice(uint256 _tokenPrice) public {
        //Require admin
        require(msg.sender == admin);


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
        require(balanceOf[msg.sender] >= 1);

        //Correctly input arguments
        require(_color < 3);
        require(_value < 37);

        //Client pay token for spinning
        balanceOf[msg.sender] -= 1;

        _value_casino = rand(37);
        _color_casino = rand(2);

        //  If Zero                                 //If other color or number
        if (((_value == 0) && (_value_casino == 0)) || ((_value == _value_casino) && (_color == _color_casino))) {
            // If ZERO
            //Pay reward
            reward = 1000;
            balanceOf[msg.sender] += reward;
        }

        emit Roulette(msg.sender, reward);
        return (_value_casino, _color_casino, reward);
    }


    //Slot-machine
    function slotMachine() public returns (uint[3] memory wheelsValues, uint reward){
        //Exception if account doesn't have enough
        require(balanceOf[msg.sender] >= 1);

        //Client pay token for spinning
        balanceOf[msg.sender] -= 1;

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
        balanceOf[msg.sender] += reward;


        emit SlotMachine(msg.sender, reward, wheelsValues);
        return (wheelsValues, reward);
    }
}
