pragma solidity ^0.8.4;

import "./Ownable.sol";

contract Saleable is Ownable {
    bool public onSale = true;
    uint256 public tokensSold;

    event Sell(address _buyer, uint256 _amount);
    event StopSelling();
    event StartSelling();

    function stopSale() public onlyOwner {

        onSale = false;
        emit StopSelling();
    }

    function startSale() public onlyOwner {

        onSale = true;
        emit StartSelling();
    }
}
