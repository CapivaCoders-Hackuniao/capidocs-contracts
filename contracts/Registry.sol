// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8;

import "./vendor/AccessControl.sol";
import "./vendor/Ownable.sol";

import "./interfaces/IPersona.sol";
import "./interfaces/IValidator.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/IPersonaFactory.sol";
import "./interfaces/IValidatorFactory.sol";

contract Registry is Ownable, AccessControl, IRegistry {
	bytes32 public constant PERSONA_ROLE = keccak256("PERSONA_ROLE");
	bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
	bytes32 public constant ACC_MANAGER_ROLE = keccak256("ACC_MANAGER_ROLE");

	//Factory
	address public personaFactory;
	address public validatorFactory;

	mapping(address => address) public ownerToPersona;
	mapping(address => address) public ownerToValidator;

	bytes32 public name;
	bool public requireRolePersona;
	bool public requireRoleValidator;

	constructor(
		bytes32 _name,
		bool _requireRolePersona,
		bool _requireRoleValidator,
		address personaFactoryAddress,
		address validatorFactoryAddress
	) {
		name = _name;
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(ACC_MANAGER_ROLE, _msgSender());
    	_setRoleAdmin(PERSONA_ROLE, ACC_MANAGER_ROLE);
   		_setRoleAdmin(VALIDATOR_ROLE, ACC_MANAGER_ROLE);
		requireRolePersona = _requireRolePersona;
		requireRoleValidator = _requireRoleValidator;
		personaFactory = personaFactoryAddress;
		validatorFactory = validatorFactoryAddress;
	}

	function changeName(bytes32 _name) public onlyOwner {
		name = _name;
	}

	function changeRequireRolePersona(bool _requireRolePersona) public onlyOwner {
		requireRolePersona = _requireRolePersona;
	}

	function changeRequireRoleValidator(bool _requireRoleValidator) public onlyOwner {
		requireRoleValidator = _requireRoleValidator;
	}

	function updateFactoryAddresses(address personaFactoryAddress, address validatorFactoryAddress) public onlyOwner {
		personaFactory = personaFactoryAddress == address(0) ? personaFactory : personaFactoryAddress;
		validatorFactory = validatorFactoryAddress == address(0) ? validatorFactory : validatorFactoryAddress;
	}

	function updatePersonaTransfer(address owner, address newOwner) external override {
		require(ownerToPersona[owner] == _msgSender(), "Registry: Not Owner");
		ownerToPersona[newOwner] = _msgSender();
		ownerToPersona[owner] = address(0);
	}

	function updateValidatorTransfer(address owner, address newOwner) external override {
		require(ownerToValidator[owner] == _msgSender(), "Registry: Not Owner");
		ownerToValidator[newOwner] = _msgSender();
		ownerToValidator[owner] = address(0);
	}

	function isValidator(address addr) public override view returns (bool) {
		return hasRole(VALIDATOR_ROLE, addr);
	}

	function isPersona(address addr) public override view returns (bool) {
		return hasRole(PERSONA_ROLE, addr);
	}

	function personaSelfRegistry(bytes32 _name) public {
		require(!requireRolePersona, "Registry: Self registry disabled");
		newPersona(_msgSender(), _name);
	}

	function validatorSelfRegistry(bytes32 _name, string memory pubKey) public {
		require(!requireRoleValidator, "Registry: Self registry disabled");
		newValidator(_msgSender(), _name, pubKey);
	}

	function personaCreateRegistry(address accOwner, bytes32 _name) public {
		require(hasRole(ACC_MANAGER_ROLE, _msgSender()));
		newPersona(accOwner, _name);
	}

	function validatorCreateRegistry(address accOwner, bytes32 _name, string memory pubKey) public {
		require(hasRole(ACC_MANAGER_ROLE, _msgSender()));
		newValidator(accOwner, _name, pubKey);
	}

	function newPersona(address accOwner, bytes32 _name) internal returns (address) {
		require(ownerToPersona[accOwner] == address(0), "Registry: persona already registered");
		address persona = IPersonaFactory(personaFactory).newPersona(address(this), _name);
		ownerToPersona[accOwner] = persona;
		IPersona(persona).transferOwnershipPersona(accOwner);
		_setupRole(PERSONA_ROLE, persona);
		return persona;
	}

	function newValidator(address accOwner, bytes32 _name, string memory pubKey) internal returns (address) {
		require(ownerToValidator[accOwner] == address(0), "Registry: validator already registered");
		address validator = IValidatorFactory(validatorFactory).newValidator(address(this), _name);
		ownerToValidator[accOwner] = validator;
		IValidator(validator).transferOwnershipValidatorPK(accOwner, pubKey);
		_setupRole(VALIDATOR_ROLE, validator);
		return validator;
	}
}
