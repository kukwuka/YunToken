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
        assert.equal(receipt.logs[receipt.logs.length - 1].event, 'AddLiquidity', 'should be the "AddLiquidity" event');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.sender, admin, 'who added liquidity');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.amountBTC, totalSupplyBtc / 10, 'liquidity in Btc tokens');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.amountYUN, totalSupplyYun / 10, 'liquidity in Yun tokens');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.liquidity, minimumLiquidity, 'liquidity in Cake tokens');


        let cakeBalance = await CakeTokenInstance.balanceOf(admin, {from: admin});
        assert.equal(cakeBalance.toNumber(), minimumLiquidity);


        receipt = await CakeTokenInstance.addLiquidity(3.5 * totalSupplyBtc / 10, 3.5 * totalSupplyYun / 10, {from: admin});
        assert(receipt.logs.length > 1, 'triggers one event');
        assert.equal(receipt.logs[receipt.logs.length - 1].event, 'AddLiquidity', 'should be the "AddLiquidity" event');
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


    it("buy tokens", async () => {
        const CakeTokenInstance = await YunBtcCake.deployed();
        const YunTokenInstance = await YunToken.deployed();
        const BtcTokenInstance = await BtcToken.deployed();

        const firstBalanceYun = await YunTokenInstance.balanceOf(admin);
        const firstBalanceBtc = await BtcTokenInstance.balanceOf(admin);


        let receipt = await CakeTokenInstance.buyBtcToken(yunTokensCount, {from: admin});

        assert(receipt.logs.length > 1, 'triggers one event');
        assert.equal(receipt.logs[receipt.logs.length - 1].event, 'BuyBtcToken', 'should be the "BuyBtcToken" event');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.buyer, admin, 'who buyed');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.amountInYUN, yunTokensCount, 'liquidity in Btc tokens');


        let amountBtc = receipt.logs[receipt.logs.length - 1].args.amountOutBTC;

        const secondBalanceYun = await YunTokenInstance.balanceOf(admin);
        const secondBalanceBtc = await BtcTokenInstance.balanceOf(admin);

        assert.equal(firstBalanceBtc.toNumber() + amountBtc.toNumber(), secondBalanceBtc.toNumber(), 'balance after buying Btc')
        assert.equal(firstBalanceYun.toNumber() - yunTokensCount, secondBalanceYun.toNumber(), 'balance after buying Btc')


        receipt = await CakeTokenInstance.buyYunToken(btcTokensCount, {from: admin});

        assert(receipt.logs.length > 1, 'triggers one event');
        assert.equal(receipt.logs[receipt.logs.length - 1].event, 'BuyYunToken', 'should be the "BuyBtcToken" event');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.buyer, admin, 'who buyed');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.amountInBTC, btcTokensCount, 'liquidity in Btc tokens');

        let amountYun = receipt.logs[receipt.logs.length - 1].args.amountOutYUN;

        const thirdBalanceYun = await YunTokenInstance.balanceOf(admin);
        const thirdBalanceBtc = await BtcTokenInstance.balanceOf(admin);

        assert.equal(secondBalanceYun.toNumber() + amountYun.toNumber(), thirdBalanceYun.toNumber(), 'balance after buying Btc')
        assert.equal(secondBalanceBtc.toNumber() - btcTokensCount, thirdBalanceBtc.toNumber(), 'balance after buying Btc')
    });


    it('remove liquidity', async () => {
        const CakeTokenInstance = await YunBtcCake.deployed();
        const YunTokenInstance = await YunToken.deployed();
        const BtcTokenInstance = await BtcToken.deployed();

        const firstBalanceCake = await CakeTokenInstance.balanceOf(admin);
        const firstBalanceYun = await YunTokenInstance.balanceOf(admin);
        const firstBalanceBtc = await BtcTokenInstance.balanceOf(admin);

        assert.notEqual(firstBalanceCake.toNumber(), 0, 'have Cake-lp tokens')

        let receipt = await CakeTokenInstance.removeLiquidity();

        // assert(receipt.logs.length > 1, 'triggers one event');
        assert.equal(receipt.logs[receipt.logs.length - 1].event, 'RemoveLiquidity', 'should be the "RemoveLiquidity" event');
        assert.equal(receipt.logs[receipt.logs.length - 1].args.sender, admin, 'who buyed');

        const amountBtc = receipt.logs[receipt.logs.length - 1].args.amountBTC;
        const amountYun = receipt.logs[receipt.logs.length - 1].args.amountYUN;


        const secondBalanceCake = await CakeTokenInstance.balanceOf(admin);
        const secondBalanceYun = await YunTokenInstance.balanceOf(admin);
        const secondBalanceBtc = await BtcTokenInstance.balanceOf(admin);

        assert.equal(secondBalanceYun.toNumber(), firstBalanceYun.toNumber() + amountYun.toNumber(), 'balance Yun after removing liquidity');
        assert.equal(secondBalanceBtc.toNumber(), firstBalanceBtc.toNumber() + amountBtc.toNumber(), 'balance Btc after removing liquidity');
        assert.equal(secondBalanceCake.toNumber(), 0, 'all cake-lp burned')
    });

});
