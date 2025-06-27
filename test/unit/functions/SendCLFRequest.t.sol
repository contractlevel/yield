// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm} from "../../BaseTest.t.sol";

contract SendCLFRequestTest is BaseTest {
    function test_yield_parentClf_sendCLFRequest_revertsWhen_notUpkeep() public {
        vm.expectRevert(abi.encodeWithSignature("ParentCLF__OnlyUpkeep()"));
        baseParentPeer.sendCLFRequest();
    }

    function test_yield_parentClf_sendCLFRequest_success() public {
        vm.recordLogs();

        _changePrank(upkeepAddress);
        baseParentPeer.sendCLFRequest();

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 requestId;
        bool found;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == keccak256(("RequestSent(bytes32)"))) {
                requestId = bytes32(logs[i].topics[1]);
                found = true;
                break;
            }
        }

        assertTrue(requestId != bytes32(0));
        assertTrue(found);
    }
}
