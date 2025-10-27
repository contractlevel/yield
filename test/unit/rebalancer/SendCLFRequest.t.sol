// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm, Roles} from "../../BaseTest.t.sol";

contract SendCLFRequestTest is BaseTest {
    function test_yield_rebalancer_sendCLFRequest_revertsWhen_notUpkeep() public {
        vm.expectRevert(abi.encodeWithSignature("Rebalancer__OnlyUpkeep()"));
        baseRebalancer.sendCLFRequest();
    }

    function test_yield_rebalancer_sendCLFRequest_revertsWhen_rebalancerPaused() public {
        _changePrank(emergency_pauser);
        baseRebalancer.emergencyPause();
        /// @dev try to send CLFRequest as upkeepAddress and expect pause revert
        _changePrank(upkeepAddress);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        baseRebalancer.sendCLFRequest();
    }

    function test_yield_rebalancer_sendCLFRequest_success() public {
        vm.recordLogs();

        _changePrank(upkeepAddress);
        baseRebalancer.sendCLFRequest();

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

    function test_yield_rebalancer_getUpkeepAddress() public view {
        assertEq(baseRebalancer.getUpkeepAddress(), address(upkeepAddress));
    }
}
