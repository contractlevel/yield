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
    error CREReceiver__MetadataZero(bytes32 receivedId, address receivedOwner, bytes10 receivedName);
    error CREReceiver__InvalidKeystoneForwarder(address sender, address expectedForwarder);
    error CREReceiver__InvalidWorkflowId(bytes32 receivedId, address storedOwner, bytes10 storedName);
    error CREReceiver__InvalidWorkflowOwner(bytes32 receivedId, address receivedOwner);
    error CREReceiver__InvalidWorkflowName(bytes32 receivedId, bytes10 receivedName);
    error CREReceiver__ForwarderNotZero();
    error CREReceiver__IdNotZero();
    error CREReceiver__OwnerNotZero();
    error CREReceiver__NameNotZero();

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

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when all security checks pass on 'onReport'
    event OnReportSecurityChecksPassed(
        bytes32 indexed workflowId, address indexed workflowOwner, bytes10 indexed workflowName
    );
    /// @notice Emitted when a Keystone Forwarder address is set
    event KeystoneForwarderSet(address indexed keystoneForwarder);
    /// @notice Emitted when a workflow is set
    event WorkflowSet(bytes32 indexed workflowId, address indexed workflowOwner, bytes10 indexed workflowName);
    /// @notice Emitted when a workflow is removed
    event WorkflowRemoved(bytes32 indexed workflowId, address indexed workflowOwner, bytes10 indexed workflowName);

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
    function onReport(bytes calldata metadata, bytes calldata report) external {
        /// @dev  Security Check: Verify caller is the trusted Chainlink Keystone Forwarder
        address keystoneForwarder = s_keystoneForwarder;
        if (msg.sender != keystoneForwarder) {
            revert CREReceiver__InvalidKeystoneForwarder(msg.sender, keystoneForwarder);
        }

        // Decode metadata and verify not zero
        (bytes32 decodedId, bytes10 decodedName, address decodedOwner) = _decodeMetadata(metadata);

        if (decodedId == bytes32(0) || decodedName == bytes10(0) || decodedOwner == address(0)) {
            revert CREReceiver__MetadataZero(decodedId, decodedOwner, decodedName);
        }

        /// @dev Security Checks: ID, owner and name
        /// @dev workflow id is checked by inference with owner/name existing for an id
        address workflowOwner = s_workflows[decodedId].owner;
        bytes10 workflowName = s_workflows[decodedId].name;

        // Verify mapped workflow id exists
        if (workflowOwner == address(0) || workflowName == bytes10(0)) {
            revert CREReceiver__InvalidWorkflowId(decodedId, workflowOwner, workflowName);
        }

        // Verify owner and name match decoded metadata
        if (workflowOwner != decodedOwner) revert CREReceiver__InvalidWorkflowOwner(decodedId, decodedOwner);
        if (workflowName != decodedName) revert CREReceiver__InvalidWorkflowName(decodedId, decodedName);

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

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
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
        if (keystoneForwarder == address(0)) revert CREReceiver__ForwarderNotZero();
        s_keystoneForwarder = keystoneForwarder;
        emit KeystoneForwarderSet(keystoneForwarder);
    }

    /// @notice Sets a workflow in the allowed workflows mapping
    /// @param workflowId The id of the workflow
    /// @param workflowOwner The owner address of the workflow
    /// @param workflowName The name of the workflow
    /// @dev The workflow name is encoded according to CRE guidelines:
    /// @dev https://docs.chain.link/cre/guides/workflow/using-evm-client/onchain-write/building-consumer-contracts#how-workflow-names-are-encoded
    function setWorkflow(bytes32 workflowId, address workflowOwner, bytes10 workflowName) external onlyOwner {
        if (workflowId == bytes32(0)) revert CREReceiver__IdNotZero();
        if (workflowOwner == address(0)) revert CREReceiver__OwnerNotZero();
        if (workflowName == bytes10(0)) revert CREReceiver__NameNotZero();

        s_workflows[workflowId] = Workflow({owner: workflowOwner, name: workflowName});
        emit WorkflowSet(workflowId, workflowOwner, workflowName);
    }

    /// @notice Removes a workflow from the allowed workflows mapping
    /// @param workflowId The id of the workflow to remove
    function removeWorkflow(bytes32 workflowId) external onlyOwner {
        Workflow memory workflow = s_workflows[workflowId];
        delete s_workflows[workflowId];
        emit WorkflowRemoved(workflowId, workflow.owner, workflow.name);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @return keystoneForwarder The Chainlink Keystone Forwarder address
    function getKeystoneForwarder() external view returns (address keystoneForwarder) {
        keystoneForwarder = s_keystoneForwarder;
    }

    /// @param workflowId The workflow Id
    /// @return workflow The workflow - contains address owner and bytes10 name
    function getWorkflow(bytes32 workflowId) external view returns (Workflow memory workflow) {
        workflow = s_workflows[workflowId];
    }
}
