// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

import "./vendor/Ownable.sol";
import "./vendor/AccessControl.sol";

import "./interfaces/IPersona.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IValidator.sol";

contract Persona is Ownable, IPersona {
	//Contract Info
	address public registry;
	bytes32 public name;

	//Documents Storage
	bytes32[] public documents;
	mapping(bytes32 => FieldInfo) public personaInfos;

	//Certificates Storage
	Certificate[] public certificates;
	Certificate[] pendingCertificates;

	//Documents Objects
	enum StatusValidation {NotEvaluated, PendingValidation, Validated, NotValidated}

	struct FieldInfo {
		string baseValue;
		bytes32 documentValueHash;
		bytes32[] documentHashes;
		address[] validators;
		mapping(address => ValidatorsAnswer) validatorsAnswersMap;
	}

	struct ValidatorsAnswer {
		StatusValidation validation;
		uint256 validationTimestamp;
		string signature;
	}

	//Certificates Objects
	struct Certificate {
		address issuer;
		bytes32 givenName;
		string value;
		string content;
		string signature;
		uint256 timestamp;
	}

	//Constructor
	constructor(address _registry, bytes32 _name) {
		name = _name;
		registry = _registry;
	}

	//Events
	event personaAskToValidate(
		address indexed validatorAddress,
		bytes32 indexed documentType,
		string[] documentLinks,
		string documentValue
	);

	event validatorAnswerValidation(bytes32 indexed documentType, uint8 status, uint256 indexed timestamp, string signature);
	
	event newCertificate(address indexed sender, bytes32 indexed name, uint256 indexed timestamp);

	//View - Documents

	function getDocuments() public view returns (bytes32[] memory){
		return documents;
	}

	function getValidationStatus(bytes32 documentType, address validator)
		public
		view
		returns (
			uint8,
			uint256,
			string memory
		)
	{
		return (
			uint8(personaInfos[documentType].validatorsAnswersMap[validator].validation),
			personaInfos[documentType].validatorsAnswersMap[validator].validationTimestamp,
			personaInfos[documentType].validatorsAnswersMap[validator].signature
		);
	}

	function getValidators(bytes32 documentType) public view returns (address[] memory) {
		return personaInfos[documentType].validators;
	}

	function getDocumentHashes(bytes32 documentType) public view returns (bytes32[] memory) {
		return personaInfos[documentType].documentHashes;
	}

	function personaFieldExists(bytes32 documentType) public view returns (bool) {
		return personaInfos[documentType].documentValueHash != bytes32("");
	}

	//View - Certificates

	function getCertificatesCount() public view returns (uint256) {
		return certificates.length;
	}

	function getPendingCertificatesCount() public view onlyOwner returns (uint256) {
		return pendingCertificates.length;
	}

	function getCertificate(uint256 index)
		public
		view
		returns (
			address,
			bytes32,
			string memory,
			string memory,
			string memory,
			uint256
		)
	{
		uint256 length = certificates.length;
		if (index >= length) return (address(0), bytes32(""), "", "", "", 0);
		return (
			certificates[index].issuer,
			certificates[index].givenName,
			certificates[index].value,
			certificates[index].content,
			certificates[index].signature,
			certificates[index].timestamp
		);
	}

	function getLastPendingCertificate()
		public
		view
		onlyOwner
		returns (
			address,
			bytes32,
			string memory,
			string memory,
			string memory,
			uint256
		)
	{
		uint256 length = pendingCertificates.length;
		if (length == 0) return (address(0), bytes32(""), "", "", "", 0);
		return (
			pendingCertificates[length - 1].issuer,
			pendingCertificates[length - 1].givenName,
			pendingCertificates[length - 1].value,
			pendingCertificates[length - 1].content,
			pendingCertificates[length - 1].signature,
			pendingCertificates[length - 1].timestamp
		);
	}

	//Actions - Contract Info

	function changeName(bytes32 _name) public onlyOwner {
		name = _name;
	}

	function transferOwnershipPersona(address newOwner) public override onlyOwner {
		require(documents.length == 0, "Persona: Persona must be empty to transfer");
		if (_msgSender() != registry) IRegistry(registry).updatePersonaTransfer(owner(), newOwner);
		transferOwnership(newOwner);
	}

	//Actions - Documents

	function addField(
		bytes32 documentType,
		string memory baseValue,
		bytes32 documentValueHash,
		bytes32[] memory documentHashes
	) public onlyOwner {
		require(!personaFieldExists(documentType), "Persona: Document already added!");
		require(documentValueHash != bytes32(""), "Persona: Document must not be empty");
		personaInfos[documentType].baseValue = baseValue;
		personaInfos[documentType].documentHashes = documentHashes;
		personaInfos[documentType].documentValueHash = documentValueHash;
		documents.push(documentType);
	}

	function replaceField(
		bytes32 documentType,
		string memory baseValue,
		bytes32 documentValueHash,
		bytes32[] memory _documentHashes
	) public onlyOwner {
		require(documentValueHash != bytes32(""), "Persona: Document must not be empty");
		personaInfos[documentType].baseValue = baseValue;
		personaInfos[documentType].documentHashes = _documentHashes;
		personaInfos[documentType].documentValueHash = documentValueHash;
		personaInfos[documentType].validators = new address[](0);
	}

	function askToValidate(
		address validatorAddress,
		bytes32 documentType,
		string[] memory documentLinks,
		string memory documentValue
	) public onlyOwner {
		require(personaFieldExists(documentType), "Persona: Document not added");
		require(IRegistry(registry).isValidator(validatorAddress), "Persona: Address is not registered as validator");
		require(
			personaInfos[documentType].validatorsAnswersMap[validatorAddress].validation == StatusValidation.NotEvaluated,
			"Persona: Validation already requested"
		);
		IValidator(validatorAddress).askValidation(
			documentType,
			documentLinks,
			personaInfos[documentType].documentHashes,
			documentValue,
			personaInfos[documentType].documentValueHash
		);
		personaInfos[documentType].validators.push(validatorAddress);
		personaInfos[documentType].validatorsAnswersMap[validatorAddress] = ValidatorsAnswer({
			validation: StatusValidation.PendingValidation,
			validationTimestamp: 0,
			signature: ""
		});
		emit personaAskToValidate(validatorAddress, documentType, documentLinks, documentValue);
	}

	//Actions - Documents - External Calls

	function validatorAnswer(
		bytes32 documentType,
		uint8 status,
		uint256 timestamp,
		string memory signature
	) external override {
		require(
			personaInfos[documentType].validatorsAnswersMap[_msgSender()].validation == StatusValidation.PendingValidation,
			"Persona: Validation not requested"
		);
		personaInfos[documentType].validatorsAnswersMap[_msgSender()].validation = StatusValidation(status);
		personaInfos[documentType].validatorsAnswersMap[_msgSender()].validationTimestamp = timestamp;
		personaInfos[documentType].validatorsAnswersMap[_msgSender()].signature = signature;
		emit validatorAnswerValidation(documentType, status, timestamp, signature);
	}

	//Actions - Certificates

	//Certificates are processed in LIFO
	function processLastPendingCertificate(bool approved) public onlyOwner {
		require(pendingCertificates.length > 0, "Persona: No pending certificates");
		if (approved) certificates.push(pendingCertificates[pendingCertificates.length - 1]);
		pendingCertificates.pop();
	}

	//Give certificate using the Persona contract (signed with the owner)
	function giveCertificateTo(
		address persona,
		bytes32 givenName,
		string memory value,
		string memory content,
		string memory signature
	) public onlyOwner {
		IPersona(persona).giveCertificate(givenName, value, content, signature);
	}

	//Actions - Certificates - External Calls

	function giveCertificate(
		bytes32 givenName,
		string memory value,
		string memory content,
		string memory signature
	) external override {
		pendingCertificates.push(Certificate(_msgSender(), givenName, value, content, signature, block.timestamp));
		emit newCertificate(_msgSender(), givenName, block.timestamp);
	}
}
