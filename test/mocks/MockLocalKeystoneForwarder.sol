// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IReceiver} from "lib/chainlink/contracts/src/v0.8/keystone/interfaces/IReceiver.sol";

contract MockLocalKeystoneForwarder {
    // send a report to receiver
    function report(address receiver, bytes calldata workflowMetadata, bytes calldata workflowReport) external {
        IReceiver(receiver).onReport(workflowMetadata, workflowReport);
    }
}
