// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IReceiver, IERC165} from "@chainlink/contracts/src/v0.8/keystone/interfaces/IReceiver.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title CREReceiver
/// @author George Gorzhiyev - Judge Finance
/// @dev Modified 'IReceiverTemplate' with security checks made mandatory
/// @dev From: https://docs.chain.link/cre/guides/workflow/using-evm-client/onchain-write/building-consumer-contracts#3-using-ireceivertemplate
/// @notice Abstract contract to get/verify/implement CRE reports from a Chainlink Keystone Forwarder
abstract contract CREReceiver is IReceiver, Ownable2Step {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error CREReceiver__InvalidKeystoneForwarder(address sender, address expectedForwarder);
    error CREReceiver__InvalidWorkflowDeployer(address receivedDeployer, address expectedDeployer);
    error CREReceiver__InvalidWorkflowName(bytes10 receivedName, bytes10 expectedName);
    error CREReceiver__InvalidWorkflowId(bytes32 receivedId, bytes32 expectedId);
    error CREReceiver__NotZeroAddress();
    error CREReceiver__NotEmptyName();
    error CREReceiver__NotZeroId();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev The Chainlink Keystone Forwarder contract address to receive CRE reports from
    address internal s_keystoneForwarder;
    /// @dev The expected CRE workflow deployer address
    address internal s_expectedWorkflowDeployer;
    /// @dev The expected CRE workflow name
    bytes10 internal s_expectedWorkflowName;
    /// @dev The expected CRE workflow Id
    bytes32 internal s_expectedWorkflowId;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a Keystone Forwarder address is set
    event KeystoneForwarderSet(address indexed);
    /// @notice Emitted when an expected workflow deployer address is set
    event ExpectedWorkflowDeployerSet(address indexed);
    /// @notice Emitted when an expected workflow name is set
    event ExpectedWorkflowNameSet(bytes10 indexed);
    /// @notice Emitted when an expected workflow Id is set
    event ExpectedWorkflowIdSet(bytes32 indexed);
    /// @notice Emitted when all security checks pass on 'onReport'
    /// @dev (Keystone Forwarder, Workflow Author, Workflow Id, Workflow Name)
    event OnReportSecurityChecksPassed(address indexed, address indexed, bytes32 indexed, bytes10);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Constructor sets msg.sender as the owner
    constructor() Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IReceiver
    /// @dev Performs all 4 validation checks
    /// @notice Called by a Chainlink Keystone Forwarder
    /// @param metadata Metadata about the report
    /// @param report The CRE report
    function onReport(bytes calldata metadata, bytes calldata report) external override {
        // Security Check 1: Verify caller is the trusted Chainlink Keystone Forwarder
        if (msg.sender != s_keystoneForwarder) {
            revert CREReceiver__InvalidKeystoneForwarder(msg.sender, s_keystoneForwarder);
        }

        // Security Checks 2-4: Verify workflow identity - ID, owner and name
        (bytes32 workflowId, bytes10 workflowName, address workflowDeployer) = _decodeMetadata(metadata);
        if (workflowId != s_expectedWorkflowId) {
            revert CREReceiver__InvalidWorkflowId(workflowId, s_expectedWorkflowId);
        }
        if (workflowDeployer != s_expectedWorkflowDeployer) {
            revert CREReceiver__InvalidWorkflowDeployer(workflowDeployer, s_expectedWorkflowDeployer);
        }
        if (workflowName != s_expectedWorkflowName) {
            revert CREReceiver__InvalidWorkflowName(workflowName, s_expectedWorkflowName);
        }

        /// @dev Emitted to assist in testing and verification of decoding workflow metadata
        emit OnReportSecurityChecksPassed(msg.sender, workflowDeployer, workflowId, workflowName);

        _processReport(report);
    }

    /// @inheritdoc IERC165
    /// @dev Implemented in order to receive CRE reports from Keystone Forwarder
    /// @param interfaceId The interface Id in bytes4
    /// @return If interface Id is supported
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Helper function to convert bytes to hex string
    /// @param data The bytes to convert
    /// @return The hex string representation
    function _bytesToHexString(bytes memory data) internal pure returns (bytes memory) {
        bytes memory hexChars = "0123456789abcdef";
        bytes memory hexString = new bytes(data.length * 2);

        for (uint256 i = 0; i < data.length; i++) {
            hexString[i * 2] = hexChars[uint8(data[i] >> 4)];
            hexString[i * 2 + 1] = hexChars[uint8(data[i] & 0x0f)];
        }

        return hexString;
    }

    /// @notice Extracts all metadata fields from the onReport metadata parameter
    /// @param metadata The metadata in bytes format
    /// @return workflowId The unique identifier of the workflow (bytes32)
    /// @return workflowName The name of the workflow (bytes10)
    /// @return workflowOwner The owner address of the workflow
    function _decodeMetadata(bytes memory metadata)
        internal
        pure
        returns (bytes32 workflowId, bytes10 workflowName, address workflowOwner)
    {
        // Metadata structure:
        // - First 32 bytes: length of the byte array (standard for dynamic bytes)
        // - Offset 32, size 32: workflow_id (bytes32)
        // - Offset 64, size 10: workflow_name (bytes10)
        // - Offset 74, size 20: workflow_owner (address)
        assembly {
            workflowId := mload(add(metadata, 32))
            workflowName := mload(add(metadata, 64))
            workflowOwner := shr(mul(12, 8), mload(add(metadata, 74)))
        }
    }

    /// @param report The report calldata containing your workflow's encoded data
    /// @dev Implement this function with your contract's business logic
    function _processReport(bytes calldata report) internal virtual;

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Updates the Chainlink Keystone Forwarder address that is allowed to call onReport
    /// @param keystoneForwarder The new forwader address
    function setKeystoneForwarderAddress(address keystoneForwarder) external onlyOwner {
        if (keystoneForwarder == address(0)) revert CREReceiver__NotZeroAddress();
        s_keystoneForwarder = keystoneForwarder;
        emit KeystoneForwarderSet(keystoneForwarder);
    }

    /// @notice Updates the expected workflow deployer address
    /// @param workflowDeployer The new expected workflow deployer address
    function setExpectedWorkflowDeployer(address workflowDeployer) external onlyOwner {
        if (workflowDeployer == address(0)) revert CREReceiver__NotZeroAddress();
        s_expectedWorkflowDeployer = workflowDeployer;
        emit ExpectedWorkflowDeployerSet(workflowDeployer);
    }

    /// @notice Updates the expected workflow name from a plaintext string
    /// @param workflowName The workflow name as a string
    /// @dev The name is hashed using SHA256 and truncated
    function setExpectedWorkflowName(string calldata workflowName) external onlyOwner {
        if (bytes(workflowName).length == 0) revert CREReceiver__NotEmptyName();

        // Convert workflow name to bytes10:
        // SHA256 hash → hex encode → take first 10 chars → hex encode those chars
        bytes32 hash = sha256(bytes(workflowName));
        bytes memory hexString = _bytesToHexString(abi.encodePacked(hash));
        bytes memory first10 = new bytes(10);
        for (uint256 i = 0; i < 10; i++) {
            first10[i] = hexString[i];
        }
        s_expectedWorkflowName = bytes10(first10);
        emit ExpectedWorkflowNameSet(bytes10(first10));
    }

    /// @notice Updates the expected workflow Id
    /// @param id The new expected workflow Id
    function setExpectedWorkflowId(bytes32 id) external onlyOwner {
        if (id == bytes32(0)) revert CREReceiver__NotZeroId();
        s_expectedWorkflowId = id;
        emit ExpectedWorkflowIdSet(id);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @return keystoneForwarder The Chainlink Keystone Forwarder address
    function getKeystoneForwarder() external view returns (address keystoneForwarder) {
        keystoneForwarder = s_keystoneForwarder;
    }

    /// @return workflowDeployer The expected CRE workflow deployer address
    function getExpectedWorkflowAuthor() external view returns (address workflowDeployer) {
        workflowDeployer = s_expectedWorkflowDeployer;
    }

    /// @return workflowName The expected CRE workflow name
    function getExpectedWorkflowName() external view returns (bytes10 workflowName) {
        workflowName = s_expectedWorkflowName;
    }

    /// @return workflowId The expected CRE workflow Id
    function getExpectedWorkflowId() external view returns (bytes32 workflowId) {
        workflowId = s_expectedWorkflowId;
    }
}
