// File: contracts\interfaces\IPersonaFactory.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface IPersonaFactory {
  function newPersona(address, bytes32) external returns (address);
}

// File: contracts\vendor\Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal virtual view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal virtual view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// File: contracts\vendor\Ownable.sol


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts\vendor\EnumerableSet.sol

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// File: contracts\vendor\Address.sol

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts\vendor\AccessControl.sol
/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts\interfaces\IPersona.sol

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

// File: contracts\interfaces\IRegistry.sol

interface IRegistry {
	function isValidator(address) external returns (bool);

	function isPersona(address) external returns (bool);

	function updatePersonaTransfer(address, address) external;

	function updateValidatorTransfer(address, address) external;
}

// File: contracts\interfaces\IValidator.sol


interface IValidator {
  function askValidation(
    bytes32,
    string[] memory,
    bytes32[] memory,
	string memory,
    bytes32
  ) external;

  function transferOwnershipValidator(address) external;
}

// File: contracts\Persona.sol


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
		bytes32 documentValueHash,
		bytes32[] memory _documentHashes
	) public onlyOwner {
		require(documentValueHash != bytes32(""), "Persona: Document must not be empty");
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
	}
}

// File: contracts\PersonaFactory.sol
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

// File: contracts\interfaces\IValidatorFactory.sol

interface IValidatorFactory {
  function newValidator(address, bytes32) external returns (address);
}

// File: contracts\vendor\SafeMath.sol

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts\vendor\MyUtils.sol


pragma solidity ^0.7.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts\Validator.sol
contract Validator is Ownable, IValidator {
	using SafeMath for uint256;

	//Contract Info
	bytes32 public name;
	address public registry;
	address public paymentToken;

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
	}

	function processPayment(uint256 price) internal {
		require(paymentToken != address(0), "Validator: Payment Token is not set up");
		TransferHelper.safeTransferFrom(paymentToken, _msgSender(), owner(), price);
	}
}

// File: contracts\ValidatorFactory.sol
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

// File: contracts\Registry.sol
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

	function validatorSelfRegistry(bytes32 _name) public {
		require(!requireRoleValidator, "Registry: Self registry disabled");
		newValidator(_msgSender(), _name);
	}

	function personaCreateRegistry(address accOwner, bytes32 _name) public {
		require(hasRole(ACC_MANAGER_ROLE, _msgSender()));
		newPersona(accOwner, _name);
	}

	function validatorCreateRegistry(address accOwner, bytes32 _name) public {
		require(hasRole(ACC_MANAGER_ROLE, _msgSender()));
		newValidator(accOwner, _name);
	}

	function newPersona(address accOwner, bytes32 _name) internal returns (address) {
		require(ownerToPersona[accOwner] == address(0), "Registry: persona already registered");
		address persona = IPersonaFactory(personaFactory).newPersona(address(this), _name);
		ownerToPersona[accOwner] = persona;
		IPersona(persona).transferOwnershipPersona(accOwner);
		_setupRole(PERSONA_ROLE, persona);
		return persona;
	}

	function newValidator(address accOwner, bytes32 _name) internal returns (address) {
		require(ownerToValidator[accOwner] == address(0), "Registry: validator already registered");
		address validator = IValidatorFactory(validatorFactory).newValidator(address(this), _name);
		ownerToValidator[accOwner] = validator;
		IValidator(validator).transferOwnershipValidator(accOwner);
		_setupRole(VALIDATOR_ROLE, validator);
		return validator;
	}
}
