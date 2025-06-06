// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.26;

// import {BaseTest} from "../../BaseTest.t.sol";

// contract SharePoolTest is BaseTest {
//     function test_yield_sharePool_onTokenTransfer_revertsWhen_notShare() public {
//         vm.expectRevert(abi.encodeWithSignature("SharePool__OnlyShare()"));
//         baseSharePool.onTokenTransfer(address(0), 100, abi.encode(1));
//     }
// }
