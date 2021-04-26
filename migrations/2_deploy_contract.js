const YunToken = artifacts.require("YunToken");

module.exports = function (deployer) {
    // Token price is 0.001 Ether
    const tokenPrice = 1000000000000000;
    const  totalSupply = 1000000;
    const _tokensAvailable = totalSupply * 0.75;
    deployer.deploy(YunToken, totalSupply,tokenPrice,_tokensAvailable);
};