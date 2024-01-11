var VehicleRentingSystem = artifacts.require("./VehicleRentingSystem.sol");

module.exports = function(deployer) {
  deployer.deploy(VehicleRentingSystem);
};