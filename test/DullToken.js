var DullToken = artifacts.require("DullToken");

contract('DullToken', function () {

  it("Should have a total supply of 100000000000000000000000000", function() {
    return DullToken.deployed()
      .then(inst => {
        return inst.totalSupply.call();
      })
      .then(tot => {
        assert.equal(tot, 100000000000000000000000000, "Total supply was incorrect")
      })
  });
  it("Should have assigned the entire balance to account 0x5AEDA56215b167893e80B4fE645BA6d5Bab767DE", function() {
    return DullToken.deployed()
      .then(inst => {
        return inst.balanceOf.call(web3.eth.accounts[9]);
      })
      .then(tot => {
        assert.equal(tot, 100000000000000000000000000, "Asignment not made");
      })
  });

  it("Should be able to transfer tokens to accounts[1]", function() {
    console.log(web3.eth.accounts[9]);
    var token;
    return DullToken.deployed()
      .then(inst => {
        token = inst;
        return token.transfer(web3.eth.accounts[1], 20000000000000000000000000, {from: web3.eth.accounts[9]})
      })
      .then(() => {
        return token.balanceOf.call(web3.eth.accounts[1]);
      })
      .then(tot => {
        assert.equal(tot, 20000000000000000000000000, "Asignment not made");        
      })
      .then(() => {
        return token.balanceOf.call(web3.eth.accounts[9]);
      })
      .then(tot => {
        assert.equal(tot, 80000000000000000000000000, "Asignment not made");        
      })

  });

});