// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Vm} from "../../BaseTest.t.sol";

contract FulfillRequestTest is BaseTest {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    bytes32 public constant CLF_REQUEST_ERROR = keccak256("CLFRequestError(bytes32,bytes)");
    bytes32 public constant INVALID_CHAIN_SELECTOR = keccak256("InvalidChainSelector(bytes32,uint64)");
    bytes32 public constant INVALID_PROTOCOL_ENUM = keccak256("InvalidProtocolEnum(bytes32,uint8)");
    bytes32 public constant CLF_REQUEST_FULFILLED = keccak256("CLFRequestFulfilled(bytes32,uint64,uint8)");

    /*//////////////////////////////////////////////////////////////
                                 TESTS
    //////////////////////////////////////////////////////////////*/
    function test_yield_parentClf_fulfillRequest_error() public {
        /// @dev arrange
        bytes32 requestId = keccak256("requestId");
        bytes memory response = abi.encode(uint256(0), uint256(0));
        bytes memory err = abi.encode("error");

        vm.recordLogs();

        /// @dev act
        _fulfillRequest(requestId, response, err);

        /// @dev assert
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool foundError = false;

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == CLF_REQUEST_ERROR) {
                assertEq(logs[i].topics[1], requestId);
                bytes memory decodedErr = abi.decode(logs[i].data, (bytes));
                assertEq(decodedErr, err);
                foundError = true;
            }
        }
        assertTrue(foundError);
    }

    function test_yield_parentClf_fulfillRequest_invalidChainSelector() public {
        /// @dev arrange
        uint64 invalidChainSelector = 1;
        bytes32 requestId = keccak256("requestId");
        bytes memory response = abi.encode(uint256(invalidChainSelector), uint256(0));
        bytes memory err = "";

        vm.recordLogs();

        /// @dev act
        _fulfillRequest(requestId, response, err);

        /// @dev assert
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool foundInvalidChainSelector = false;

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == INVALID_CHAIN_SELECTOR) {
                assertEq(logs[i].topics[1], requestId);
                assertEq(logs[i].topics[2], bytes32(uint256(invalidChainSelector)));
                foundInvalidChainSelector = true;
            }
        }
        assertTrue(foundInvalidChainSelector);
    }

    function test_yield_parentClf_fulfillRequest_invalidProtocolEnum() public {
        /// @dev arrange
        uint8 invalidProtocolEnum = 2;
        bytes32 requestId = keccak256("requestId");
        bytes memory response = abi.encode(uint256(optChainSelector), uint256(invalidProtocolEnum));
        bytes memory err = "";

        vm.recordLogs();

        /// @dev act
        _fulfillRequest(requestId, response, err);

        /// @dev assert
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool foundInvalidProtocolEnum = false;

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == INVALID_PROTOCOL_ENUM) {
                assertEq(logs[i].topics[1], requestId);
                assertEq(logs[i].topics[2], bytes32(uint256(invalidProtocolEnum)));
                foundInvalidProtocolEnum = true;
            }
        }
        assertTrue(foundInvalidProtocolEnum);
    }

    function test_yield_parentClf_fulfillRequest_success() public {
        /// @dev arrange
        deal(address(baseUsdc), depositor, DEPOSIT_AMOUNT);
        _changePrank(depositor);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        bytes32 requestId = keccak256("requestId");
        bytes memory response = abi.encode(uint256(optChainSelector), uint256(0));
        bytes memory err = "";

        vm.recordLogs();

        /// @dev act
        _fulfillRequest(requestId, response, err);

        /// @dev assert
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool foundError = false;
        bool foundInvalidChainSelector = false;
        bool foundInvalidProtocolEnum = false;
        bool foundCLFRequestFulfilled = false;

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == CLF_REQUEST_ERROR) {
                foundError = true;
            }
            if (logs[i].topics[0] == INVALID_CHAIN_SELECTOR) {
                foundInvalidChainSelector = true;
            }
            if (logs[i].topics[0] == INVALID_PROTOCOL_ENUM) {
                foundInvalidProtocolEnum = true;
            }
            if (logs[i].topics[0] == CLF_REQUEST_FULFILLED) {
                assertEq(logs[i].topics[1], requestId);
                assertEq(logs[i].topics[2], bytes32(uint256(optChainSelector)));
                assertEq(logs[i].topics[3], bytes32(uint256(0)));
                foundCLFRequestFulfilled = true;
            }
        }
        assertFalse(foundError);
        assertFalse(foundInvalidChainSelector);
        assertFalse(foundInvalidProtocolEnum);
        assertTrue(foundCLFRequestFulfilled);
    }

    function test_yield_parentClf_fulfillRequest_success_noShares() public {
        /// @dev arrange
        bytes32 requestId = keccak256("requestId");
        bytes memory response = abi.encode(uint256(optChainSelector), uint256(0));
        bytes memory err = "";

        vm.recordLogs();

        /// @dev act
        _fulfillRequest(requestId, response, err);

        /// @dev assert
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bool foundError = false;
        bool foundInvalidChainSelector = false;
        bool foundInvalidProtocolEnum = false;
        bool foundCLFRequestFulfilled = false;

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == CLF_REQUEST_ERROR) {
                foundError = true;
            }
            if (logs[i].topics[0] == INVALID_CHAIN_SELECTOR) {
                foundInvalidChainSelector = true;
            }
            if (logs[i].topics[0] == INVALID_PROTOCOL_ENUM) {
                foundInvalidProtocolEnum = true;
            }
            if (logs[i].topics[0] == CLF_REQUEST_FULFILLED) {
                assertEq(logs[i].topics[1], requestId);
                assertEq(logs[i].topics[2], bytes32(uint256(optChainSelector)));
                assertEq(logs[i].topics[3], bytes32(uint256(0)));
                foundCLFRequestFulfilled = true;
            }
        }
        assertFalse(foundError);
        assertFalse(foundInvalidChainSelector);
        assertFalse(foundInvalidProtocolEnum);
        assertTrue(foundCLFRequestFulfilled);
    }
}
