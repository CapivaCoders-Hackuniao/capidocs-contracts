// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;

interface IValidatorFactory {
  function newValidator(address, bytes32) external returns (address);
}
