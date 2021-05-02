const YunToken = artifacts.require("YunToken");
const BtcToken = artifacts.require("BtcToken");
const YunBtcCake = artifacts.require("YunBtcCake");


contract('YunBtcCake', async (accounts) => {

    it('initialized the contract with the correct values', async () => {
        const tokenInstance = await YunBtcCake.deployed();

        //Check contract name
        const name = await tokenInstance.name();
        assert.equal(name, 'Cake token for Bitcoin and Yunis', 'has the correct name');

        //Check contract symbol
        const symbol = await tokenInstance.symbol();
        assert.equal(symbol, 'YB-LP', 'has the correct symbol');
    });

})