const YunToken = artifacts.require("YunToken");
const BtcToken = artifacts.require("BtcToken");
const YunBtcCake = artifacts.require("YunBtcCake");


contract('YunBtcCake', async (accounts) => {
    const admin = accounts[0];
    const totalSupplyYun = 1000000;
    const totalSupplyBtc = 10000;
    const minimumLiquidity = 1000;
    const yunTokensCount = totalSupplyYun / 100;
    const btcTokensCount = totalSupplyBtc / 100;


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
        const YunTokenInstance = await YunToken.deployed();
        const BtcTokenInstance = await BtcToken.deployed();

        await YunTokenInstance.approve(CakeTokenInstance.address, totalSupplyYun, {from: admin})
        await BtcTokenInstance.approve(CakeTokenInstance.address, totalSupplyBtc, {from: admin})

        let allowanceYun = await YunTokenInstance.allowance(admin, CakeTokenInstance.address);
        let allowanceBtc = await BtcTokenInstance.allowance(admin, CakeTokenInstance.address);

        assert.equal(allowanceYun.toNumber(), totalSupplyYun);
        assert.equal(allowanceBtc.toNumber(), totalSupplyBtc);


        let balanceYun = await YunTokenInstance.balanceOf(admin);
        let balanceBtc = await BtcTokenInstance.balanceOf(admin);

        assert.equal(balanceYun.toNumber(), totalSupplyYun);
        assert.equal(balanceBtc.toNumber(), totalSupplyBtc);


        let receipt = await CakeTokenInstance.addLiquidity(totalSupplyBtc / 10, totalSupplyYun / 10, {from: admin});
        assert(receipt.logs.length > 1, 'triggers one event');
        assert.equal(receipt.logs[receipt.logs.length - 1].event, 'AddLiquidity', 'should be the "Sell" event');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.sender, admin, 'who added liquidity');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.amountBTC, totalSupplyBtc / 10, 'liquidity in Btc tokens');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.amountYUN, totalSupplyYun / 10, 'liquidity in Yun tokens');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.liquidity, minimumLiquidity, 'liquidity in Cake tokens');


        let cakeBalance = await CakeTokenInstance.balanceOf(admin, {from: admin});
        assert.equal(cakeBalance.toNumber(), minimumLiquidity);


        receipt = await CakeTokenInstance.addLiquidity(3.5 * totalSupplyBtc / 10, 3.5 * totalSupplyYun / 10, {from: admin});
        assert(receipt.logs.length > 1, 'triggers one event');
        assert.equal(receipt.logs[receipt.logs.length - 1].event, 'AddLiquidity', 'should be the "Sell" event');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.sender, admin, 'who added liquidity');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.amountBTC, 3.5 * totalSupplyBtc / 10, 'liquidity in Btc tokens');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.amountYUN, 3.5 * totalSupplyYun / 10, 'liquidity in Yun tokens');

        cakeBalance = await CakeTokenInstance.balanceOf(admin, {from: admin});
        assert.equal(cakeBalance.toNumber(), (3.5 + 1) * minimumLiquidity);


        let reverses = await CakeTokenInstance.getReserves()
        let reverseYun = reverses._reserveYUN.toNumber();
        let reverseBtc = reverses._reserveBTC.toNumber();

        assert.equal(reverseBtc, (3.5 + 1) * totalSupplyBtc / 10);
        assert.equal(reverseYun, (3.5 + 1) * totalSupplyYun / 10);

    });


    it("check price", async () => {
        const CakeTokenInstance = await YunBtcCake.deployed();

        let reverses = await CakeTokenInstance.getReserves()
        let reverseYun = reverses._reserveYUN.toNumber();
        let reverseBtc = reverses._reserveBTC.toNumber();

        let amountOutBTC = reverseYun - Math.floor(reverseYun * (reverseBtc) / (reverseBtc + btcTokensCount))
        let YunPrice = await CakeTokenInstance.getYunTokenPrice(btcTokensCount);

        assert.equal(YunPrice.toNumber(), amountOutBTC, 'How many Yun tokens we will get is counted right')


        let amountOutYUN = reverseBtc - Math.floor(reverseBtc * (reverseYun) / (reverseYun + yunTokensCount))
        let BtcPrice = await CakeTokenInstance.getBtcTokenPrice(yunTokensCount);

        assert.equal(BtcPrice.toNumber(), amountOutYUN, 'How many Yun tokens we will get is counted right')
    });
    
    
    
    it("buy tokens",async ()=>{

    })
});
