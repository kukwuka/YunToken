const YunToken = artifacts.require("YunToken");
const BtcToken = artifacts.require("BtcToken");
const YunBtcCake = artifacts.require("YunBtcCake");

module.exports = async (deployer) => {
    // Token price is 0.001 Ether
    const tokenPrice = 100000000;
    const totalSupplyYun = 1000000;
    const _tokensAvailable = totalSupplyYun * 0.75;
    const totalSupplyBtc = 10000;
    await deployer.deploy(YunToken, totalSupplyYun, tokenPrice, _tokensAvailable);
    await deployer.deploy(BtcToken, totalSupplyBtc);
    await deployer.deploy(YunBtcCake, BtcToken.address, YunToken.address);
};