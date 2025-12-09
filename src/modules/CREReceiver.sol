// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IReceiver, IERC165} from "@chainlink/contracts/src/v0.8/keystone/interfaces/IReceiver.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title CREReceiver
/// @author George Gorzhiyev - Judge Finance
/// @dev Modified 'IReceiverTemplate' with security checks made mandatory
/// @dev From: https://docs.chain.link/cre/guides/workflow/using-evm-client/onchain-write/building-consumer-contracts#3-using-ireceivertemplate
/// @notice Abstract contract to get/verify/consume CRE reports from a Chainlink Keystone Forwarder
abstract contract CREReceiver is IReceiver, Ownable2Step {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error CREReceiver__InvalidKeystoneForwarder(address sender, address expectedForwarder);
    error CREReceiver__InvalidWorkflow(bytes32 receivedId, address receivedOwner, bytes10 receivedName);
    error CREReceiver__NotZeroAddress();
    error CREReceiver__NotEmptyName();
    error CREReceiver__NotZeroId();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev Holds a workflow owner/name and mapped to a workflow id
    struct Workflow {
        address owner;
        bytes10 name;
    }

    /// @dev Mapping workflow ids to owner/name
    mapping(bytes32 workflowId => Workflow) internal s_workflows;

    /// @dev The Chainlink Keystone Forwarder contract address to receive CRE reports from
    address internal s_keystoneForwarder;
    /// @dev The expected CRE workflow owner address
    address internal s_expectedWorkflowOwner;
    /// @dev The expected CRE workflow name
    bytes10 internal s_expectedWorkflowName;
    /// @dev The expected CRE workflow Id
    bytes32 internal s_expectedWorkflowId;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a Keystone Forwarder address is set
    event KeystoneForwarderSet(address indexed keystoneForwarder);
    /// @notice Emitted when a workflow is set
    event WorkflowSet(bytes32 indexed workflowId, address indexed workflowOwner, bytes10 indexed workflowName);
    /// @notice Emitted when a workflow is removed
    event WorkflowRemoved(bytes32 indexed workflowId, address indexed workflowOwner, bytes10 indexed workflowName);
    /// @notice Emitted when all security checks pass on 'onReport'
    event OnReportSecurityChecksPassed(
        bytes32 indexed workflowId, address indexed workflowOwner, bytes10 indexed workflowName
    );

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
        address keystoneForwarder = s_keystoneForwarder;
        if (msg.sender != keystoneForwarder) {
            revert CREReceiver__InvalidKeystoneForwarder(msg.sender, keystoneForwarder);
        }

        // Security Checks 2-4: Verify workflow identity - ID, owner and name
        /// @dev workflow id is checked by inference with owner/name existing for an id
        (bytes32 decodedId, bytes10 decodedName, address decodedOwner) = _decodeMetadata(metadata);

        address workflowOwner = s_workflows[decodedId].owner;
        bytes10 workflowName = s_workflows[decodedId].name;

        if (workflowOwner != decodedOwner || workflowName != decodedName) {
            revert CREReceiver__InvalidWorkflow(decodedId, decodedOwner, decodedName);
        }

        /// @dev Emitted to assist in testing and verification of decoding workflow metadata
        emit OnReportSecurityChecksPassed(decodedId, decodedOwner, decodedName);
        _onReport(report);
    }

    /// @inheritdoc IERC165
    /// @dev Implemented in order to receive CRE reports from Keystone Forwarder
    /// @param interfaceId The interface Id in bytes4
    /// @return If interface Id is supported
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /// @notice Removes a workflow from the allowed workflows mapping
    /// @param workflowId The id of the workflow to remove
    function removeWorkflow(bytes32 workflowId) external onlyOwner {
        address workflowOwner = s_workflows[workflowId].owner;
        bytes10 workflowName = s_workflows[workflowId].name;
        // @review Better to use &&? || in the edge chance one field is
        // set and the other is not but not sure that will happen
        if (workflowOwner != address(0) || workflowName != bytes10(0)) {
            delete s_workflows[workflowId];
            emit WorkflowRemoved(workflowId, workflowOwner, workflowName);
        } else {
            revert CREReceiver__InvalidWorkflow(workflowId, workflowOwner, workflowName);
        }
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
    function _onReport(bytes calldata report) internal virtual;

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Updates the Chainlink Keystone Forwarder address that is allowed to call onReport
    /// @param keystoneForwarder The new forwader address
    function setKeystoneForwarder(address keystoneForwarder) external onlyOwner {
        if (keystoneForwarder == address(0)) revert CREReceiver__NotZeroAddress();
        s_keystoneForwarder = keystoneForwarder;
        emit KeystoneForwarderSet(keystoneForwarder);
    }

    /// @notice Sets a workflow in the allowed workflows mapping
    /// @param workflowId The id of the workflow
    /// @param workflowOwner The owner address of the workflow
    /// @param workflowName The name of the workflow
    function setWorkflow(bytes32 workflowId, address workflowOwner, string calldata workflowName) external onlyOwner {
        if (workflowId == bytes32(0)) revert CREReceiver__NotZeroId();
        if (workflowOwner == address(0)) revert CREReceiver__NotZeroAddress();
        if (bytes(workflowName).length == 0) revert CREReceiver__NotEmptyName();

        /// @dev Following method from IReceiverTemplate to encode name for CRE guidelines
        /// URL: https://docs.chain.link/cre/guides/workflow/using-evm-client/onchain-write/building-consumer-contracts#how-workflow-names-are-encoded
        // Convert workflow name to bytes10:
        // SHA256 hash → hex encode → take first 10 chars → hex encode those chars
        bytes32 hash = sha256(bytes(workflowName));
        bytes memory hexString = _bytesToHexString(abi.encodePacked(hash));
        bytes memory encodedName = new bytes(10);
        for (uint256 i = 0; i < 10; i++) {
            encodedName[i] = hexString[i];
        }

        s_workflows[workflowId] = Workflow({owner: workflowOwner, name: bytes10(encodedName)});
        emit WorkflowSet(workflowId, workflowOwner, bytes10(encodedName));
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @return keystoneForwarder The Chainlink Keystone Forwarder address
    function getKeystoneForwarder() external view returns (address keystoneForwarder) {
        keystoneForwarder = s_keystoneForwarder;
    }

    /// @return wfId The workflow Id
    /// @return wfOwner The CRE workflow owner address
    /// @return wfName The CRE workflow name
    function getWorkflow(bytes32 workflowId) external view returns (bytes32 wfId, address wfOwner, bytes10 wfName) {
        wfId = workflowId;
        wfOwner = s_workflows[workflowId].owner;
        wfName = s_workflows[workflowId].name;
    }

    /// @return workflowOwner The CRE workflow owner address
    function getWorkflowOwner(bytes32 workflowId) external view returns (address workflowOwner) {
        workflowOwner = s_workflows[workflowId].owner;
    }

    /// @return workflowName The CRE workflow name
    function getWorkflowName(bytes32 workflowId) external view returns (bytes10 workflowName) {
        workflowName = s_workflows[workflowId].name;
    }
}
