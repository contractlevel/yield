// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IParentPeer} from "../interfaces/IParentPeer.sol";
import {IYieldPeer} from "../interfaces/IYieldPeer.sol";
import {ILogAutomation, Log} from "@chainlink/contracts/src/v0.8/automation/interfaces/ILogAutomation.sol";
import {AutomationBase} from "@chainlink/contracts/src/v0.8/automation/AutomationBase.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @notice This contract is used to help the ParentPeer send CCIP rebalance messages.
/// This is needed because CLF runs out of gas when sending CCIP rebalance messages.
/// So we use this contract to automate the CCIP sends based on the CLF callback.
/// @notice This can't be an extension of the ParentPeer because the contract would be too big.
contract ParentRebalancer is AutomationBase, ILogAutomation, Ownable2Step {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ParentRebalancer__OnlyForwarder();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev Chainlink Automation forwarder
    address internal s_forwarder;
    /// @dev ParentPeer contract address
    address internal s_parentPeer;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the Chainlink Automation forwarder is set
    event ForwarderSet(address indexed forwarder);
    /// @notice Emitted when the ParentPeer contract address is set
    event ParentPeerSet(address indexed parentPeer);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Simulated offchain by Chainlink Automation nodes
    /// @notice Checks if the log is a StrategyUpdated event from the ParentPeer
    /// @notice If the emitted log is a StrategyUpdated event from ParentPeer, returns the performData to be used by the performUpkeep function
    /// @param log The log emitted by the ParentPeer
    /// @return upkeepNeeded Whether performUpkeep should be called by the Chainlink Automation forwarder
    /// @return performData The performData to be used by the performUpkeep function
    /// @notice The cannotExecute modifier will need to be commented out for some unit tests to pass
    function checkLog(Log calldata log, bytes memory)
        external
        view
        cannotExecute
        returns (bool upkeepNeeded, bytes memory performData)
    {
        bytes32 eventSignature = keccak256("StrategyUpdated(uint64,uint8,uint64)");
        address parentPeer = s_parentPeer;
        uint64 thisChainSelector = IParentPeer(parentPeer).getThisChainSelector();
        address forwarder = s_forwarder;

        if (log.source == parentPeer && log.topics[0] == eventSignature) {
            uint64 chainSelector = uint64(uint256(log.topics[1]));
            uint8 protocolEnum = uint8(uint256(log.topics[2]));
            uint64 oldChainSelector = uint64(uint256(log.topics[3]));

            if (chainSelector == thisChainSelector && oldChainSelector == thisChainSelector) {
                performData = "";
                upkeepNeeded = false;
                return (upkeepNeeded, performData);
            }

            IYieldPeer.Strategy memory newStrategy =
                IYieldPeer.Strategy({chainSelector: chainSelector, protocol: IYieldPeer.Protocol(protocolEnum)});
            IYieldPeer.CcipTxType txType;
            address oldStrategyPool = IYieldPeer(parentPeer).getStrategyPool();
            uint256 totalValue;

            if (oldChainSelector == thisChainSelector && chainSelector != thisChainSelector) {
                txType = IYieldPeer.CcipTxType.RebalanceNewStrategy;
                totalValue = IYieldPeer(parentPeer).getTotalValue();
            } else {
                txType = IYieldPeer.CcipTxType.RebalanceOldStrategy;
            }

            performData =
                abi.encode(forwarder, parentPeer, newStrategy, txType, oldChainSelector, oldStrategyPool, totalValue);
            upkeepNeeded = true;
        } else {
            performData = "";
            upkeepNeeded = false;
        }
    }

    /// @notice Called by the Chainlink Automation forwarder
    /// @notice Triggers CCIP rebalance messages from the ParentPeer
    /// @dev Revert if caller is not the Chainlink Automation forwarder
    /// @param performData The performData returned by the checkLog function
    function performUpkeep(bytes calldata performData) external {
        (
            address forwarder,
            address parentPeer,
            IYieldPeer.Strategy memory strategy,
            IYieldPeer.CcipTxType txType,
            uint64 oldChainSelector,
            address oldStrategyPool,
            uint256 totalValue
        ) = abi.decode(
            performData, (address, address, IYieldPeer.Strategy, IYieldPeer.CcipTxType, uint64, address, uint256)
        );

        if (msg.sender != forwarder) revert ParentRebalancer__OnlyForwarder();

        if (txType == IYieldPeer.CcipTxType.RebalanceNewStrategy) {
            IParentPeer(parentPeer).rebalanceNewStrategy(oldStrategyPool, totalValue, strategy);
        } else {
            IParentPeer(parentPeer).rebalanceOldStrategy(oldChainSelector, strategy);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the Chainlink Automation forwarder
    /// @param forwarder The address of the Chainlink Automation forwarder
    function setForwarder(address forwarder) external onlyOwner {
        s_forwarder = forwarder;
        emit ForwarderSet(forwarder);
    }

    /// @notice Sets the ParentPeer contract address
    /// @param parentPeer The address of the ParentPeer contract
    function setParentPeer(address parentPeer) external onlyOwner {
        s_parentPeer = parentPeer;
        emit ParentPeerSet(parentPeer);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the Chainlink Automation forwarder
    function getForwarder() external view returns (address) {
        return s_forwarder;
    }

    /// @notice Returns the ParentPeer contract address
    function getParentPeer() external view returns (address) {
        return s_parentPeer;
    }
}
