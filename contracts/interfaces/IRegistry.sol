// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;

interface IRegistry {
	function isValidator(address) external returns (bool);

	function isPersona(address) external returns (bool);

	function updatePersonaTransfer(address, address) external;

	function updateValidatorTransfer(address, address) external;
}
