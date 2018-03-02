var DullToken = artifacts.require("DullToken");
var DullChannel = artifacts.require("DullChannel");

var token;
var channel;
var channelId;
var stateChannel;

var houseAccount = web3.eth.accounts[9];
var playerAccount = web3.eth.accounts[1];


contract('DullToken and DullChannel', function () {

  it("Should have a total supply of 100000000000000000000000000", function() {
    return DullToken.deployed()
      .then(inst => {
        token = inst;
        return inst.totalSupply.call();
      })
      .then(tot => {
        assert.equal(tot, 100000000000000000000000000, "Total supply was incorrect")
      })
  });
  it("Should have assigned the entire balance to account 0x5AEDA56215b167893e80B4fE645BA6d5Bab767DE", function() {
    return DullToken.deployed()
      .then(inst => {
        return inst.balanceOf.call(houseAccount);
      })
      .then(tot => {
        assert.equal(tot, 100000000000000000000000000, "Asignment not made");
      })
  });

  it("Should be able to transfer tokens to accounts[1]", function() {
    var token;
    return DullToken.deployed()
      .then(inst => {
        token = inst;
        return token.transfer(playerAccount, 20000000000000000000000000, {from: houseAccount})
      })
      .then(() => {
        return token.balanceOf.call(playerAccount);
      })
      .then(tot => {
        assert.equal(tot, 20000000000000000000000000, "Asignment not made");        
      })
      .then(() => {
        return token.balanceOf.call(houseAccount);
      })
      .then(tot => {
        assert.equal(tot, 80000000000000000000000000, "Asignment not made");        
      })
  });

  it("Should be able to feed tokens into a DullChannel contract", function() {
    return DullChannel.deployed()
      .then(inst => {
        channel = inst;
        console.log("DullToken address: " + token.address);
        console.log("DullChannel address: " + channel.address);
        
        return token.approve(channel.address, 1000, {from: houseAccount});
      })
      .then(() => {
        return token.balanceOf.call(channel.address);
      })
      .then(bal => {
        console.log("Channel balance: " + bal);
      })
      .then(() => {
        return token.allowance.call(houseAccount, channel.address);
      })
      .then(allowance => {
        console.log("House allowance: " + allowance);
        assert.equal(allowance, 1000, "Channel not set correctly");
      })
      .then(() => {
        // openChannel(address token, address player, uint amount)
        // The house is accounts[9], the player is accounts[1]
        return channel.openChannel(token.address, playerAccount, 100, {from: houseAccount});
      })
      .then(result => {
        for (var i = 0; i < result.logs.length; i++) {
          var log = result.logs[i];
          console.log(log.event);
        }
      })
      .then(() => {
        return channel.getChannelId.call(houseAccount, playerAccount);
      })
      .then(id => {
        channelId = id;
        console.log("Channel ID: " + channelId);
        return channel.getDepositHouse.call(channelId);
      })
      .then(deposit => {
        assert.equal(deposit, 100, "House deposit not 100");
      })
      .then(() => {        
        return token.approve(channel.address, 100, {from: playerAccount});
      })
      .then(() => {
        return token.balanceOf.call(channel.address);
      })
      .then(bal => {
        console.log("Channel balance: " + bal);
      })
      .then(() => {
        return token.allowance.call(playerAccount, channel.address);
      })
      .then(allowance => {
        assert.equal(allowance, 100, "Player has not allowed transfer of 100 tokens");
      })
      .then(() => {
        return channel.addDeposit(channelId, 100, {from: playerAccount});
      })
      .then(() => {
        return token.balanceOf.call(channel.address);
      })
      .then(bal => {
        console.log("Channel balance: " + bal);
        return channel.getDepositPlayer.call(channelId);
      })
      .then(deposit => {
        console.log("Player balance: " + deposit);
        assert.equal(deposit, 100, "Player deposit not 100");
      })
      .then(() => {
       return channel.getPlayerAddress.call(channelId);
      })
      .then(add => {
        console.log("Player address: " + add);
        assert.equal(add, playerAccount, "Player account wrong");
      })
  })

});

