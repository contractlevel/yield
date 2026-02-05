// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    ERC20BurnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {
    AccessControlDefaultAdminRulesUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IGetCCIPAdmin} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IGetCCIPAdmin.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC677} from "@chainlink/contracts/src/v0.8/shared/token/ERC677/IERC677.sol";
import {IERC677Receiver} from "@chainlink/contracts/src/v0.8/shared/interfaces/IERC677Receiver.sol";
import {IBurnMintERC677Upgradeable, IERC20} from "./interfaces/IBurnMintERC677Upgradeable.sol";

/// @title Share
/// @author Judge Finance
/// @notice Upgradeable ERC677 token with access control
/// @notice Deployer must grant mint and burn roles to (crosschain) Yield contracts
contract Share is
    Initializable,
    UUPSUpgradeable,
    IGetCCIPAdmin,
    IBurnMintERC677Upgradeable,
    ERC20BurnableUpgradeable,
    AccessControlDefaultAdminRulesUpgradeable
{
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @custom:storage-location erc7201:yieldcoin.storage.Share
    struct ShareStorage {
        address s_ccipAdmin;
        mapping(bytes32 role => EnumerableSet.AddressSet) s_roleMembers;
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Share__NotERC677Receiver();
    error Share__InvalidRecipient(address recipient);

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice The initial delay for transferring the admin role
    uint48 internal constant INITIAL_DEFAULT_ADMIN_ROLE_TRANSFER_DELAY = 259200 seconds; // 3 days

    // keccak256(abi.encode(uint256(keccak256("yieldcoin.storage.Share")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SHARE_STORAGE_LOCATION =
        0xe4963c679d07e6dc2d227d26eb05e3128d8de183944771ed5ba5665e6ea96200;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event CCIPAdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Ensures the target address is not itself
    /// @param target The address to check
    modifier notToSelf(address target) {
        if (target == address(this)) revert Share__InvalidRecipient(target);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR / INIT
    //////////////////////////////////////////////////////////////*/
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the token, admin rules, and default roles
    /// @dev Token decimals are fixed at 18 inside of ERC20Upgradeable
    function initialize() external initializer {
        __ERC20_init("YieldCoin", "YIELD");
        __ERC20Burnable_init();
        __AccessControl_init();
        __AccessControlDefaultAdminRules_init(INITIAL_DEFAULT_ADMIN_ROLE_TRANSFER_DELAY, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _getShareStorage().s_ccipAdmin = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IBurnMintERC677Upgradeable
    /// @dev Uses OZ ERC20Upgradeable _burn to disallow burning from address(0).
    /// @dev Decreases the total supply.
    function burn(uint256 amount)
        public
        override(IBurnMintERC677Upgradeable, ERC20BurnableUpgradeable)
        onlyRole(BURNER_ROLE)
    {
        super.burn(amount);
    }

    /// @inheritdoc IBurnMintERC677Upgradeable
    /// @dev Alias for BurnFrom for compatibility with the older naming convention.
    /// @dev Uses burnFrom for all validation & logic.
    function burn(address account, uint256 amount) public onlyRole(BURNER_ROLE) {
        burnFrom(account, amount);
    }

    /// @inheritdoc IBurnMintERC677Upgradeable
    /// @dev Uses OZ ERC20Upgradeable _burn to disallow burning from address(0).
    /// @dev Decreases the total supply.
    function burnFrom(address account, uint256 amount)
        public
        override(IBurnMintERC677Upgradeable, ERC20BurnableUpgradeable)
        onlyRole(BURNER_ROLE)
    {
        super.burnFrom(account, amount);
    }

    /// @inheritdoc IBurnMintERC677Upgradeable
    /// @dev Uses OZ ERC20 _mint to disallow minting to address(0).
    /// @dev Disallows minting to address(this)
    /// @dev Increases the total supply.
    function mint(address account, uint256 amount) external onlyRole(MINTER_ROLE) notToSelf(account) {
        _mint(account, amount);
    }

    /// @inheritdoc IERC677
    /// @dev Uses Chainlink's ERC677 implementation of transferAndCall
    /// @dev OZ onlyProxy modifier to prevent calls from implementation contract
    function transferAndCall(address to, uint256 amount, bytes memory data) public onlyProxy returns (bool success) {
        super.transfer(to, amount);
        emit Transfer(msg.sender, to, amount, data);
        if (to.code.length > 0) {
            IERC677Receiver(to).onTokenTransfer(msg.sender, amount, data);
        }
        return true;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlDefaultAdminRulesUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IBurnMintERC677Upgradeable).interfaceId || interfaceId == type(IERC677).interfaceId
            || interfaceId == type(IERC20).interfaceId || interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IGetCCIPAdmin).interfaceId || super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice grants both mint and burn roles to `burnAndMinter`.
    /// @param burnAndMinter The address to be granted both roles to
    function grantMintAndBurnRoles(address burnAndMinter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, burnAndMinter);
        grantRole(BURNER_ROLE, burnAndMinter);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc AccessControlDefaultAdminRulesUpgradeable
    function _grantRole(bytes32 role, address account) internal override returns (bool granted) {
        granted = super._grantRole(role, account);
        if (granted) {
            _getShareStorage().s_roleMembers[role].add(account);
        }
    }

    /// @inheritdoc AccessControlDefaultAdminRulesUpgradeable
    function _revokeRole(bytes32 role, address account) internal override returns (bool revoked) {
        revoked = super._revokeRole(role, account);
        if (revoked) {
            _getShareStorage().s_roleMembers[role].remove(account);
        }
    }

    /// @dev Disallows minting and transferring to address(this).
    function _update(address from, address to, uint256 value) internal virtual override notToSelf(to) {
        super._update(from, to, value);
    }

    /// @dev Uses OZ ERC20Upgradeable _approve to disallow approving for address(0).
    /// @dev Disallows approving for address(this).
    function _approve(address owner, address spender, uint256 value, bool emitEvent)
        internal
        virtual
        override
        notToSelf(spender)
    {
        super._approve(owner, spender, value, emitEvent);
    }

    /// @notice Authorizes an upgrade to a new implementation
    /// @param newImplementation The address of the new implementation
    /// @dev Revert if msg.sender does not have UPGRADER_ROLE
    /// @dev Required by UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /*//////////////////////////////////////////////////////////////
                         PRIVATE PURE / STORAGE
    //////////////////////////////////////////////////////////////*/
    /// @notice Get the Share storage
    /// @return $ The Share storage
    function _getShareStorage() private pure returns (ShareStorage storage $) {
        assembly {
            $.slot := SHARE_STORAGE_LOCATION
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Transfers the CCIPAdmin role to a new address
    /// @dev only the owner can call this function, NOT the current ccipAdmin, and 2-step ownership transfer is used.
    /// @param newAdmin The address to transfer the CCIPAdmin role to. Setting to address(0) is a valid way to revoke
    /// the role
    function setCCIPAdmin(address newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ShareStorage storage $ = _getShareStorage();
        address currentAdmin = $.s_ccipAdmin;

        $.s_ccipAdmin = newAdmin;

        emit CCIPAdminTransferred(currentAdmin, newAdmin);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IGetCCIPAdmin
    /// @notice Returns the current CCIPAdmin address
    function getCCIPAdmin() external view override returns (address) {
        return _getShareStorage().s_ccipAdmin;
    }

    /// @notice This function returns the members of a role
    /// @param role The role to get the members of
    /// @return roleMembers members of the role
    function getRoleMembers(bytes32 role) public view returns (address[] memory) {
        return _getShareStorage().s_roleMembers[role].values();
    }
}
