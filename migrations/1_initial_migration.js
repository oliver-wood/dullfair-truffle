var Migrations = artifacts.require("./Migrations.sol");
var DullToken =  artifacts.require("./DullToken.sol");
var DullChannel =  artifacts.require("./DullChannel.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(DullToken);
  deployer.deploy(DullChannel);
};
