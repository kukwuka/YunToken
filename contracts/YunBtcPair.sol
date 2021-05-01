pragma solidity ^0.8.4;

import "./BtcToken.sol";
import "./YunToken.sol";
import "./extensions/ERC20.sol";
import "./extensions/ERC20.sol";
import "./interfaces/IERC20.sol";

contract YunBtcCake is ERC20 {
    BtcToken public btcContract;
    YunToken public yunContract;
    using SafeMath for uint256;

    constructor(BtcToken _btcContract, YunToken _yunContract) ERC20('CAKE-YB', 'YB-LP'){
        btcContract = _btcContract;
        yunContract = _yunContract;
    }

    function getReserves() public view returns (uint256 _reserveBTC, uint256 _reserveYUN) {
        _reserveBTC = IERC20(btcContract).balanceOf(msg.sender);
        _reserveYUN = IERC20(yunContract).balanceOf(msg.sender);
    }

    function addLiquidity(uint256 _amountInBtc, uint256 _amountInYun) public returns (uint liquidity) {
        require((_amountInBtc == 0) || (_amountInYun == 0));
        //        uint256 BtcYunRelation = balanceBTC.div(balanceYUN);
        //        uint256 YunBtcRelation = balanceYUN.div(balanceBTC);




        require(IERC20(btcContract).balanceOf(msg.sender) > _amountInBtc, "not Enough BTC Token");
        require(IERC20(yunContract).balanceOf(msg.sender) > _amountInYun, "not Enough YUN Token");

        uint256 balanceBTC = IERC20(btcContract).balanceOf(address(this));
        uint256 balanceYUN = IERC20(yunContract).balanceOf(address(this));


        if (_totalSupply == 0) {
            _mint(msg.sender, 10);
        } else {
            if (balanceBTC > balanceYUN) {
                uint256 BtcYunRelation = balanceBTC.div(balanceYUN);
                BtcYunRelation = 0;

            } else {
                uint256 YunBtcRelation = balanceYUN.div(balanceBTC);
                YunBtcRelation = 0;

            }
        }
        return 1;


        //        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        //        // gas savings
        //
        //        uint amount0 = balance0.sub(_reserve0);
        //        uint amount1 = balance1.sub(_reserve1);
        //
        //        bool feeOn = _mintFee(_reserve0, _reserve1);
        //        uint _totalSupply = totalSupply;
        //        // gas savings, must be defined here since totalSupply can update in _mintFee
        //        if (_totalSupply == 0) {
        //            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
        //            _mint(address(0), MINIMUM_LIQUIDITY);
        //            // permanently lock the first MINIMUM_LIQUIDITY tokens
        //        } else {
        //            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        //        }
        //        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        //        _mint(to, liquidity);
        //
        //        _update(balance0, balance1, _reserve0, _reserve1);
        //        if (feeOn) kLast = uint(reserve0).mul(reserve1);
        //        // reserve0 and reserve1 are up-to-date
        //        emit Mint(msg.sender, amount0, amount1);
    }


    function buyYunToken(uint256 _amountIn) public {
        require(_amountIn != 0);
        require(IERC20(btcContract).balanceOf(msg.sender) > _amountIn, "not Enough BTC Token");

        (, uint256 _reserveYUN) = getReserves();


        uint256 amountOut = getBtcTokenPrice(_amountIn);
        require(_reserveYUN > _amountIn);

        IERC20(btcContract).transferFrom(msg.sender, address(this), _amountIn);
        IERC20(yunContract).transfer(msg.sender, amountOut);


    }


//    function buyBtcToken(uint256 _amountIn) public {
//        require(_amountIn != 0);
//        require(IERC20(yunContract).balanceOf(msg.sender) > _amountIn, "not Enough YUN Token");
//
//        (uint256 _reserveBTC, ) = getReserves();
//
//
//        uint256 amountOut = getBtcTokenPrice(_amountIn);
//        require(_reserveYUN > _amountIn);
//
//        IERC20(btcContract).transferFrom(msg.sender, address(this), _amountIn);
//        IERC20(yunContract).transfer(msg.sender, amountOut);
//
//
//    }

    function getYunTokenPrice(uint256 _amountIn) public view returns (uint256){


        uint256 balanceBTC = IERC20(btcContract).balanceOf(address(this));
        uint256 balanceYUN = IERC20(yunContract).balanceOf(address(this));

        uint256 konstant0 = balanceYUN.mul(balanceBTC);
        //        uint256 konstant1 = balanceYUN.mul(balanceBTC.add(_amount));
        uint256 amountOut = balanceYUN - konstant0 / (balanceBTC + _amountIn);
        return amountOut;
    }


    function getBtcTokenPrice(uint256 _amountIn) public view returns (uint256){
        require(IERC20(yunContract).balanceOf(msg.sender) > _amountIn, "not Enough BTC Token");

        uint256 balanceBTC = IERC20(btcContract).balanceOf(address(this));
        uint256 balanceYUN = IERC20(yunContract).balanceOf(address(this));

        uint256 konstant0 = balanceYUN.mul(balanceBTC);
        //        uint256 konstant1 = balanceYUN.mul(balanceBTC.add(_amount));
        uint256 amountOut = balanceBTC - konstant0 / (balanceYUN + _amountIn);
        return amountOut;
    }


}
