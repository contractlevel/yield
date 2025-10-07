// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title StablecoinRegistry
/// @author @judgestef
/// @notice Registry for stablecoins
contract StablecoinRegistry is Ownable2Step {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    struct Stablecoin {
        address stablecoin;
        uint8 decimals;
    }
    /// @notice Stablecoin ID to stablecoin
    /// @notice Stablecoin ID should be generated using keccak256 with consistent formatting:
    /// @dev Examples:
    /// @dev bytes32 usdcId = keccak256(IERC20Metadata(stablecoin).symbol());
    mapping(bytes32 stablecoinId => Stablecoin stablecoin) internal s_stablecoins;
    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a stablecoin is registered
    event StablecoinRegistered(bytes32 indexed stablecoinId, address indexed stablecoinAddress);
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                               EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @notice Setter for registering a stablecoin
    /// @dev Revert if msg.sender is not the owner
    /// @param stablecoinId The stablecoin ID should be generated using keccak256 with consistent formatting:
    /// @dev Examples:
    /// @dev bytes32 usdcId = keccak256(IERC20Metadata(stablecoin).symbol());
    /// @param stablecoin The stablecoin struct containing the stablecoin address and decimals
    function setStablecoin(bytes32 stablecoinId, Stablecoin memory stablecoin) external onlyOwner {
        s_stablecoins[stablecoinId] = stablecoin;
        emit StablecoinRegistered(stablecoinId, stablecoin.stablecoin);
    }

    /*//////////////////////////////////////////////////////////////
                               GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Getter for a stablecoin
    /// @param stablecoinId The stablecoin ID
    /// @return stablecoin The stablecoin struct containing the stablecoin address and decimals
    function getStablecoin(bytes32 stablecoinId) external view returns (Stablecoin memory stablecoin) {
        stablecoin = s_stablecoins[stablecoinId];
    }
}

// function setStablecoin(address stablecoinAddress) external onlyOwner {
//     bytes32 stablecoinId = keccak256(abi.encodePacked(IERC20Metadata(stablecoinAddress).symbol()));
//     s_stablecoins[stablecoinId] =
//         Stablecoin(stablecoinAddress, IERC20Metadata(stablecoinAddress).decimals(), stablecoinId);
//     emit StablecoinSet(stablecoinAddress, stablecoinId);
// } DECIMALS IN STRUCT TO NOT READ ALL THE TIME
// KECCAK256 OUTSIDE OF FUNCTION
// (bytes32 id, Stablecoin memory stablecoin)
