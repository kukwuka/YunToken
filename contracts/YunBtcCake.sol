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
    event Burn(address indexed sender, uint amountBTC, uint amountYUN);


    function getReserves() public view returns (uint256 _reserveBTC, uint256 _reserveYUN) {
        _reserveBTC = IERC20(btcContract).balanceOf(address(this));
        _reserveYUN = IERC20(yunContract).balanceOf(address(this));
    }

    function removeLiquidity() public {
        uint256 liquidity = balanceOf(msg.sender);
        require(balanceOf(msg.sender) != 0);
        (uint256 _reverseBTC, uint256  _reverseYUN) = getReserves();

        uint256 amountBTC = liquidity.mul(_reverseBTC) / _totalSupply;

        // using balances ensures pro-rata distribution
        uint256 amountYUN = liquidity.mul(_reverseYUN) / _totalSupply;

        IERC20(yunContract).transfer(msg.sender, amountBTC);
        IERC20(btcContract).transfer(msg.sender, amountYUN);

        emit Burn(msg.sender, amountBTC, amountYUN);
    }

    function addLiquidity(uint256 _amountInBtc, uint256 _amountInYun) public returns (uint liquidity) {
        require((_amountInBtc == 0) || (_amountInYun == 0));

        (uint256 _reverseBTC,uint256 _reverseYUN) = getReserves();

        require(
            (_amountInBtc.div(_amountInYun) == _reverseBTC.div(_reverseYUN))
            ||
            (_amountInYun.div(_amountInBtc) == _reverseYUN.div(_reverseBTC)),
            "proportion isn't right"
        );

        require(_reverseBTC > _amountInBtc, "not Enough BTC Token");
        require(_reverseYUN > _amountInYun, "not Enough YUN Token");

        if (_totalSupply == 0) {
            liquidity = 1000;
        } else {
            liquidity = Math.min(
                _amountInBtc.mul(_totalSupply) / _reverseBTC,
                _amountInYun.mul(_totalSupply) / _reverseYUN
            );
        }

        IERC20(btcContract).transferFrom(msg.sender, address(this), _amountInBtc);
        IERC20(yunContract).transferFrom(msg.sender, address(this), _amountInYun);
        _mint(msg.sender, liquidity);
    }


    function buyYunToken(uint256 _amountIn) public {
        require(_amountIn != 0);
        require(IERC20(btcContract).balanceOf(msg.sender) > _amountIn, "not Enough BTC Token");

        (, uint256 _reserveYUN) = getReserves();


        uint256 amountOut = getBtcTokenPrice(_amountIn);
        require(_reserveYUN > amountOut);

        IERC20(btcContract).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(yunContract).transfer(msg.sender, amountOut);
    }


    function buyBtcToken(uint256 _amountIn) public {
        require(_amountIn != 0);
        require(IERC20(yunContract).balanceOf(msg.sender) > _amountIn, "not Enough YUN Token");

        (uint256 _reserveBTC,) = getReserves();


        uint256 amountOut = getBtcTokenPrice(_amountIn);
        require(_reserveBTC > amountOut);

        IERC20(yunContract).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(btcContract).transfer(msg.sender, amountOut);


    }

    function getYunTokenPrice(uint256 _amountIn) public view returns (uint256 amountOut){


        uint256 balanceBTC = IERC20(btcContract).balanceOf(address(this));
        uint256 balanceYUN = IERC20(yunContract).balanceOf(address(this));

        uint256 konstant0 = balanceYUN.mul(balanceBTC);
        //        uint256 konstant1 = balanceYUN.mul(balanceBTC.add(_amount));
        amountOut = balanceYUN - konstant0 / (balanceBTC + _amountIn);
    }


    function getBtcTokenPrice(uint256 _amountIn) public view returns (uint256 amountOut){
        require(IERC20(yunContract).balanceOf(msg.sender) > _amountIn, "not Enough BTC Token");

        uint256 balanceBTC = IERC20(btcContract).balanceOf(address(this));
        uint256 balanceYUN = IERC20(yunContract).balanceOf(address(this));

        uint256 konstant0 = balanceYUN.mul(balanceBTC);
        //        uint256 konstant1 = balanceYUN.mul(balanceBTC.add(_amount));
        amountOut = balanceBTC - konstant0 / (balanceYUN + _amountIn);
    }
}
