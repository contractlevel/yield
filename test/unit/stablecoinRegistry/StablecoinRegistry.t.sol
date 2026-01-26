// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {StablecoinRegistry} from "../../../src/modules/StablecoinRegistry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract StablecoinRegistryTest is Test {
    StablecoinRegistry public registry;
    address public owner;
    address public notOwner;

    bytes32 public constant USDC_ID = keccak256("USDC");
    bytes32 public constant USDT_ID = keccak256("USDT");
    bytes32 public constant GHO_ID = keccak256("GHO");

    address public constant USDC_ADDRESS = address(0x1);
    address public constant USDT_ADDRESS = address(0x2);
    address public constant GHO_ADDRESS = address(0x3);

    event StablecoinSet(bytes32 indexed stablecoinId, address indexed stablecoin);

    function setUp() public {
        owner = makeAddr("owner");
        notOwner = makeAddr("notOwner");

        vm.prank(owner);
        registry = new StablecoinRegistry();
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    function test_yield_stablecoinRegistry_constructor_setsOwner() public view {
        assertEq(registry.owner(), owner);
    }

    /*//////////////////////////////////////////////////////////////
                            SET STABLECOIN
    //////////////////////////////////////////////////////////////*/
    function test_yield_stablecoinRegistry_setStablecoin_revertsWhen_notOwner() public {
        vm.prank(notOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, notOwner));
        registry.setStablecoin(USDC_ID, USDC_ADDRESS);
    }

    function test_yield_stablecoinRegistry_setStablecoin_success() public {
        vm.prank(owner);
        registry.setStablecoin(USDC_ID, USDC_ADDRESS);

        assertEq(registry.getStablecoin(USDC_ID), USDC_ADDRESS);
    }

    function test_yield_stablecoinRegistry_setStablecoin_emitsEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, false);
        emit StablecoinSet(USDC_ID, USDC_ADDRESS);
        registry.setStablecoin(USDC_ID, USDC_ADDRESS);
    }

    function test_yield_stablecoinRegistry_setStablecoin_canUpdateExisting() public {
        vm.startPrank(owner);
        registry.setStablecoin(USDC_ID, USDC_ADDRESS);
        assertEq(registry.getStablecoin(USDC_ID), USDC_ADDRESS);

        address newAddress = address(0x999);
        registry.setStablecoin(USDC_ID, newAddress);
        assertEq(registry.getStablecoin(USDC_ID), newAddress);
        vm.stopPrank();
    }

    function test_yield_stablecoinRegistry_setStablecoin_canDeregister() public {
        vm.startPrank(owner);
        registry.setStablecoin(USDC_ID, USDC_ADDRESS);
        assertTrue(registry.isStablecoinSupported(USDC_ID));

        registry.setStablecoin(USDC_ID, address(0));
        assertFalse(registry.isStablecoinSupported(USDC_ID));
        vm.stopPrank();
    }

    function test_yield_stablecoinRegistry_setStablecoin_multipleStablecoins() public {
        vm.startPrank(owner);
        registry.setStablecoin(USDC_ID, USDC_ADDRESS);
        registry.setStablecoin(USDT_ID, USDT_ADDRESS);
        registry.setStablecoin(GHO_ID, GHO_ADDRESS);

        assertEq(registry.getStablecoin(USDC_ID), USDC_ADDRESS);
        assertEq(registry.getStablecoin(USDT_ID), USDT_ADDRESS);
        assertEq(registry.getStablecoin(GHO_ID), GHO_ADDRESS);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            GET STABLECOIN
    //////////////////////////////////////////////////////////////*/
    function test_yield_stablecoinRegistry_getStablecoin_returnsZeroWhen_notSet() public view {
        assertEq(registry.getStablecoin(USDC_ID), address(0));
    }

    function test_yield_stablecoinRegistry_getStablecoin_returnsCorrectAddress() public {
        vm.prank(owner);
        registry.setStablecoin(USDC_ID, USDC_ADDRESS);

        assertEq(registry.getStablecoin(USDC_ID), USDC_ADDRESS);
    }

    /*//////////////////////////////////////////////////////////////
                        IS STABLECOIN SUPPORTED
    //////////////////////////////////////////////////////////////*/
    function test_yield_stablecoinRegistry_isStablecoinSupported_returnsFalseWhen_notSet() public view {
        assertFalse(registry.isStablecoinSupported(USDC_ID));
    }

    function test_yield_stablecoinRegistry_isStablecoinSupported_returnsTrueWhen_set() public {
        vm.prank(owner);
        registry.setStablecoin(USDC_ID, USDC_ADDRESS);

        assertTrue(registry.isStablecoinSupported(USDC_ID));
    }

    function test_yield_stablecoinRegistry_isStablecoinSupported_returnsFalseWhen_deregistered() public {
        vm.startPrank(owner);
        registry.setStablecoin(USDC_ID, USDC_ADDRESS);
        assertTrue(registry.isStablecoinSupported(USDC_ID));

        registry.setStablecoin(USDC_ID, address(0));
        assertFalse(registry.isStablecoinSupported(USDC_ID));
        vm.stopPrank();
    }
}
