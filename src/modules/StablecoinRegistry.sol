// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IStablecoinRegistry} from "../interfaces/IStablecoinRegistry.sol";

/// @title StablecoinRegistry
/// @author @contractlevel
/// @notice Registry for stablecoin addresses per chain
/// @dev Maps stablecoinId (bytes32) to stablecoin address
contract StablecoinRegistry is IStablecoinRegistry, Ownable2Step {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice Stablecoin ID to stablecoin address
    /// @notice Stablecoin IDs should be generated using keccak256 with consistent formatting:
    /// @dev Examples:
    /// @dev bytes32 usdcId = keccak256("USDC");
    /// @dev bytes32 usdtId = keccak256("USDT");
    /// @dev bytes32 ghoId = keccak256("GHO");
    mapping(bytes32 stablecoinId => address stablecoin) internal s_stablecoins;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a stablecoin is registered or updated
    event StablecoinSet(bytes32 indexed stablecoinId, address indexed stablecoin);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Setter for registering and deregistering a stablecoin
    /// @dev Revert if msg.sender is not the owner
    /// @param stablecoinId The stablecoin ID should be generated using keccak256 with consistent formatting:
    /// @dev Examples:
    /// @dev bytes32 usdcId = keccak256("USDC");
    /// @dev bytes32 usdtId = keccak256("USDT");
    /// @dev bytes32 ghoId = keccak256("GHO");
    /// @param stablecoin The stablecoin address (use address(0) to deregister)
    function setStablecoin(bytes32 stablecoinId, address stablecoin) external onlyOwner {
        s_stablecoins[stablecoinId] = stablecoin;
        emit StablecoinSet(stablecoinId, stablecoin);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Get the stablecoin address for a given stablecoin ID
    /// @param stablecoinId The stablecoin ID
    /// @return stablecoin The stablecoin address
    function getStablecoin(bytes32 stablecoinId) external view returns (address stablecoin) {
        stablecoin = s_stablecoins[stablecoinId];
    }

    /// @notice Check if a stablecoin is supported
    /// @param stablecoinId The stablecoin ID
    /// @return isSupported Whether the stablecoin is supported on this chain
    function isStablecoinSupported(bytes32 stablecoinId) external view returns (bool isSupported) {
        isSupported = s_stablecoins[stablecoinId] != address(0);
    }
}
