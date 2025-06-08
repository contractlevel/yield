// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, Vm, console2, ParentCLF, ChildPeer, IERC20, Share} from "../BaseTest.t.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Handler is Test {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    ParentCLF internal parent;
    ChildPeer internal child1;
    ChildPeer internal child2;
    Share internal share;
    address internal ccipRouter;
    IERC20 internal usdc;

    /*//////////////////////////////////////////////////////////////
                                 GHOSTS
    //////////////////////////////////////////////////////////////*/
    uint256 internal ghost_totalSharesMinted;
    uint256 internal ghost_totalSharesBurned;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        ParentCLF _parent,
        ChildPeer _child1,
        ChildPeer _child2,
        Share _share,
        address _ccipRouter,
        address _usdc
    ) {
        parent = _parent;
        child1 = _child1;
        child2 = _child2;
        share = _share;
        ccipRouter = _ccipRouter;
        usdc = IERC20(_usdc);
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    function deposit() public {}

    function withdraw() public {}
}
