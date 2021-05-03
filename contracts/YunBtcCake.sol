pragma solidity ^0.8.4;

import "./BtcToken.sol";
import "./YunToken.sol";
import "./utils/Safemath.sol";
import "./utils/Math.sol";
import "./extensions/ERC20.sol";
import "./extensions/ERC20.sol";
import "./interfaces/IERC20.sol";

contract YunBtcCake is ERC20 {
    BtcToken public btcContract;
    YunToken public yunContract;
    using SafeMath for uint256;

    constructor(BtcToken _btcContract, YunToken _yunContract) ERC20('Cake token for Bitcoin and Yunis', 'YB-LP'){
        //save YUN and BTC token

        btcContract = _btcContract;
        yunContract = _yunContract;
    }

    event AddLiquidity(address indexed sender, uint256 amountBTC, uint256 amountYUN, uint256 liquidity);
    event RemoveLiquidity(address indexed sender, uint amountBTC, uint amountYUN);
    event BuyBtcToken(address indexed buyer, uint amountOutBTC, uint amountInYUN);
    event BuyYunToken(address indexed buyer, uint amountInBTC, uint amountOutYUN);


    function getReserves() public view returns (uint256 _reserveBTC, uint256 _reserveYUN) {
        //balance of contract address is reverses

        _reserveBTC = IERC20(btcContract).balanceOf(address(this));
        _reserveYUN = IERC20(yunContract).balanceOf(address(this));
    }

    function removeLiquidity() public {
        //get balance LP
        uint256 liquidity = balanceOf(msg.sender);

        //have some LP tokens
        require(liquidity != 0);

        //get reservoirs
        (uint256 _reverseBTC, uint256  _reverseYUN) = getReserves();

        //like liquidity * reverseBTC / totalSupply -1
        uint256 amountBTC = liquidity.mul(_reverseBTC) / _totalSupply - 1;

        // like liquidity * reverseYUN / totalSupply -1
        uint256 amountYUN = liquidity.mul(_reverseYUN) / _totalSupply - 1;

        //fee is 1 BTC token and 1 Yun token


        //delete LP tokens
        _burn(msg.sender, liquidity);

        //send tokens
        IERC20(yunContract).transfer(msg.sender, amountYUN);
        IERC20(btcContract).transfer(msg.sender, amountBTC);


        emit RemoveLiquidity(msg.sender, amountBTC, amountYUN);
    }

    function addLiquidity(uint256 _amountInBtc, uint256 _amountInYun) public returns (uint256 liquidity) {
        //before calling this function you need to approve count
        // of _amountInBtc tokens in BTC contract and
        // _amountInYun tokens in YUN


        // arguments are not null
        require((_amountInBtc != 0) || (_amountInYun != 0), "arguments can not be equal zero");

        //get reservoirs
        (uint256 _reverseBTC,uint256 _reverseYUN) = getReserves();

        if (_totalSupply == 0) {
            // if totalSupply is zero, first guy will take 1000 LP tokens ,regardless of count of BTC and YUN tokens


            liquidity = 1000;
        } else {

            //check proportion
            require(
                (_amountInBtc.div(_amountInYun) == _reverseBTC.div(_reverseYUN))
                ||
                (_amountInYun.div(_amountInBtc) == _reverseYUN.div(_reverseBTC)),
                "proportion isn't right"
            );

            //count and give minimum liquidity
            liquidity = Math.min(
                _amountInBtc.mul(_totalSupply) / _reverseBTC,
                _amountInYun.mul(_totalSupply) / _reverseYUN
            );
        }

        //liquidity is not zero
        require(liquidity != 0, "Error");

        //take coins
        IERC20(btcContract).transferFrom(msg.sender, address(this), _amountInBtc);
        IERC20(yunContract).transferFrom(msg.sender, address(this), _amountInYun);

        //give LP tokens
        _mint(msg.sender, liquidity);


        emit AddLiquidity(msg.sender, _amountInBtc, _amountInYun, liquidity);
    }


    function buyYunToken(uint256 _amountIn) public returns (uint256 _amountOut) {
        //before calling this function you need to approve count of _amountIn tokens in BTC contract



        //_amountIn not null
        require(_amountIn != 0);

        //have enough tokens
        require(IERC20(btcContract).balanceOf(msg.sender) > _amountIn, "not Enough BTC Token");

        (, uint256 _reserveYUN) = getReserves();

        //get price
        _amountOut = getBtcTokenPrice(_amountIn);

        //have enough YUN in reservoir
        require(_reserveYUN > _amountOut, "not Enough YUN Token in reservoir");

        //take tokens
        IERC20(btcContract).transferFrom(msg.sender, address(this), _amountIn);

        //send tokens
        IERC20(yunContract).transfer(msg.sender, _amountOut);


        emit BuyYunToken(msg.sender, _amountIn, _amountOut);

    }


    function buyBtcToken(uint256 _amountIn) public returns (uint256 _amountOut){
        //before calling this function you need to approve count of _amountIn tokens in YUN contract

        //_amountIn not null
        require(_amountIn != 0);

        //have enough tokens
        require(IERC20(yunContract).balanceOf(msg.sender) > _amountIn, "not Enough YUN Token");

        (uint256 _reserveBTC,) = getReserves();

        //get price
        _amountOut = getBtcTokenPrice(_amountIn);

        //have enough BTC in reservoir
        require(_reserveBTC > _amountOut, "not Enough BTC Token in reservoir");

        //take tokens
        IERC20(yunContract).transferFrom(msg.sender, address(this), _amountIn);

        //send tokens
        IERC20(btcContract).transfer(msg.sender, _amountOut);


        emit BuyBtcToken(msg.sender, _amountOut, _amountIn);


    }

    function getYunTokenPrice(uint256 _amountIn) public view returns (uint256 _amountOut){
        //how many YUN tokens will get for BTC count in _amountIn

        (uint256 _reverseBTC, uint256 _reverseYUN) = getReserves();

        //like reverseYUN - (reverseYUN * reverseBTC / (reverseBTC + amountIn ))
        _amountOut = _reverseYUN.sub(_reverseYUN.mul(_reverseBTC).div(_reverseBTC.add(_amountIn)));
    }


    function getBtcTokenPrice(uint256 _amountIn) public view returns (uint256 _amountOut){
        //how many BTC tokens will get for YUN in _amountIn

        (uint256 _reverseBTC, uint256 _reverseYUN) = getReserves();
        //like reverseBTC - (reverseBTC * reverseYUN / (reverseYUN+ amountIn ))
        _amountOut = _reverseBTC.sub(_reverseBTC.mul(_reverseYUN).div(_reverseYUN.add(_amountIn)));
    }
}
