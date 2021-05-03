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
        btcContract = _btcContract;
        yunContract = _yunContract;
    }

    event AddLiquidity(address indexed sender, uint256 amountBTC, uint256 amountYUN, uint256 liquidity);
    event RemoveLiquidity(address indexed sender, uint amountBTC, uint amountYUN);
    event BuyBtcToken(address indexed buyer, uint amountOutBTC, uint amountInYUN);
    event BuyYunToken(address indexed buyer, uint amountInBTC, uint amountOutYUN);


    function getReserves() public view returns (uint256 _reserveBTC, uint256 _reserveYUN) {
        _reserveBTC = IERC20(btcContract).balanceOf(address(this));
        _reserveYUN = IERC20(yunContract).balanceOf(address(this));
    }

    function removeLiquidity() public {
        uint256 liquidity = balanceOf(msg.sender);
        require(liquidity != 0);
        (uint256 _reverseBTC, uint256  _reverseYUN) = getReserves();

        uint256 amountBTC = liquidity.mul(_reverseBTC) / _totalSupply - 1;

        // using balances ensures pro-rata distribution
        uint256 amountYUN = liquidity.mul(_reverseYUN) / _totalSupply - 1;


        _burn(msg.sender, liquidity);

        IERC20(yunContract).transfer(msg.sender, amountYUN);
        IERC20(btcContract).transfer(msg.sender, amountBTC);

        emit RemoveLiquidity(msg.sender, amountBTC, amountYUN);
    }

    function addLiquidity(uint256 _amountInBtc, uint256 _amountInYun) public returns (uint256 liquidity) {
        require((_amountInBtc != 0) || (_amountInYun != 0), "arguments can not be equal zero");
        (uint256 _reverseBTC,uint256 _reverseYUN) = getReserves();

        if (_totalSupply == 0) {
            liquidity = 1000;
        } else {
            require(
                (_amountInBtc.div(_amountInYun) == _reverseBTC.div(_reverseYUN))
                ||
                (_amountInYun.div(_amountInBtc) == _reverseYUN.div(_reverseBTC)),
                "proportion isn't right"
            );

            liquidity = Math.min(
                _amountInBtc.mul(_totalSupply) / _reverseBTC,
                _amountInYun.mul(_totalSupply) / _reverseYUN
            );
        }
        require(liquidity != 0, "Error");

        IERC20(btcContract).transferFrom(msg.sender, address(this), _amountInBtc);
        IERC20(yunContract).transferFrom(msg.sender, address(this), _amountInYun);
        _mint(msg.sender, liquidity);
        emit AddLiquidity(msg.sender, _amountInBtc, _amountInYun, liquidity);
    }


    function buyYunToken(uint256 _amountIn) public returns (uint256 _amountOut) {
        require(_amountIn != 0);
        require(IERC20(btcContract).balanceOf(msg.sender) > _amountIn, "not Enough BTC Token");

        (, uint256 _reserveYUN) = getReserves();


        _amountOut = getBtcTokenPrice(_amountIn);
        require(_reserveYUN > _amountOut);

        IERC20(btcContract).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(yunContract).transfer(msg.sender, _amountOut);
        emit BuyYunToken(msg.sender, _amountIn, _amountOut);

    }


    function buyBtcToken(uint256 _amountIn) public returns (uint256 _amountOut){
        require(_amountIn != 0);
        require(IERC20(yunContract).balanceOf(msg.sender) > _amountIn, "not Enough YUN Token");

        (uint256 _reserveBTC,) = getReserves();


        _amountOut = getBtcTokenPrice(_amountIn);
        require(_reserveBTC > _amountOut);

        IERC20(yunContract).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(btcContract).transfer(msg.sender, _amountOut);
        emit BuyBtcToken(msg.sender, _amountOut, _amountIn);


    }

    function getYunTokenPrice(uint256 _amountIn) public view returns (uint256 _amountOut){

        (uint256 _reverseBTC, uint256 _reverseYUN) = getReserves();
        _amountOut = _reverseYUN.sub(_reverseYUN.mul(_reverseBTC).div(_reverseBTC.add(_amountIn)));
    }


    function getBtcTokenPrice(uint256 _amountIn) public view returns (uint256 _amountOut){

        (uint256 _reverseBTC, uint256 _reverseYUN) = getReserves();
        _amountOut = _reverseBTC.sub(_reverseBTC.mul(_reverseYUN).div(_reverseYUN.add(_amountIn)));
    }
}
