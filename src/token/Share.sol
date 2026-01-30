// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// --- OpenZeppelin Upgrades ---
import {
    ERC20BurnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {
    AccessControlDefaultAdminRulesUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// --- OpenZeppelin Utilities ---
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// --- Chainlink Interfaces ---
import {IGetCCIPAdmin} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IGetCCIPAdmin.sol";
import {IERC677} from "@chainlink/contracts/src/v0.8/shared/token/ERC677/IERC677.sol";
import {IERC677Receiver} from "@chainlink/contracts/src/v0.8/shared/interfaces/IERC677Receiver.sol";
import {IBurnMintERC20} from "@chainlink/contracts/src/v0.8/shared/token/ERC20/IBurnMintERC20.sol";

/// @title Share
/// @author Judge Finance
/// @notice Upgradeable ERC677 token with hybrid access control.
/// @dev Combines DefaultAdminRules (Time-lock) for security with manual EnumerableSets for role visibility.
contract Share is
    Initializable,
    UUPSUpgradeable,
    IERC677,
    IGetCCIPAdmin,
    ERC20BurnableUpgradeable,
    AccessControlDefaultAdminRulesUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    /// @custom:storage-location erc7201:yieldcoin.storage.Share
    struct ShareStorage {
        address s_ccipAdmin;
        EnumerableSet.AddressSet s_minters;
        EnumerableSet.AddressSet s_burners;
    }

    /*//////////////////////////////////////////////////////////////
                           STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
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
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Share__ZeroAddress();
    error Share__NotERC677Receiver();
    error Share__InvalidRecipient();

    /*//////////////////////////////////////////////////////////////
                           CONSTRUCTOR / INIT
    //////////////////////////////////////////////////////////////*/
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the token, admin rules, and default roles
    function initialize() external initializer {
        __ERC20_init("YieldCoin", "YIELD");
        __ERC20Burnable_init();

        // Initialize AccessControl with a 3-day delay
        __AccessControlDefaultAdminRules_init(3 days, msg.sender);

        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);

        _getShareStorage().s_ccipAdmin = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                     HYBRID ROLE ENUMERATION HOOKS
    //////////////////////////////////////////////////////////////*/
    /// @dev Hook into internal role granting to update manual EnumerableSets
    function _grantRole(bytes32 role, address account) internal override returns (bool) {
        bool result = super._grantRole(role, account);

        if (result) {
            ShareStorage storage $ = _getShareStorage();
            if (role == MINTER_ROLE) {
                $.s_minters.add(account);
            } else if (role == BURNER_ROLE) {
                $.s_burners.add(account);
            }
        }
        return result;
    }

    /// @dev Hook into internal role revoking to update manual EnumerableSets
    function _revokeRole(bytes32 role, address account) internal override returns (bool) {
        bool result = super._revokeRole(role, account);

        if (result) {
            ShareStorage storage $ = _getShareStorage();
            if (role == MINTER_ROLE) {
                $.s_minters.remove(account);
            } else if (role == BURNER_ROLE) {
                $.s_burners.remove(account);
            }
        }
        return result;
    }

    /*//////////////////////////////////////////////////////////////
                            ROLE GETTERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns all permissioned minters
    function getMinters() external view returns (address[] memory) {
        return _getShareStorage().s_minters.values();
    }

    /// @notice Returns all permissioned burners
    function getBurners() external view returns (address[] memory) {
        return _getShareStorage().s_burners.values();
    }

    /// @notice Grant both mint and burn roles to a single address
    function grantMintAndBurnRoles(address burnAndMinter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, burnAndMinter);
        grantRole(BURNER_ROLE, burnAndMinter);
    }

    /*//////////////////////////////////////////////////////////////
                                ERC677
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IERC677
    function transferAndCall(address to, uint256 amount, bytes memory data) public override returns (bool success) {
        transfer(to, amount);
        emit Transfer(msg.sender, to, amount, data);

        if (to.code.length > 0) {
            try IERC677Receiver(to).onTokenTransfer(msg.sender, amount, data) {}
            catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert Share__NotERC677Receiver();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                          RESTRICTED BURNING
    //////////////////////////////////////////////////////////////*/
    function burn(uint256 amount) public override(ERC20BurnableUpgradeable) onlyRole(BURNER_ROLE) {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override(ERC20BurnableUpgradeable) onlyRole(BURNER_ROLE) {
        super.burnFrom(account, amount);
    }

    /*//////////////////////////////////////////////////////////////
                                MINTING
    //////////////////////////////////////////////////////////////*/
    function mint(address account, uint256 amount) external onlyRole(MINTER_ROLE) {
        if (account == address(this)) revert Share__InvalidRecipient();
        _mint(account, amount);
    }

    /*//////////////////////////////////////////////////////////////
                             SAFETY CHECKS
    //////////////////////////////////////////////////////////////*/
    function _update(address from, address to, uint256 value) internal override {
        if (to == address(this)) revert Share__InvalidRecipient();
        super._update(from, to, value);
    }

    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal override {
        if (spender == address(this)) revert Share__InvalidRecipient();
        super._approve(owner, spender, value, emitEvent);
    }

    /*//////////////////////////////////////////////////////////////
                             CCIP ADMIN
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IGetCCIPAdmin
    function getCCIPAdmin() external view override returns (address) {
        return _getShareStorage().s_ccipAdmin;
    }

    function setCCIPAdmin(address newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newAdmin == address(0)) revert Share__ZeroAddress();

        ShareStorage storage $ = _getShareStorage();
        address oldAdmin = $.s_ccipAdmin;
        $.s_ccipAdmin = newAdmin;

        emit CCIPAdminTransferred(oldAdmin, newAdmin);
    }

    /*//////////////////////////////////////////////////////////////
                               METADATA
    //////////////////////////////////////////////////////////////*/
    function decimals() public view virtual override(ERC20Upgradeable) returns (uint8) {
        return 18;
    }

    /*//////////////////////////////////////////////////////////////
                       CONFLICT RESOLUTION OVERRIDES
    //////////////////////////////////////////////////////////////*/
    function totalSupply() public view override(ERC20Upgradeable) returns (uint256) {
        return super.totalSupply();
    }

    function balanceOf(address account) public view override(ERC20Upgradeable) returns (uint256) {
        return super.balanceOf(account);
    }

    function transfer(address to, uint256 amount) public override(ERC20Upgradeable) returns (bool) {
        return super.transfer(to, amount);
    }

    function allowance(address owner, address spender) public view override(ERC20Upgradeable) returns (uint256) {
        return super.allowance(owner, spender);
    }

    function approve(address spender, uint256 amount) public override(ERC20Upgradeable) returns (bool) {
        return super.approve(spender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override(ERC20Upgradeable) returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                               INTERNALS
    //////////////////////////////////////////////////////////////*/
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function _getShareStorage() private pure returns (ShareStorage storage $) {
        assembly {
            $.slot := SHARE_STORAGE_LOCATION
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlDefaultAdminRulesUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC677).interfaceId || interfaceId == type(IBurnMintERC20).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
