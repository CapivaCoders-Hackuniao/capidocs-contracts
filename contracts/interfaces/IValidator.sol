// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IValidator {
  function askValidation(
    bytes32,
    string[] memory,
    bytes32[] memory,
	string memory,
    bytes32
  ) external;

  function transferOwnershipValidator(address) external;

  function transferOwnershipValidatorPK(address, string memory) external;

}
