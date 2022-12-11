const Build_Persona = require("../build/contracts/Persona.json");
const Build_PersonaFactory = require("../build/contracts/PersonaFactory.json");
const Build_Registry = require("../build/contracts/Registry.json");
const Build_ValidatorFactory = require("../build/contracts/ValidatorFactory.json");
const Build_Validator = require("../build/contracts/Validator.json");

const {solidity, deployContract} = require("ethereum-waffle");
const {use, expect} = require("chai");
const {ethers} = require("@nomiclabs/buidler");
const documentLinks = ["test1"];
const documentHashes = [ethers.utils.keccak256(ethers.utils.toUtf8Bytes(documentLinks[0]))];
const documentTypeString = "Passport";
const documentType = ethers.utils.formatBytes32String(documentTypeString);
const documentValue = "testEncrypted";
const documentValueHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("test"));
const registryName = ethers.utils.formatBytes32String("TestRegistry");
const personaName = ethers.utils.formatBytes32String("TestPersona");
const validatorName = ethers.utils.formatBytes32String("TestValidator");
const validatorPubKey = ethers.utils.formatBytes32String("pubkey");

use(solidity);

let PersonaFactory,
	Registry,
	Persona,
	Validator,
	ValidatorFactory,
	ownerRegistry,
	personaOwnerAddress,
	notPersonaAddress,
	certificateIssuer;

describe("Deployment", function () {
	it("Celo deploy contracts", async function () {
		[ownerRegistry, personaOwnerAddress, notPersonaAddress, validatorOwnerAddress, certificateIssuer] = await ethers.getSigners();
		PersonaFactory = await deployContract(ownerRegistry, Build_PersonaFactory, []);
		await PersonaFactory.deployed();
		ValidatorFactory = await deployContract(ownerRegistry, Build_ValidatorFactory, []);
		await ValidatorFactory.deployed();
		Registry = await deployContract(ownerRegistry, Build_Registry, [
			registryName,
			false,
			true,
			PersonaFactory.address,
			ValidatorFactory.address,
		]);
		await Registry.deployed();
	});

	it("Celo save DEFAULT ADMIN ROLE at deploy", async function () {
		const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
		expect(await Registry.hasRole(DEFAULT_ADMIN_ROLE, ownerRegistry._address)).to.equal(true);
	});

	it("Celo register name correctly", async function () {
		expect(await Registry.name()).to.equal(registryName);
	});
});

describe("Persona contract", function () {
	it("Celo create a Persona", async function () {
		const tx = await Registry.connect(personaOwnerAddress).personaSelfRegistry(personaName);
		await tx.wait();
		let _personaAddress = await Registry.ownerToPersona(personaOwnerAddress._address);
		Persona = new ethers.Contract(_personaAddress, Build_Persona.abi, ethers.provider);
		await Persona.deployed();
	});

	it("Celo have persona role", async function () {
		const PERSONA_ROLE = ethers.utils.solidityKeccak256(["string"], ["PERSONA_ROLE"]);
		expect(await Registry.hasRole(PERSONA_ROLE, Persona.address)).to.equal(true);
	});

	it("Celo register name correctly", async function () {
		expect(await Persona.name()).to.equal(personaName);
	});

	it("Celo not allow to create Persona again", async function () {
		await expect(Registry.connect(personaOwnerAddress).personaSelfRegistry(personaName)).to.be.revertedWith(
			"Registry: persona already registered"
		);
	});

	it("Celo not add a blank value", async function () {
		await expect(
			Persona.connect(personaOwnerAddress).addField(documentType, documentValue, ethers.utils.formatBytes32String(""), documentHashes)
		).to.be.revertedWith("Persona: Document must not be empty");
	});

	it("Celo add a correct field", async function () {
		const field = await Persona.connect(personaOwnerAddress).addField(documentType, documentValue, documentValueHash, documentHashes);
		await field.wait();
	});

	it("Celo not add a repeated field", async function () {
		await expect(
			Persona.connect(personaOwnerAddress).addField(documentType, documentValue, documentValueHash, documentHashes)
		).to.be.revertedWith("Persona: Document already added!");
	});

	it("Celo not add a field because is not a owner", async function () {
		await expect(
			Persona.connect(notPersonaAddress).addField(documentType, documentValue, documentValueHash, documentHashes)
		).to.be.revertedWith("Ownable: caller is not the owner");
	});
});

describe("Validator contract", function () {
	it("Celo not create a Validator using default registry", async function () {
		await expect(Registry.connect(validatorOwnerAddress).validatorSelfRegistry(validatorName, validatorPubKey)).to.be.revertedWith(
			"Registry: Self registry disabled"
		);
	});

	it("Celo change configuration for validator self registry", async function () {
		const tx = await Registry.connect(ownerRegistry).changeRequireRoleValidator(false);
		await tx.wait();
		expect(await Registry.requireRoleValidator()).to.equal(false);
	});

	it("Celo create a Validator", async function () {
		const tx = await Registry.connect(validatorOwnerAddress).validatorSelfRegistry(validatorName, validatorPubKey);
		await tx.wait();
		let _validatorAddress = await Registry.ownerToValidator(validatorOwnerAddress._address);
		Validator = new ethers.Contract(_validatorAddress, Build_Validator.abi, ethers.provider);
		await Validator.deployed();
	});

	it("Celo register name correctly", async function () {
		expect(await Validator.name()).to.equal(validatorName);
	});

	it("Celo not allow to create Validator again", async function () {
		await expect(Registry.connect(validatorOwnerAddress).validatorSelfRegistry(validatorName, validatorPubKey)).to.be.revertedWith(
			"Registry: validator already registered"
		);
	});

	it("Celo add document correctly", async function () {
		const tx = await Validator.connect(validatorOwnerAddress).addDocumentType(documentType);
		await tx.wait();
		expect(await Validator.documentTypes(documentType)).to.equal(true);
	});
});

describe("Persona and validator", function () {
	it("Celo not send validation because document not added", async function () {
		await expect(
			Persona.connect(personaOwnerAddress).askToValidate(
				Validator.address,
				ethers.utils.formatBytes32String("documento errado"),
				["testLink"],
				"testHash"
			)
		).to.be.revertedWith("Persona: Document not added");
	});

	it("Celo not send validation because address is not validator", async function () {
		await expect(
			Persona.connect(personaOwnerAddress).askToValidate(notPersonaAddress._address, documentType, ["testLink"], "testHash")
		).to.be.revertedWith("Persona: Address is not registered as validator");
	});

	it("Celo not send validation because validator does not accept that document type", async function () {
		const field = await Persona.connect(personaOwnerAddress).addField(
			ethers.utils.formatBytes32String("outro documento"),
			documentValue,
			documentValueHash,
			documentHashes
		);
		await field.wait();
		await expect(
			Persona.connect(personaOwnerAddress).askToValidate(
				Validator.address,
				ethers.utils.formatBytes32String("outro documento"),
				["testLink"],
				"testHash"
			)
		).to.be.revertedWith("Validator: Validator does not validate this kind of document");
	});

	it("Celo send document to validation", async function () {
		const tx = await Persona.connect(personaOwnerAddress).askToValidate(Validator.address, documentType, ["testLink"], "testHash");
		await tx.wait();
		const status = await Persona.getValidationStatus(documentType, Validator.address);
		expect(status[0]).to.equal(1);
		const validators = await Persona.getValidators(documentType);
		expect(validators).to.include(Validator.address);
		expect(validators.length).to.equal(1);
		expect(await Validator.validationQueueStart()).to.equal(1);
		expect(await Validator.validationQueueEnd()).to.equal(1);
	});

	it("Celo process validation", async function () {
		const nextValidation = await Validator.getNextValidation();
		expect(nextValidation[0]).to.equal(Persona.address);
		expect(nextValidation[1]).to.equal(documentType);
		const tx = await Validator.connect(validatorOwnerAddress).processValidation(0, "test");
		await tx.wait();
		const status = await Persona.getValidationStatus(documentType, Validator.address);
		expect(status[0]).to.equal(0);
	});

	it("Celo not process validation from other addresses", async function () {
		await expect(Validator.connect(personaOwnerAddress).processValidation(1, "test")).to.be.revertedWith(
			"Ownable: caller is not the owner"
		);
	});
});
describe("Persona and Certificate Issuer", function () {
	it("Celo not process pending certifications when array is empty", async function () {
		await expect(Persona.connect(personaOwnerAddress).processLastPendingCertificate(false)).to.be.revertedWith(
			"Persona: No pending certificates"
		);
	});

	it("Celo register a new certificate", async function () {
		let status = await Persona.connect(personaOwnerAddress).getLastPendingCertificate();
		expect(status[0]).to.equal("0x0000000000000000000000000000000000000000");
		const tx = await Persona.connect(certificateIssuer).giveCertificate(
			ethers.utils.formatBytes32String("test"),
			"test",
			"test",
			"test"
		);
		await tx.wait();
		status = await Persona.connect(personaOwnerAddress).getLastPendingCertificate();
		expect(status[0]).to.equal(certificateIssuer._address);
	});

	it("Celo register a new certificate again", async function () {
		const tx = await Persona.connect(certificateIssuer).giveCertificate(
			ethers.utils.formatBytes32String("test"),
			"test",
			"test",
			"test"
		);
		await tx.wait();
		const count = await Persona.connect(personaOwnerAddress).getPendingCertificatesCount();
		expect(count).to.equal(2);
	});

	it("Celo process pending certificate as false", async function () {
		const tx = await Persona.connect(personaOwnerAddress).processLastPendingCertificate(false);
		await tx.wait();
		let status = await Persona.connect(personaOwnerAddress).getCertificate(0);
		expect(status[0]).to.equal("0x0000000000000000000000000000000000000000");
		const count = await Persona.connect(personaOwnerAddress).getPendingCertificatesCount();
		expect(count).to.equal(1);
		const count2 = await Persona.connect(personaOwnerAddress).getCertificatesCount();
		expect(count2).to.equal(0);
	});

	it("Celo process pending certificate as true", async function () {
		const tx = await Persona.connect(personaOwnerAddress).processLastPendingCertificate(true);
		await tx.wait();
		let status = await Persona.connect(personaOwnerAddress).getCertificate(0);
		expect(status[0]).to.equal(certificateIssuer._address);
		const count = await Persona.connect(personaOwnerAddress).getPendingCertificatesCount();
		expect(count).to.equal(0);
		const count2 = await Persona.connect(personaOwnerAddress).getCertificatesCount();
		expect(count2).to.equal(1);
	});
});
