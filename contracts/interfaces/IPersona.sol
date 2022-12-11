// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;

interface IPersona {
	function validatorAnswer(
		bytes32,
		uint8,
		uint256,
		string memory
	) external;

	function transferOwnershipPersona(address) external;

	function giveCertificate(
		bytes32,
		string memory,
		string memory,
		string memory
	) external;
}
