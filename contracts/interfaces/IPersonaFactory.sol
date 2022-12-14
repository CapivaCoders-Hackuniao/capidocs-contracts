// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;

interface IPersonaFactory {
  function newPersona(address, bytes32) external returns (address);
}
