var Migrations = artifacts.require("./Migrations.sol");
var DullToken =  artifacts.require("./DullToken.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(DullToken);
};
