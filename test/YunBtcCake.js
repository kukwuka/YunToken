const YunToken = artifacts.require("YunToken");
const BtcToken = artifacts.require("BtcToken");
const YunBtcCake = artifacts.require("YunBtcCake");


contract('YunBtcCake', async (accounts) => {

    const admin = accounts[0];
    const totalSupplyYun = 1000000;
    const totalSupplyBtc = 10000;

    it('initialized the contract with the correct values', async () => {
        const tokenInstance = await YunBtcCake.deployed();

        //Check contract name
        const name = await tokenInstance.name();
        assert.equal(name, 'Cake token for Bitcoin and Yunis', 'has the correct name');

        //Check contract symbol
        const symbol = await tokenInstance.symbol();
        assert.equal(symbol, 'YB-LP', 'has the correct symbol');
    });


    it('add liquidity', async () => {
        const CakeTokenInstance = await YunBtcCake.deployed();
        const YunTokenInstance = await YunBtcCake.deployed();
        const BtcTokenInstance = await BtcToken.deployed();

        await YunTokenInstance.approve(CakeTokenInstance.address, totalSupplyYun, {from: admin})
        await BtcTokenInstance.approve(CakeTokenInstance.address, totalSupplyBtc, {from: admin})

        let allowanceYun = await YunTokenInstance.allowance(admin, CakeTokenInstance.address);
        let allowanceBtc = await BtcTokenInstance.allowance(admin, CakeTokenInstance.address);

        assert.equal(allowanceYun.toNumber(), totalSupplyYun);
        assert.equal(allowanceBtc.toNumber(), totalSupplyBtc);

        let liquidity = await YunTokenInstance.addLiquidity(1000, 100000,{from: admin});
        console.log(liquidity);
    });
})
