// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;

import "./interfaces/IPersonaFactory.sol";
import "./Persona.sol";
import "./vendor/AccessControl.sol";

contract PersonaFactory is IPersonaFactory, AccessControl {
  function newPersona(address registry, bytes32 name)
    public
    override
    returns (address personaAddressContract)
  {
    Persona persona = new Persona(registry, name);
    persona.transferOwnership(_msgSender());
    personaAddressContract = address(persona);
  }
}
