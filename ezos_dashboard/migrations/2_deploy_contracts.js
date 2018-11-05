var Ezos = artifacts.require('./ezos.sol');

module.exports = function (deployer) {
  deployer.deploy(Ezos);
}
