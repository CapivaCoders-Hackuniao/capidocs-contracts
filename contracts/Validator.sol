// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

import "./interfaces/IValidator.sol";
import "./interfaces/IPersona.sol";
import "./interfaces/IRegistry.sol";
import "./vendor/Ownable.sol";
import "./vendor/SafeMath.sol";
import "./vendor/MyUtils.sol";

contract Validator is Ownable, IValidator {
	using SafeMath for uint256;

	//Contract Info
	bytes32 public name;
	address public registry;
	address public paymentToken;
	string public ownerPublicKey;

	//Validator Configs
	mapping(bytes32 => bool) public documentTypes;
	mapping(bytes32 => uint256) public documentPrices;

	//Validator Queue
	mapping(uint256 => validation) public validationQueue;
	uint256 public validationQueueStart;
	uint256 public validationQueueEnd;

	//Validator Objects
	struct validation {
		address persona;
		bytes32 documentType;
		string[] documentLinks;
		bytes32[] documentHashes;
		string documentValue;
		bytes32 documentValueHash;
		bool processed;
	}

	//Constructor
	constructor(address _registry, bytes32 _name) {
		name = _name;
		registry = _registry;
		validationQueueStart = 1;
		validationQueueEnd = 0;
	}

	event newValidationRequest(address indexed sender, bytes32 indexed documentType);

	//View

	function getNextValidation()
		public
		view
		returns (
			address persona,
			bytes32 documentType,
			string[] memory documentLinks,
			bytes32[] memory documentHashes,
			string memory documentValue,
			bytes32 documentValueHash
		)
	{
		return (
			validationQueue[validationQueueStart].persona,
			validationQueue[validationQueueStart].documentType,
			validationQueue[validationQueueStart].documentLinks,
			validationQueue[validationQueueStart].documentHashes,
			validationQueue[validationQueueStart].documentValue,
			validationQueue[validationQueueStart].documentValueHash
		);
	}

	function getValidationAt(uint256 index)
		public
		view
		returns (
			address persona,
			bytes32 documentType,
			string[] memory documentLinks,
			bytes32[] memory documentHashes,
			string memory documentValue,
			bytes32 documentValueHash
		)
	{
		return (
			validationQueue[index].persona,
			validationQueue[index].documentType,
			validationQueue[index].documentLinks,
			validationQueue[index].documentHashes,
			validationQueue[index].documentValue,
			validationQueue[index].documentValueHash
		);
	}

	//Actions - Contract Info

	function changeName(bytes32 _name) public onlyOwner {
		name = _name;
	}

	function setPaymentToken(address token) public onlyOwner {
		paymentToken = token;
	}

	function transferOwnershipValidatorPK(address newOwner, string memory _ownerPublicKey) public override {
		transferOwnershipValidator(newOwner);
		ownerPublicKey = _ownerPublicKey;
	}

	function transferOwnershipValidator(address newOwner) public override {
		require(validationQueueStart > validationQueueEnd, "Validator: Can not transfer with open queue");
		if (_msgSender() != registry) IRegistry(registry).updateValidatorTransfer(owner(), newOwner);
		transferOwnership(newOwner);
	}

	//Actions - Validator Configs

	function setDocumentPrices(bytes32[] memory _documentTypes, uint256[] memory _documentPrices) public onlyOwner {
		for (uint256 i; i < _documentTypes.length; i++) {
			setDocumentPrice(_documentTypes[i], _documentPrices[i]);
		}
	}

	function setDocumentPrice(bytes32 documentType, uint256 documentPrice) public onlyOwner {
		documentPrices[documentType] = documentPrice;
	}

	function addDocumentTypes(bytes32[] memory _documentTypes) public onlyOwner {
		for (uint256 i; i < _documentTypes.length; i++) {
			addDocumentType(_documentTypes[i]);
		}
	}

	function addDocumentType(bytes32 documentType) public onlyOwner {
		documentTypes[documentType] = true;
	}

	function removeDocumentTypes(bytes32[] memory _documentTypes) public onlyOwner {
		for (uint256 i; i < _documentTypes.length; i++) {
			removeDocumentType(_documentTypes[i]);
		}
	}

	function removeDocumentType(bytes32 documentType) public onlyOwner {
		documentTypes[documentType] = false;
	}

	//Actions - Validator

	//Validations are processed in FIFO
	function processValidation(uint8 status, string memory signature) public onlyOwner {
		require(validationQueueStart <= validationQueueEnd, "Validator: Queue empty");
		if (!validationQueue[validationQueueStart].processed) {
			IPersona(validationQueue[validationQueueStart].persona).validatorAnswer(
				validationQueue[validationQueueStart].documentType,
				status,
				block.timestamp,
				signature
			);
			validationQueue[validationQueueStart].processed = true;
		}
		validationQueueStart = validationQueueStart.add(1);
	}

	//Use with caution
	function processValidationAt(
		uint256 index,
		uint8 status,
		string memory signature
	) public onlyOwner {
		require(!validationQueue[index].processed, "Validator: Already processed");
		IPersona(validationQueue[index].persona).validatorAnswer(validationQueue[index].documentType, status, block.timestamp, signature);
		validationQueue[index].processed = true;
	}

	//Actions - Extenal - Persona

	function askValidation(
		bytes32 documentType,
		string[] memory documentLinks,
		bytes32[] memory documentHashes,
		string memory documentValue,
		bytes32 documentValueHash
	) external override {
		require(IRegistry(registry).isPersona(_msgSender()), "Validator: Address is not registered as validator");
		require(documentTypes[documentType], "Validator: Validator does not validate this kind of document");
		validationQueueEnd = validationQueueEnd.add(1);
		validationQueue[validationQueueEnd].persona = _msgSender();
		validationQueue[validationQueueEnd].documentType = documentType;
		validationQueue[validationQueueEnd].documentLinks = documentLinks;
		validationQueue[validationQueueEnd].documentHashes = documentHashes;
		validationQueue[validationQueueEnd].documentValue = documentValue;
		validationQueue[validationQueueEnd].documentValueHash = documentValueHash;
		if (documentPrices[documentType] > 0) processPayment(documentPrices[documentType]);
		emit newValidationRequest(_msgSender(), documentType);
	}

	function processPayment(uint256 price) internal {
		require(paymentToken != address(0), "Validator: Payment Token is not set up");
		TransferHelper.safeTransferFrom(paymentToken, _msgSender(), owner(), price);
	}
}
