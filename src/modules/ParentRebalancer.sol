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
    address internal s_forwarder;
    address internal s_parentPeer;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    function checkLog(Log calldata log, bytes memory)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        bytes32 eventSignature = keccak256("StrategyUpdated(uint64,uint8,uint64)");
        address parentPeer = s_parentPeer;
        uint64 thisChainSelector = IParentPeer(parentPeer).getThisChainSelector();

        if (log.source == parentPeer && log.topics[0] == eventSignature) {
            uint64 chainSelector = uint64(uint256(log.topics[1]));
            uint8 protocolEnum = uint8(uint256(log.topics[2]));
            uint64 oldChainSelector = uint64(uint256(log.topics[3]));

            if (chainSelector == thisChainSelector && oldChainSelector == thisChainSelector) {
                performData = "";
                upkeepNeeded = false;
            }

            IYieldPeer.Strategy memory strategy =
                IYieldPeer.Strategy({chainSelector: chainSelector, protocol: IYieldPeer.Protocol(protocolEnum)});
            IYieldPeer.CcipTxType txType;
            if (oldChainSelector == thisChainSelector && chainSelector != thisChainSelector) {
                txType = IYieldPeer.CcipTxType.RebalanceNewStrategy;
            } else {
                txType = IYieldPeer.CcipTxType.RebalanceOldStrategy;
            }

            performData = abi.encode(parentPeer, strategy, txType, oldChainSelector);
            upkeepNeeded = true;
        } else {
            performData = "";
            upkeepNeeded = false;
        }
    }

    function performUpkeep(bytes calldata performData) external {
        if (msg.sender != s_forwarder) revert ParentRebalancer__OnlyForwarder();

        (address parentPeer, IYieldPeer.Strategy memory strategy, IYieldPeer.CcipTxType txType, uint64 oldChainSelector)
        = abi.decode(performData, (address, IYieldPeer.Strategy, IYieldPeer.CcipTxType, uint64));

        if (txType == IYieldPeer.CcipTxType.RebalanceNewStrategy) {
            IParentPeer(parentPeer).rebalanceNewStrategy(strategy);
        } else {
            IParentPeer(parentPeer).rebalanceOldStrategy(oldChainSelector, strategy);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    function setForwarder(address forwarder) external onlyOwner {
        s_forwarder = forwarder;
    }
}
