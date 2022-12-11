const {ethers} = require("@nomiclabs/buidler");

const PersonaFactory = artifacts.require("PersonaFactory");
const ValidatorFactory = artifacts.require("ValidatorFactory");
const Registry = artifacts.require("Registry");

const name = ethers.utils.formatBytes32String("Test Registry");

module.exports = async (deployer) => {
	await deployer.deploy(PersonaFactory);
	await deployer.deploy(ValidatorFactory);
	await deployer.deploy(Registry, name, false, false, PersonaFactory.address, ValidatorFactory.address);
};
