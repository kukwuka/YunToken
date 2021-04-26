App = {
    web3Provider: null,
    contracts: {},
    account: '0x0',
    loading: false,
    tokenPrice: 1000000000000000,
    tokensSold: 0,
    tokensAvailable: 750000,

    init: function () {
        console.log("App initialized...")
        return App.initWeb3();
    },

    initWeb3: function () {
        if (typeof web3 !== 'undefined') {
            // If a web3 instance is already provided by Meta Mask.
            App.web3Provider = window.web3.currentProvider;
            web3 = new Web3(window.web3.currentProvider);

        } else {
            // Specify default instance if no web3 instance provided
            App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
            web3 = new Web3(App.web3Provider);
        }
        return App.initContracts();
    },

    initContracts: function () {
        $.getJSON("YunToken.json", function (yunToken) {
            App.contracts.Yuntoken = TruffleContract(yunToken);
            App.contracts.Yuntoken.setProvider(App.web3Provider);
            App.contracts.Yuntoken.deployed().then(function (yunToken) {
                console.log("Dapp Token Address:", yunToken.address);
            });

            App.listenForEvents();
            return App.render();
        });
    },

    // Listen for events emitted from the contract
    listenForEvents: function () {
        App.contracts.Yuntoken.deployed().then(function (instance) {
            instance.Sell({}, {
                fromBlock: 0,
                toBlock: 'latest',
            }).watch(function (error, event) {
                if (event.args._buyer === App.account) {
                    console.log("event triggered", event);
                }
                App.render();
            });
            instance.SlotMachine({}, {
                fromBlock: 'latest',
                toBlock: 'latest',
            }).watch(function (error, event) {
                if (event.args._player === App.account) {
                    alert("You won on the Slot-Machine " + event.args._reward.toNumber()+" YUN");
                    console.log("event triggered", event);
                }
                App.render();
            });
            instance.Roulette({}, {
                fromBlock: 'latest',
                toBlock: 'latest',
            }).watch(function (error, event) {
                if (event.args._player === App.account) {
                    alert("You won on the Russian Roulette " + event.args._reward.toNumber()+" YUN");
                    console.log("event triggered", event);
                }
                App.render();
            })
        })
    },

    render: function () {
        console.log(window.ethereum.enable());

        if (App.loading) {
            return;
        }
        App.loading = true;

        var loader = $('#loader');
        var content = $('#content');

        loader.show();
        content.hide();

        // Load account data
        if (!web3.isConnected()) {
            console.error("Not connected");
        }
        console.log(web3.accounts);
        web3.eth.getCoinbase(function (err, account) {
            if (err === null) {
                console.log('account', account)
                App.account = account;
                $('#accountAddress').html("Your Account: " + account);
            }
        })

        // Load token sale contract
        App.contracts.Yuntoken.deployed().then(function (instance) {
            dappTokenSaleInstance = instance;
            return dappTokenSaleInstance.tokenPrice();
        }).then(function (tokenPrice) {
            App.tokenPrice = tokenPrice;
            $('.token-price').html(web3.fromWei(App.tokenPrice, "ether").toNumber());
            return dappTokenSaleInstance.tokensSold();
        }).then(function (tokensSold) {
            App.tokensSold = tokensSold.toNumber();
            $('.tokens-sold').html(App.tokensSold);
            $('.tokens-available').html(App.tokensAvailable);

            var progressPercent = (Math.ceil(App.tokensSold) / App.tokensAvailable) * 100;
            $('#progress').css('width', progressPercent + '%');

            // Load token contract
            App.contracts.Yuntoken.deployed().then(function (instance) {
                dappTokenInstance = instance;
                return dappTokenInstance.balanceOf(App.account);
            }).then(function (balance) {
                $('.dapp-balance').html(balance.toNumber());
                App.loading = false;
                loader.hide();
                content.show();
            })
        });
    },

    buyTokens: function () {
        $('#content').hide();
        $('#loader').show();
        var numberOfTokens = $('#numberOfTokens').val();
        App.contracts.Yuntoken.deployed().then(function (instance) {
            return instance.buyTokens(numberOfTokens, {
                from: App.account,
                value: numberOfTokens * App.tokenPrice,
                gas: 500000 // Gas limit
            });
        }).then(function (result) {
            console.log("Tokens bought...")
            $('form').trigger('reset') // reset number of tokens in form
            // Wait for Sell event
        });
    }
}


$(function () {
    $(window).load(function () {
        App.init();
    })
});
