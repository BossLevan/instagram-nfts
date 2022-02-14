const ShowTimeContract = artifacts.require("ShowtimeMT");

module.exports = function (deployer) {
  deployer.deploy(ShowTimeContract);
};