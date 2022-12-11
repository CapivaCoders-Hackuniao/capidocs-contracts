// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;

import "./interfaces/IValidatorFactory.sol";
import "./Validator.sol";
import "./vendor/AccessControl.sol";

contract ValidatorFactory is IValidatorFactory, AccessControl {
  function newValidator(address registry, bytes32 name)
    public
    override
    returns (address validatorAddressContract)
  {
    Validator validator = new Validator(registry, name);
    validator.transferOwnership(_msgSender());
    validatorAddressContract = address(validator);
  }
}
