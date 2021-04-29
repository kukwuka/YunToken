const YunToken = artifacts.require("YunToken");

contract('YunToken', (accounts) => {
    let tokenInstance;
    let tokenPrice = 1000000000000000;
    let admin = accounts[0];
    let fromAccount = accounts[2];
    let toAccount = accounts[3];
    let spendingAccount = accounts[4];
    let buyer = accounts[5];
    let numberOfTokens = 10;


    it('initialized the contract with the correct values', () => {
        return YunToken.deployed().then((instance) => {
            tokenInstance = instance;

            //Check contract name
            return tokenInstance.name();
        }).then((name) => {
            assert.equal(name, 'Yunis Token', 'has the correct name');

            //Check contract symbol
            return tokenInstance.symbol();
        }).then((symbol) => {
            assert.equal(symbol, 'YUN', 'has the correct symbol');
        });
    })


    it('sets the total Supply upon deployment', () => {
        return YunToken.deployed().then((instance) => {
            tokenInstance = instance;

            //Check  token total supply
            return tokenInstance.totalSupply();
        }).then((totalSupply) => {
            assert.equal(totalSupply.toNumber(), 1000000, 'sets the total supply to 0');

            //Check  balance admin
            return tokenInstance.balanceOf(admin);
        }).then((adminBalance) => {
            assert.equal(adminBalance.toNumber(), 1000000, 'it allocates initial supply to the admin account ');

        });
    });
    //
    it('transfers token ownership', () => {
        return YunToken.deployed().then((instance) => {
            tokenInstance = instance

            //transfer some value from admin
            return tokenInstance.transfer.call(accounts[1], 25000, {from: accounts[0]})
        }).then((success) => {
            assert.equal(success, true, 'it returns true')

            //transfer some value for  event
            return tokenInstance.transfer(accounts[1], 25000, {from: accounts[0]});

        }).then((receipt) => {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'Transfer', 'should be the "Transfer" event');
            // console.log(receipt.logs[0].args.sender);
            assert.equal(receipt.logs[0].args.from, accounts[0], 'logs the account the tokens are transferred from');
            assert.equal(receipt.logs[0].args.to, accounts[1], 'logs the account the tokens are transferred to');
            assert.equal(receipt.logs[0].args.value, 25000, 'logs the transfer amount');

            //check balance
            return tokenInstance.balanceOf(accounts[1]);
        }).then((balance) => {
            assert.equal(balance.toNumber(), 25000, 'adss the amount to the receiving account');

            //check balance
            return tokenInstance.balanceOf(accounts[0]);
        }).then((balance) => {
            assert.equal(balance.toNumber(), 975000, 'deducts the amount from the sending');
        })
    });


    it('approves tokens for delegated transfer', () => {
        return YunToken.deployed().then((instance) => {
            tokenInstance = instance;

            //approve some value
            return tokenInstance.approve.call(accounts[1], 100);
        }).then((success) => {
            assert.equal(success, true, 'it returns true');

            //approve some value for event
            return tokenInstance.approve(accounts[1], 100);
        }).then((receipt) => {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'Approval', 'should be the "Approval" event');
            assert.equal(receipt.logs[0].args.owner, accounts[0], 'logs the account the tokens are transferred from');
            assert.equal(receipt.logs[0].args.spender, accounts[1], 'logs the account the tokens are transferred to');
            assert.equal(receipt.logs[0].args.value, 100, 'logs the transfer amount');

            //check allowance
            return tokenInstance.allowance(accounts[0], accounts[1]);
        }).then((allowance) => {
            assert.equal(allowance, 100, 'stores the for delegated transfer');
        });
    });


    it('handles delegated token transfers', () => {
        return YunToken.deployed().then((instance) => {
            tokenInstance = instance;

            //Transfer some tokens to fromAccount
            return tokenInstance.transfer(fromAccount, 100, {from: accounts[0]});
        }).then(() => {

            //Approve spendingAccount to spend 10 tokens from fromAccount
            return tokenInstance.approve(spendingAccount, 15, {from: fromAccount});
        }).then(() => {

            //Try transferring something  larger the sender balance
            return tokenInstance.transferFrom(fromAccount, toAccount, 9999, {from: spendingAccount});
        }).then(assert.fail).catch((error) => {
            assert(error.message.indexOf('revert') >= 0, 'cannot transfer valuer larger  than  balance');

            return tokenInstance.transferFrom(fromAccount, toAccount, 20, {from: spendingAccount});
        }).then(assert.fail).catch((error) => {
            assert(error.message.indexOf('revert') >= 0, 'cannot transfer valuer larger  than  approved amount');

            return tokenInstance.transferFrom.call(fromAccount, toAccount, 10, {from: spendingAccount});
        }).then((success) => {
            assert.equal(success, true);

            //transferFrom for event
            return tokenInstance.transferFrom(fromAccount, toAccount, 10, {from: spendingAccount});
        }).then((receipt) => {
            // console.log(receipt.logs.length);
            assert.equal(receipt.logs.length, 2, 'triggers two event');
            assert.equal(receipt.logs[0].event, 'Transfer', 'should be the "Transfer" event');
            assert.equal(receipt.logs[0].args.from, fromAccount, 'logs the account the tokens are transferred from');
            assert.equal(receipt.logs[0].args.to, toAccount, 'logs the account the tokens are transferred to');
            assert.equal(receipt.logs[0].args.value, 10, 'logs the transfer amount');

            assert.equal(receipt.logs[1].event, 'Approval', 'should be the "Transfer" event');
            assert.equal(receipt.logs[1].args.owner, fromAccount, 'logs the account the tokens are transferred from');
            assert.equal(receipt.logs[1].args.spender, spendingAccount, 'logs the account the tokens are transferred to');
            // console.log(receipt.logs[1].args.value);
            assert.equal(receipt.logs[1].args.value.toNumber(), 5, 'logs the transfer amount');


            //check balance
            return tokenInstance.balanceOf(fromAccount);
        }).then((balance) => {
            assert.equal(balance.toNumber(), 90, 'deducts the amount from the selling account ');

            //check balance
            return tokenInstance.balanceOf(toAccount);
        }).then((balance) => {
            assert.equal(balance.toNumber(), 10, 'deducts the amount from the receiving account ');

            //check allowance
            return tokenInstance.allowance(fromAccount, spendingAccount);
        }).then((allowance) => {
            assert.equal(allowance.toNumber(), 5, 'deducts the amount from the allowance')
        });
    });

    it('token buying', () => {
        return YunToken.deployed().then((instance) => {
            tokenInstance = instance;

            //Start Sale
            return tokenInstance.startSale({from: admin})
        }).then((receipt) => {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'StartSelling', 'should be the "Transfer" event');

            //Check is token on sale
            return tokenInstance.onSale();
        }).then((value) => {
            assert(value, 'clients can buy tokens');

            //Buy some tokens
            return tokenInstance.buyTokens(numberOfTokens, {from: buyer, value: numberOfTokens * tokenPrice})
        }).then((receipt) => {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'Sell', 'should be the "Transfer" event');
            assert.equal(receipt.logs[0].args._buyer, buyer, 'logs the account the tokens are bought by');
            assert.equal(receipt.logs[0].args._amount, numberOfTokens, 'logs the amount bought by the buyer');

            //Check buyer balance
            return tokenInstance.balanceOf(buyer);
        }).then((balance) => {
            assert.equal(balance.toNumber(), numberOfTokens, 'deducts the amount from the selling account ');

            //Buy token with low price
            return tokenInstance.buyTokens(numberOfTokens, {from: buyer, value: 1});
        }).then(assert.fail).catch(function (error) {
            assert(error.message.indexOf('revert') >= 0, 'msg.value must equal number of tokens in wei');

            //Buy token more than available
            return tokenInstance.buyTokens(800000, {from: buyer, value: numberOfTokens * tokenPrice})
        }).then(assert.fail).catch(function (error) {
            assert(error.message.indexOf('revert') >= 0, 'cannot purchase more tokens than available');

            //Stop selling
            return tokenInstance.stopSale({from: admin})
        }).then((receipt) => {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'StopSelling', 'should be the "Transfer" event');

            //Check is token on sale
            return tokenInstance.onSale();
        }).then((value) => {
            assert(!value, 'clients can buy tokens');
        });
    });

    it('casino roulette', () => {

        let casinoValue = 23;
        let color = 2;
        let playerBalance;
        return YunToken.deployed().then((instance) => {
            tokenInstance = instance;

            //Get  player balance before playing
            return tokenInstance.balanceOf(admin);
        }).then((balance) => {
            playerBalance = balance.toNumber();
            //Start Sale
            return tokenInstance.roulette(casinoValue, color, {from: admin})
        }).then((receipt) => {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'Roulette', 'should be the "Transfer" event');
            assert.equal(receipt.logs[0].args._player, admin, 'logs the account the tokens are bought by');
            // console.log(receipt.logs[0].args._reward.toNumber());

            //get balance after playing
            return tokenInstance.balanceOf(admin);
        }).then((balance) => {
            assert.notEqual(playerBalance, balance.toNumber(), 'balance after and before playing are the same')
        });
    });


    it('casino Slot-Machine', () => {
        let playerBalance;
        return YunToken.deployed().then((instance) => {
            tokenInstance = instance;

            //Get  player balance before playing
            return tokenInstance.balanceOf(admin);
        }).then((balance) => {
            playerBalance = balance.toNumber();
            //Start Sale
            return tokenInstance.slotMachine({from: admin});
        }).then((receipt) => {
            assert.equal(receipt.logs.length, 1, 'triggers one event');
            assert.equal(receipt.logs[0].event, 'SlotMachine', 'should be the "Transfer" event');
            assert.equal(receipt.logs[0].args._player, admin, 'logs the account the tokens are bought by');
            // console.log(receipt.logs[0].args._reward.toNumber());
            // console.log(receipt.logs[0].args._wheelsValues);

            //get balance after playing
            return tokenInstance.balanceOf(admin);
        }).then((balance) => {
            assert.notEqual(playerBalance, balance.toNumber(), 'balance after and before playing are the same')
        });
    })


});