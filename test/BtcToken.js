const BtcToken = artifacts.require("BtcToken");


contract('BtcToken', async (accounts) => {
    const admin = accounts[0];
    const tokenAmplitude = 100;
    const buyer = accounts[5];


    it('initialized the contract with the correct values', async () => {
        const tokenInstance = await BtcToken.deployed();

        //Check contract name
        const name = await tokenInstance.name();
        assert.equal(name, 'Bitcoin Token', 'has the correct name');

        //Check contract symbol
        const symbol = await tokenInstance.symbol();
        assert.equal(symbol, 'BTC', 'has the correct symbol');
    });


    it('sets the total Supply upon deployment', async () => {
        const tokenInstance = await BtcToken.deployed();

        const totalSupply = await tokenInstance.totalSupply();
        assert.equal(totalSupply.toNumber(), 10000, 'sets the total supply to 0');

        const adminBalance = await tokenInstance.balanceOf(admin);
        assert.equal(adminBalance.toNumber(), 10000, 'it allocates initial supply to the admin account ');

    });

    it('token buying', async () => {

        const tokenInstance = await BtcToken.deployed();

        //Get first price
        let currentPrice = await tokenInstance.currentPrice();

        assert.equal(currentPrice, tokenAmplitude, 'tokens did not buy, price is 3 ')

        //Get how many tokens are sold
        let tokensSold = await tokenInstance.tokensSold();

        assert.equal(tokensSold.toNumber(), 0, 'tokens did not sale')

        //buy some tokens
        let numberOfTokens1 = 10000
        let receipt = await tokenInstance.buyTokens(numberOfTokens1, {
            from: buyer,
            value: numberOfTokens1 * currentPrice
        });

        assert.equal(receipt.logs.length, 1, 'triggers one event');
        assert.equal(receipt.logs[0].event, 'Sell', 'should be the "Sell" event');
        assert.equal(receipt.logs[0].args._buyer, buyer, 'logs the account the tokens are bought by');
        assert.equal(receipt.logs[0].args._amount, numberOfTokens1, 'logs the account the count of tokens are bought');

        //check balance after buying
        let buyerBalance = await tokenInstance.balanceOf(buyer);
        assert.equal(buyerBalance, numberOfTokens1, 'after buying count of tokens is equal to counts of token on the balance')

        //get price after buying, it increase by rule: A^(x/(k+1))
        currentPrice = await tokenInstance.currentPrice();
        assert.equal(currentPrice.toNumber(), tokenAmplitude ** 2, 'changed token price')

        //get second buy
        let numberOfTokens2 = 10000;
        receipt = await tokenInstance.buyTokens(numberOfTokens2, {
            from: buyer,
            value: numberOfTokens2 * currentPrice
        });

        assert.equal(receipt.logs.length, 1, 'triggers one event');
        assert.equal(receipt.logs[0].event, 'Sell', 'should be the "Sell" event');
        assert.equal(receipt.logs[0].args._buyer, buyer, 'logs the account the tokens are bought by');
        assert.equal(receipt.logs[0].args._amount, numberOfTokens2, 'logs the account the count of tokens are bought');

        //get balance after second transaction
        buyerBalance = await tokenInstance.balanceOf(buyer);

        assert.equal(buyerBalance, numberOfTokens2 + numberOfTokens1, 'after buying count of tokens is equal to counts of token on the balance')

        //check the price
        currentPrice = await tokenInstance.currentPrice();

        assert.notEqual(BigInt(currentPrice), tokenAmplitude);


    })


});