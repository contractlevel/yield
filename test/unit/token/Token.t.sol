// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest, Share} from "../../BaseTest.t.sol";
import {Client, IRouterClient} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IBurnMintERC677Upgradeable, IERC677, IERC20} from "src/token/interfaces/IBurnMintERC677Upgradeable.sol";
import {IGetCCIPAdmin} from "@chainlink/contracts/src/v0.8/ccip/interfaces/IGetCCIPAdmin.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// @review This test is a collection of assorted tests to fill in coverage gaps. Should this be broken up into other files?

contract TokenTest is BaseTest {
    uint256 internal constant APPROVE_AMOUNT = 1 ether;
    uint256 internal constant TRANSFER_AMOUNT = 1 ether;
    uint256 internal constant MINT_AMOUNT = 1 ether;
    uint256 internal constant BURN_AMOUNT = 1 ether;

    /*//////////////////////////////////////////////////////////////
                              NOT TO SELF
    //////////////////////////////////////////////////////////////*/
    function test_yield_token_mint_revertsWhen_mintToSelf() public {
        // Arrange
        uint256 mintAmount = 1 ether;
        _changePrank(baseShare.owner());
        baseShare.grantRole(baseShare.MINTER_ROLE(), baseShare.owner()); /// @dev Ensure we have minter role

        // Act & Assert
        vm.expectRevert(abi.encodeWithSelector(Share.Share__InvalidRecipient.selector, address(baseShare)));
        baseShare.mint(address(baseShare), mintAmount);
    }

    function test_yield_token_transfer_revertsWhen_transferToSelf() public {
        // Arrange
        deal(address(baseShare), holder, TRANSFER_AMOUNT);

        // Act & Assert
        vm.expectRevert(abi.encodeWithSelector(Share.Share__InvalidRecipient.selector, address(baseShare)));
        baseShare.transfer(address(baseShare), TRANSFER_AMOUNT);
    }

    function test_yield_token_approve_revertsWhen_approveToSelf() public {
        // Arrange
        _changePrank(holder);

        // Act & Assert
        vm.expectRevert(abi.encodeWithSelector(Share.Share__InvalidRecipient.selector, address(baseShare)));
        baseShare.approve(address(baseShare), APPROVE_AMOUNT);
    }

    /*//////////////////////////////////////////////////////////////
                               BURN LOGIC
    //////////////////////////////////////////////////////////////*/
    /// @dev Tests the "burn(account,amount)" older naming convention for BurnFrom
    function test_yield_token_burnLegacy_success() public {
        // Arrange
        address burner = makeAddr("burner");
        address victim = makeAddr("victim");

        /// @dev Setup tokens and role
        deal(address(baseShare), victim, BURN_AMOUNT);
        _changePrank(baseShare.owner());
        baseShare.grantRole(baseShare.BURNER_ROLE(), burner);

        /// @dev Victim approves burner
        _changePrank(victim);
        baseShare.approve(burner, BURN_AMOUNT);

        // Act
        /// @dev Burner calls the overloaded burn(address, uint256)
        _changePrank(burner);
        baseShare.burn(victim, BURN_AMOUNT);

        // Assert
        assertEq(baseShare.balanceOf(victim), 0);
        assertEq(baseShare.balanceOf(burner), 0);
    }

    /// @dev Tests the "burnFrom(account,amount)" override directly
    function test_yield_token_burnFrom_direct_success() public {
        // Arrange
        address burner = makeAddr("burner_direct");
        address victim = makeAddr("victim_direct");

        /// @dev Setup tokens and role
        deal(address(baseShare), victim, BURN_AMOUNT);
        _changePrank(baseShare.owner());
        baseShare.grantRole(baseShare.BURNER_ROLE(), burner);

        // Act
        /// @dev Victim approves burner
        _changePrank(victim);
        baseShare.approve(burner, BURN_AMOUNT);
        /// @dev Burner calls burnFrom DIRECTLY
        _changePrank(burner);
        baseShare.burnFrom(victim, BURN_AMOUNT);

        // Assertions
        assertEq(baseShare.balanceOf(victim), 0);
        assertEq(baseShare.balanceOf(burner), 0);
    }

    /*//////////////////////////////////////////////////////////////
                               ONLY PROXY
    //////////////////////////////////////////////////////////////*/
    /// @dev Tests the onlyProxy modifier on the transferAndCall public function
    function test_share_onlyProxy_revertsWhen_notProxy() public {
        // Arrange
        _selectFork(baseFork);

        // Cast the implementation address (stored in BaseTest) to Share type
        Share shareImpl = Share(baseShareImplAddr);

        // Act & Assert
        // The onlyProxy modifier reverts with UUPSUnauthorizedCallContext
        // if address(this) is the implementation address (not the proxy)
        vm.expectRevert(UUPSUpgradeable.UUPSUnauthorizedCallContext.selector);

        // Call transferAndCall directly on the implementation
        shareImpl.transferAndCall(holder, TRANSFER_AMOUNT, "");
    }

    /*//////////////////////////////////////////////////////////////
                           SUPPORTS INTERFACE
    //////////////////////////////////////////////////////////////*/
    function test_yield_token_supportsInterface() public view {
        // Arrange
        bytes4 wrongInterface = 0x12345678;

        // Act & Assert
        /// @dev Positive check
        assertTrue(baseShare.supportsInterface(type(IERC20).interfaceId));
        assertTrue(baseShare.supportsInterface(type(IBurnMintERC677Upgradeable).interfaceId));
        assertTrue(baseShare.supportsInterface(type(IERC677).interfaceId));
        assertTrue(baseShare.supportsInterface(type(IGetCCIPAdmin).interfaceId));
        assertTrue(baseShare.supportsInterface(type(IERC165).interfaceId));

        /// @dev Negative check
        assertFalse(baseShare.supportsInterface(wrongInterface));
    }

    /*//////////////////////////////////////////////////////////////
                                 ROLES
    //////////////////////////////////////////////////////////////*/
    /// @dev Tests the grantMintAndBurnRoles/getRoleMembers functions
    function test_yield_token_grantMintAndBurnRoles_success() public {
        // Arrange
        address burnAndMinter = makeAddr("burnAndMinter");
        bytes32 minterRole = baseShare.MINTER_ROLE();
        bytes32 burnerRole = baseShare.BURNER_ROLE();

        // Act
        _changePrank(baseShare.owner());
        baseShare.grantMintAndBurnRoles(burnAndMinter);
        /// @dev get minters and burners, cache last index
        address[] memory minters = baseShare.getRoleMembers(minterRole);
        address[] memory burners = baseShare.getRoleMembers(burnerRole);
        uint256 mintersLastIndex = minters.length - 1;
        uint256 burnersLastIndex = burners.length - 1;

        // Assert
        assertEq(minters[mintersLastIndex], burnAndMinter);
        assertEq(burners[burnersLastIndex], burnAndMinter);
    }

    /// @dev This is a sanity test to cover interal _revokeRole override
    function test_yield_token_revokeRoleRole_success() public {
        // Arrange
        address burner = makeAddr("burner");
        bytes32 burnerRole = baseShare.BURNER_ROLE();

        _changePrank(baseShare.owner());
        baseShare.grantRole(burnerRole, burner);
        address[] memory burnersBefore = baseShare.getRoleMembers(burnerRole);
        uint256 burnersLastIndex = burnersBefore.length - 1;
        /// @dev Verify burner in role members
        assertEq(burnersBefore[burnersLastIndex], burner);

        // Act
        baseShare.revokeRole(burnerRole, burner);
        address[] memory burnersAfter = baseShare.getRoleMembers(burnerRole);
        burnersLastIndex = burnersAfter.length - 1;

        // Assert
        assert(burnersAfter[burnersLastIndex] != burner);
    }

    /*//////////////////////////////////////////////////////////////
                               CCIP ADMIN
    //////////////////////////////////////////////////////////////*/
    /// @dev Tests setting and getting CCIP admin
    function test_yield_token_setCCIPAdmin() public {
        // Arrange
        _changePrank(baseShare.owner());
        address newAdmin = makeAddr("newAdmin");

        // Act
        baseShare.setCCIPAdmin(newAdmin);

        // Assert
        assertEq(baseShare.getCCIPAdmin(), newAdmin);
    }

    /*//////////////////////////////////////////////////////////////
                        CROSS CHAIN INTEGRATION
    //////////////////////////////////////////////////////////////*/
    function test_yield_token_crossChainTransfer() public {
        /// @dev arrange
        _selectFork(baseFork);
        deal(address(baseUsdc), holder, DEPOSIT_AMOUNT);
        _changePrank(holder);
        baseUsdc.approve(address(baseParentPeer), DEPOSIT_AMOUNT);
        baseParentPeer.deposit(DEPOSIT_AMOUNT);

        uint256 fee = _getFee(DEPOSIT_AMOUNT);
        uint256 userPrincipal = DEPOSIT_AMOUNT - fee;

        address link = baseParentPeer.getLink();
        address ccipRouter = baseNetworkConfig.ccip.ccipRouter;

        /// @dev sanity check
        uint256 tokenAmount = userPrincipal * INITIAL_SHARE_PRECISION;
        assertEq(baseShare.totalSupply(), tokenAmount);

        /// @dev build CCIP message
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: address(baseShare), amount: tokenAmount});
        baseShare.approve(ccipRouter, tokenAmount);

        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(address(holder)),
            data: "",
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.GenericExtraArgsV2({gasLimit: 1000000, allowOutOfOrderExecution: true})
            ),
            feeToken: link
        });

        uint256 ccipFees = IRouterClient(ccipRouter).getFee(optChainSelector, evm2AnyMessage);

        deal(link, holder, ccipFees);
        LinkTokenInterface(link).approve(ccipRouter, ccipFees);
        /// @dev act
        IRouterClient(ccipRouter).ccipSend(optChainSelector, evm2AnyMessage);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(optFork);

        /// @dev assert
        assertEq(optShare.balanceOf(holder), tokenAmount);
    }
}
