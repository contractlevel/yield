/// Verification of CREReceiver
/// @author George Gorzhiyev | Judge Finance
/// @notice CREReceiver is the abstract base contract for the Rebalancer

/*//////////////////////////////////////////////////////////////
                            METHODS
//////////////////////////////////////////////////////////////*/
methods {
    // CREReceiver methods
    function getKeystoneForwarder() external returns (address) envfree;
    function getWorkflow(bytes32) external returns (CREReceiver.Workflow memory) envfree;
    function owner() external returns (address) envfree;

    // Harness helper methods
    function createWorkflowReport(uint64, bytes32) external returns (bytes) envfree;
    function createWorkflowMetadata(bytes32, bytes10, address) external returns (bytes) envfree;
    function bytes32ToAddress(bytes32) external returns (address) envfree;
    function bytes32ToBytes10(bytes32) external returns (bytes10) envfree;
}

/*//////////////////////////////////////////////////////////////
                          DEFINITIONS
//////////////////////////////////////////////////////////////*/
// --- CREReceiver events --- //
definition OnReportSecurityChecksPassedEvent() returns bytes32 =
// keccak256(abi.encodePacked("OnReportSecurityChecksPassed(bytes32,address,bytes10)"))
to_bytes32(0x34e31b78708912bc5800a9d9027fd5088b0854d26f060d0ccc0fca8672c53b81);

definition KeystoneForwarderSetEvent() returns bytes32 =
// keccak256(abi.encodePacked("KeystoneForwarderSet(address)"))
to_bytes32(0x684a795bb89a06f40a343942b5ce820ac84ef62c2e1b030c5c8cc3ab7e09e64c);

definition WorkflowSetEvent() returns bytes32 =
// keccak256(abi.encodePacked("WorkflowSet(bytes32,address,bytes10)"))
to_bytes32(0x31239ecc9edbf46fa75a09048fdf9fc21aa17451fcfab56b6ce17f9aadad79f6);

definition WorkflowRemovedEvent() returns bytes32 =
// keccak256(abi.encodePacked("WorkflowRemoved(bytes32,address,bytes10)"))
to_bytes32(0xe98a46d5e955503e4ad1d22f0722714971ca87a1ad7c24e32a62ddc3000d6c55);

/*//////////////////////////////////////////////////////////////
                             GHOSTS
//////////////////////////////////////////////////////////////*/
// --- OnReportSecurityChecksPassed --- //
/// @notice EventCount: track amount OnReportSecurityChecksPassed event is emitted
/// @dev set to persistent as being havoced after onReport call
persistent ghost mathint ghost_onReportSecurityChecksPassed_eventCount {
    init_state axiom ghost_onReportSecurityChecksPassed_eventCount == 0;
}

/// @notice EmittedValue: track workflowId emitted in OnReportSecurityChecksPassed event
/// @dev set to persistent as being havoced after onReport call
persistent ghost bytes32 ghost_onReportSecurityChecksPassed_emittedWorkflowId {
    init_state axiom ghost_onReportSecurityChecksPassed_emittedWorkflowId == to_bytes32(0);
}

/// @notice EmittedValue: track workflowOwner emitted in OnReportSecurityChecksPassed event
/// @dev set to persistent as being havoced after onReport call
persistent ghost address ghost_onReportSecurityChecksPassed_emittedWorkflowOwner {
    init_state axiom ghost_onReportSecurityChecksPassed_emittedWorkflowOwner == 0x0;
}

/// @notice EmittedValue: track workflowName emitted in OnReportSecurityChecksPassed event
/// @dev set to persistent as being havoced after onReport call
persistent ghost bytes10 ghost_onReportSecurityChecksPassed_emittedWorkflowName {
    init_state axiom ghost_onReportSecurityChecksPassed_emittedWorkflowName == to_bytes10(0);
}

// --- KeystoneForwarderSet --- //
/// @notice EventCount: track amount KeystoneForwarderSet event is emitted
ghost mathint ghost_keystoneForwarderSet_eventCount {
    init_state axiom ghost_keystoneForwarderSet_eventCount == 0;
}

/// @notice EmittedValue: track address emitted in KeystoneForwarderSet event
ghost address ghost_keystoneForwarderSet_emittedAddress {
    init_state axiom ghost_keystoneForwarderSet_emittedAddress == 0;
}

// --- WorkflowSet --- //
/// @notice EventCount: track amount WorkflowSet event is emitted
ghost mathint ghost_workflowSet_eventCount {
    init_state axiom ghost_workflowSet_eventCount == 0;
}

/// @notice EmittedValue: track workflowId emitted in WorkflowSet event
ghost bytes32 ghost_workflowSet_emittedWorkflowId {
    init_state axiom ghost_workflowSet_emittedWorkflowId == to_bytes32(0);
}

/// @notice EmittedValue: track workflowOwner emitted in WorkflowSet event
ghost address ghost_workflowSet_emittedWorkflowOwner {
    init_state axiom ghost_workflowSet_emittedWorkflowOwner == 0x0;
}

/// @notice EmittedValue: track workflowName emitted in WorkflowSet event
ghost bytes10 ghost_workflowSet_emittedWorkflowName {
    init_state axiom ghost_workflowSet_emittedWorkflowName == to_bytes10(0);
}

// --- WorkflowRemoved --- //
/// @notice EventCount: track amount WorkflowRemoved event is emitted
ghost mathint ghost_WorkflowRemoved_eventCount {
    init_state axiom ghost_WorkflowRemoved_eventCount == 0;
}

/// @notice EmittedValue: track workflowId emitted in WorkflowRemoved event
ghost bytes32 ghost_WorkflowRemoved_emittedWorkflowId {
    init_state axiom ghost_WorkflowRemoved_emittedWorkflowId == to_bytes32(0);
}

/// @notice EmittedValue: track workflowOwner emitted in WorkflowRemoved event
ghost address ghost_WorkflowRemoved_emittedWorkflowOwner {
    init_state axiom ghost_WorkflowRemoved_emittedWorkflowOwner == 0x0;
}

/// @notice EmittedValue: track workflowName emitted in WorkflowRemoved event
ghost bytes10 ghost_WorkflowRemoved_emittedWorkflowName {
    init_state axiom ghost_WorkflowRemoved_emittedWorkflowName == to_bytes10(0);
}

/*//////////////////////////////////////////////////////////////
                             HOOKS
//////////////////////////////////////////////////////////////*/
/// @notice hook onto emitted events and update relevant ghosts
hook LOG4(uint offset, uint length, bytes32 t0, bytes32 t1, bytes32 t2, bytes32 t3) {
    if (t0 == OnReportSecurityChecksPassedEvent()) {
        ghost_onReportSecurityChecksPassed_eventCount = ghost_onReportSecurityChecksPassed_eventCount + 1;
        ghost_onReportSecurityChecksPassed_emittedWorkflowId = t1;
        ghost_onReportSecurityChecksPassed_emittedWorkflowOwner = bytes32ToAddress(t2);
        ghost_onReportSecurityChecksPassed_emittedWorkflowName = bytes32ToBytes10(t3);
    }
    if (t0 == WorkflowSetEvent()) {
        ghost_workflowSet_eventCount = ghost_workflowSet_eventCount + 1;
        ghost_workflowSet_emittedWorkflowId = t1;
        ghost_workflowSet_emittedWorkflowOwner = bytes32ToAddress(t2);
        ghost_workflowSet_emittedWorkflowName = bytes32ToBytes10(t3);
    }
    if (t0 == WorkflowRemovedEvent()) {
        ghost_WorkflowRemoved_eventCount = ghost_WorkflowRemoved_eventCount + 1;
        ghost_WorkflowRemoved_emittedWorkflowId = t1;
        ghost_WorkflowRemoved_emittedWorkflowOwner = bytes32ToAddress(t2);
        ghost_WorkflowRemoved_emittedWorkflowName = bytes32ToBytes10(t3);
    }
}

/// @notice hook onto emitted events and update relevant ghosts
hook LOG2(uint offset, uint length, bytes32 t0, bytes32 t1) {
    if (t0 == KeystoneForwarderSetEvent()) {
        ghost_keystoneForwarderSet_eventCount = ghost_keystoneForwarderSet_eventCount + 1;
        ghost_keystoneForwarderSet_emittedAddress = bytes32ToAddress(t1);
    }
}

/*//////////////////////////////////////////////////////////////
                             RULES
//////////////////////////////////////////////////////////////*/
// --- OnReport --- //
rule OnReport_decodes_reportMetadata() {
    env e;
    bytes report;
    bytes32 workflowId;
    address workflowOwner;
    bytes10 workflowName;

    require workflowId != to_bytes32(0), "workflowId should be non-zero";
    require workflowOwner != 0x0, "workflowOwner should be non-zero";
    require workflowName != to_bytes10(0), "workflowName should be non-zero";

    bytes metadata = createWorkflowMetadata(workflowId, workflowName, workflowOwner);

    require ghost_onReportSecurityChecksPassed_eventCount == 0, "event count should be zero at start";

    onReport(e, metadata, report);

    assert ghost_onReportSecurityChecksPassed_eventCount == 1;
    assert ghost_onReportSecurityChecksPassed_emittedWorkflowId == workflowId;
    assert ghost_onReportSecurityChecksPassed_emittedWorkflowOwner == workflowOwner;
    assert ghost_onReportSecurityChecksPassed_emittedWorkflowName == workflowName;
}

rule OnReport_revertsWhen_notKeystoneForwarder() {
    env e;
    calldataarg args;

    require e.msg.sender != getKeystoneForwarder(), "msg.sender should not be keystone forwarder";
    require e.msg.value == 0, "msg.value should be zero";

    onReport@withrevert(e, args);
    assert lastReverted;
}

rule OnReport_revertsWhen_zeroMetadata() {
    env e;
    bytes report;
    bytes32 workflowId;
    address workflowOwner;
    bytes10 workflowName;

    require workflowId == to_bytes32(0), "workflowId should be zero";
    require workflowOwner == 0x0, "workflowOwner should be zero address";
    require workflowName == to_bytes10(0), "workflowName should be zero";

    bytes metadata = createWorkflowMetadata(workflowId, workflowName, workflowOwner);

    require e.msg.sender == getKeystoneForwarder(), "msg.sender should be keystone forwarder";
    require e.msg.value == 0, "msg.value should be zero";

    onReport@withrevert(e, metadata, report);
    assert lastReverted;
}

rule OnReport_revertsWhen_zeroWorkflowId() {
    env e;
    bytes report;
    bytes32 workflowId;
    address workflowOwner;
    bytes10 workflowName;

    require workflowId == to_bytes32(0), "workflowId should be zero";
    require workflowOwner != 0x0, "workflowOwner should not be non-zero";
    require workflowName != to_bytes10(0), "workflowName should be non-zero";

    bytes metadata = createWorkflowMetadata(workflowId, workflowName, workflowOwner);

    require e.msg.sender == getKeystoneForwarder(), "msg.sender should be keystone forwarder";
    require e.msg.value == 0, "msg.value should be zero";

    onReport@withrevert(e, metadata, report);
    assert lastReverted;
}

rule OnReport_revertsWhen_zeroWorkflowOwner() {
    env e;
    bytes report;
    bytes32 workflowId;
    address workflowOwner;
    bytes10 workflowName;

    require workflowId != to_bytes32(0), "workflowId should be non-zero";
    require workflowOwner == 0x0, "workflowOwner should be zero address";
    require workflowName != to_bytes10(0), "workflowName should be non-zero";

    bytes metadata = createWorkflowMetadata(workflowId, workflowName, workflowOwner);

    require e.msg.sender == getKeystoneForwarder(), "msg.sender should be keystone forwarder";
    require e.msg.value == 0, "msg.value should be zero";

    onReport@withrevert(e, metadata, report);
    assert lastReverted;
}

rule OnReport_revertsWhen_zeroWorkflowName() {
    env e;
    bytes report;
    bytes32 workflowId;
    address workflowOwner;
    bytes10 workflowName;

    require workflowId != to_bytes32(0), "workflowId should be non-zero";
    require workflowOwner != 0x0, "workflowOwner should not be zero address";
    require workflowName == to_bytes10(0), "workflowName should be zero";

    bytes metadata = createWorkflowMetadata(workflowId, workflowName, workflowOwner);

    require e.msg.sender == getKeystoneForwarder(), "msg.sender should be keystone forwarder";
    require e.msg.value == 0, "msg.value should be zero";

    onReport@withrevert(e, metadata, report);
    assert lastReverted;
}

rule OnReport_revertsWhen_invalidWorkflowId() {
    env e;
    bytes report;

    // workflow metadata
    bytes32 workflowId;
    address workflowOwner;
    bytes10 workflowName;
    bytes32 invalidWorkflowId;

    require invalidWorkflowId != workflowId, "invalid workflow id should not be valid id";
    require currentContract.s_workflows[workflowId].owner == workflowOwner, "valid workflow owner should be in storage";
    require currentContract.s_workflows[workflowId].name == workflowName, "valid workflow name should be in storage";

    require e.msg.sender == getKeystoneForwarder(), "msg.sender should be keystone forwarder";
    require e.msg.value == 0, "msg.value should be zero";

    // metadata with invalid id
    bytes invalidMetadata = createWorkflowMetadata(invalidWorkflowId, workflowName, workflowOwner);

    onReport@withrevert(e, invalidMetadata, report);
    assert lastReverted;
}

rule OnReport_revertsWhen_invalidWorkflowOwner() {
    env e;
    bytes report;

    // workflow metadata
    bytes32 workflowId;
    address workflowOwner;
    bytes10 workflowName;
    address invalidWorkflowOwner;

    require invalidWorkflowOwner != workflowOwner, "invalid workflow owner should not be valid owner";
    require currentContract.s_workflows[workflowId].owner == workflowOwner, "valid workflow owner should be in storage";
    require currentContract.s_workflows[workflowId].name == workflowName, "valid workflow name should be in storage";

    require e.msg.sender == getKeystoneForwarder(), "msg.sender should be keystone forwarder";
    require e.msg.value == 0, "msg.value should be zero";

    // metadata with invalid owner
    bytes invalidMetadata = createWorkflowMetadata(workflowId, workflowName, invalidWorkflowOwner);

    onReport@withrevert(e, invalidMetadata, report);
    assert lastReverted;
}

rule OnReport_revertsWhen_invalidWorkflowName() {
    env e;
    bytes report;

    // workflow metadata
    bytes32 workflowId;
    address workflowOwner;
    bytes10 workflowName;
    bytes10 invalidWorkflowName;

    require invalidWorkflowName != workflowName, "invalid workflow name should not be valid name";
    require currentContract.s_workflows[workflowId].owner == workflowOwner, "valid workflow owner should be in storage";
    require currentContract.s_workflows[workflowId].name == workflowName, "valid workflow name should be in storage";

    require e.msg.sender == getKeystoneForwarder(), "msg.sender should be keystone forwarder";
    require e.msg.value == 0, "msg.value should be zero";

    // metadata with invalid name
    bytes invalidMetadata = createWorkflowMetadata(workflowId, invalidWorkflowName, workflowOwner);

    onReport@withrevert(e, invalidMetadata, report);
    assert lastReverted;
}

// --- Setters --- //
rule setKeystoneForwarder_revertsWhen_notOwner() {
    env e;
    calldataarg args;

    require e.msg.sender != owner(), "msg.sender should not be owner";

    setKeystoneForwarder@withrevert(e, args);
    assert lastReverted;
}

rule setKeystoneForwarder_revertsWhen_zeroAddress() {
    env e;
    address keystoneForwarder;

    require e.msg.sender == owner(), "msg.sender should be owner";
    require keystoneForwarder == 0x0, "keystoneForwarder should be zero address";

    setKeystoneForwarder@withrevert(e, keystoneForwarder);
    assert lastReverted;
}

rule setKeystoneForwarder_success() {
    env e;
    address keystoneForwarder;
    address returnedKeystoneForwarder;

    require ghost_keystoneForwarderSet_eventCount == 0, "event count should be zero at start";
    require ghost_keystoneForwarderSet_emittedAddress == 0x0, "emitted address at start should be zero address";

    setKeystoneForwarder(e, keystoneForwarder);

    assert ghost_keystoneForwarderSet_eventCount == 1;
    assert ghost_keystoneForwarderSet_emittedAddress == keystoneForwarder;
    assert(getKeystoneForwarder() == keystoneForwarder);
}

rule setWorkflow_revertsWhen_notOwner() {
    env e;
    calldataarg args;

    require e.msg.sender != owner(), "msg.sender should not be owner";
    require e.msg.value == 0, "msg.value should be zero";

    setWorkflow@withrevert(e, args);
    assert lastReverted;
}

rule setWorkflow_revertsWhen_workflowIdZero() {
    env e;
    bytes32 workflowId;
    address workflowOwner;
    bytes10 workflowName;

    require e.msg.value == 0, "msg.value should be zero";
    require e.msg.sender == owner(), "msg.sender should be owner";
    require workflowId == to_bytes32(0x0), "workflowId should be zero";
    require workflowOwner != 0x0, "workflowOwner should be non-zero";
    require workflowName != to_bytes10(0), "workflowName should be non-zero";

    setWorkflow@withrevert(e, workflowId, workflowOwner, workflowName);
    assert lastReverted;
}

rule setWorkflow_revertsWhen_workflowOwnerZero() {
    env e;
    bytes32 workflowId;
    address workflowOwner;
    bytes10 workflowName;

    require e.msg.value == 0, "msg.value should be zero";
    require e.msg.sender == owner(), "msg.sender should be owner";
    require workflowOwner == 0x0, "workflowOwner should be zero address";
    require workflowName != to_bytes10(0), "workflowName should be non-zero";
    require workflowId != to_bytes32(0), "workflowId should be non-zero";

    setWorkflow@withrevert(e, workflowId, workflowOwner, workflowName);
    assert lastReverted;
}

rule setWorkflow_revertsWhen_workflowNameZero() {
    env e;
    bytes32 workflowId;
    address workflowOwner;
    bytes10 workflowName;

    require workflowName == to_bytes10(0), "workflowName should be empty";
    require workflowOwner != 0x0, "workflowOwner should be non-zero";
    require workflowId != to_bytes32(0), "workflowId should be non-zero";

    require e.msg.value == 0, "msg.value should be zero";
    require e.msg.sender == owner(), "msg.sender should be owner";

    setWorkflow@withrevert(e, workflowId, workflowOwner, workflowName);
    assert lastReverted;
}

rule setWorkflow_emitsEvent() {
    env e;
    bytes32 workflowId;
    address workflowOwner;
    bytes10 workflowName;

    require ghost_workflowSet_eventCount == 0, "event count should be zero at start";

    setWorkflow(e, workflowId, workflowOwner, workflowName);

    assert ghost_workflowSet_eventCount == 1;
    assert ghost_workflowSet_emittedWorkflowId == workflowId;
    assert ghost_workflowSet_emittedWorkflowOwner == workflowOwner;
    assert ghost_workflowSet_emittedWorkflowName == workflowName;
}

rule setWorkflow_updatesStorage() {
    env e;
    bytes32 workflowId;
    address workflowOwner;
    bytes10 workflowName;

    setWorkflow(e, workflowId, workflowOwner, workflowName);

    CREReceiver.Workflow workflow = getWorkflow(workflowId);
    assert(workflow.owner == workflowOwner);
    assert(workflow.name == workflowName);
}

rule removeWorkflow_revertsWhen_notOwner() {
    env e;
    calldataarg args;

    require e.msg.sender != owner(), "msg.sender should not be owner";
    require e.msg.value == 0, "msg.value should be zero";

    removeWorkflow@withrevert(e, args);
    assert lastReverted;
}

rule removeWorkflow_success() {
    env e;
    bytes32 workflowId;
    address workflowOwner;
    bytes10 workflowName;

    require ghost_WorkflowRemoved_eventCount == 0, "event count should be zero at start";
    require currentContract.s_workflows[workflowId].owner == workflowOwner, "manually set owner";
    require currentContract.s_workflows[workflowId].name == workflowName, "manually set name";

    removeWorkflow(e, workflowId);

    CREReceiver.Workflow workflow = getWorkflow(workflowId); // check workflow state
    assert ghost_WorkflowRemoved_eventCount == 1;
    assert ghost_WorkflowRemoved_emittedWorkflowId == workflowId;
    assert ghost_WorkflowRemoved_emittedWorkflowOwner == workflowOwner;
    assert ghost_WorkflowRemoved_emittedWorkflowName == workflowName;
    assert(workflow.owner == 0x0);
    assert(workflow.name == to_bytes10(0));
}

// --- Getters --- //
rule getKeystoneForwarder_returns_address() {
    env e;
    address keystoneForwarder;
    address returnedKeystoneForwarder;

    setKeystoneForwarder(e, keystoneForwarder);
    returnedKeystoneForwarder = getKeystoneForwarder();

    assert(keystoneForwarder == returnedKeystoneForwarder);
}

rule getWorkflow_returns_workflow() {
    bytes32 workflowId;
    address workflowOwner;
    bytes10 workflowName;

    require currentContract.s_workflows[workflowId].owner == workflowOwner, "manually set owner";
    require currentContract.s_workflows[workflowId].name == workflowName, "manually set name";

    CREReceiver.Workflow workflow = getWorkflow(workflowId);

    assert(workflow.owner == workflowOwner);
    assert(workflow.name == workflowName);
}
