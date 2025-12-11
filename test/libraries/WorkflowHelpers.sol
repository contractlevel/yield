// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IYieldPeer} from "../../src/interfaces/IYieldPeer.sol";

/// @dev Library containing helper functions for CRE workflow testing
library WorkflowHelpers {
    /*//////////////////////////////////////////////////////////////
                            WORKFLOW HELPERS
    //////////////////////////////////////////////////////////////*/
    /// @notice Helper function to create a Keystone workflow report
    /// @param chainSelector The chain selector of the strategy
    /// @param protocolId The protocol ID of the strategy
    /// @return workflowReport The Keystone workflow report
    function _createWorkflowReport(uint64 chainSelector, bytes32 protocolId)
        internal
        pure
        returns (bytes memory workflowReport)
    {
        IYieldPeer.Strategy memory strategy =
            IYieldPeer.Strategy({chainSelector: chainSelector, protocolId: protocolId});

        workflowReport = abi.encode(strategy);
    }

    /// @notice Helper function create Keystone workflow metadata
    /// @param wfId The ID of the workflow
    /// @param wfName The name of the workflow
    /// @param wfOwner The owner of the workflow
    /// @return workflowMetadata The Keystone workflow metadata
    function _createWorkflowMetadata(bytes32 wfId, bytes10 wfName, address wfOwner)
        internal
        pure
        returns (bytes memory workflowMetadata)
    {
        workflowMetadata = abi.encodePacked(wfId, wfName, wfOwner);
    }

    /// @notice Helper function to create CRE encoded workflow name
    /// @dev SEE URL
    /// URL: https://docs.chain.link/cre/guides/workflow/using-evm-client/onchain-write/building-consumer-contracts#how-workflow-names-are-encoded
    /// @param rawName The raw string name of the workflow
    function _createWorkflowName(string memory rawName) internal pure returns (bytes10 encodedName) {
        // Convert workflow name to bytes10:
        // SHA256 hash → hex encode → take first 10 chars → hex encode those chars
        bytes32 hash = sha256(bytes(rawName));
        bytes memory hexString = _bytesToHexString(abi.encodePacked(hash));
        bytes memory first10 = new bytes(10);
        for (uint256 i = 0; i < 10; i++) {
            first10[i] = hexString[i];
        }
        encodedName = bytes10(first10);
    }

    /// @dev Helper function for '_createWorkflowName'
    /// @param data The bytes data to convert to a hex string
    function _bytesToHexString(bytes memory data) private pure returns (bytes memory) {
        bytes memory hexChars = "0123456789abcdef";
        bytes memory hexString = new bytes(data.length * 2);

        for (uint256 i = 0; i < data.length; i++) {
            hexString[i * 2] = hexChars[uint8(data[i] >> 4)];
            hexString[i * 2 + 1] = hexChars[uint8(data[i] & 0x0f)];
        }

        return hexString;
    }
}
