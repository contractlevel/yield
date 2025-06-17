// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ParentCLF} from "./ParentCLF.sol";
import {ILogAutomation, Log} from "@chainlink/contracts/src/v0.8/automation/interfaces/ILogAutomation.sol";
import {AutomationBase} from "@chainlink/contracts/src/v0.8/automation/AutomationBase.sol";

contract ParentCLA is ParentCLF, AutomationBase, ILogAutomation {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    address internal s_forwarder;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address ccipRouter,
        address link,
        uint64 thisChainSelector,
        address usdc,
        address aavePoolAddressesProvider,
        address comet,
        address share,
        address functionsRouter,
        bytes32 donId,
        uint64 clfSubId
    )
        ParentCLF(
            ccipRouter,
            link,
            thisChainSelector,
            usdc,
            aavePoolAddressesProvider,
            comet,
            share,
            functionsRouter,
            donId,
            clfSubId
        )
    {}

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    function checkLog(Log calldata log, bytes memory)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // @review: this is not the correct event signature, oldChainSelector is not included
        bytes32 eventSignature = keccak256("StrategyUpdated(uint64,uint8,uint64)");

        if (log.source == address(this) && log.topics[0] == eventSignature) {
            uint64 chainSelector = uint64(uint256(log.topics[1]));
            uint8 protocolEnum = uint8(uint256(log.topics[2]));
            uint64 oldChainSelector = uint64(uint256(log.topics[3]));

            if (chainSelector == i_thisChainSelector) {
                performData = "";
                upkeepNeeded = false;
            }

            Strategy memory strategy = Strategy({chainSelector: chainSelector, protocol: Protocol(protocolEnum)});
            CcipTxType txType;
            if (oldChainSelector == i_thisChainSelector && chainSelector != i_thisChainSelector) {
                txType = CcipTxType.RebalanceNewStrategy;
            } else {
                txType = CcipTxType.RebalanceOldStrategy;
            }

            performData = abi.encode(strategy, txType, oldChainSelector);
            upkeepNeeded = true;
        } else {
            performData = "";
            upkeepNeeded = false;
        }
    }

    function performUpkeep(bytes calldata performData) external {
        (Strategy memory strategy, CcipTxType txType, uint64 oldChainSelector) =
            abi.decode(performData, (Strategy, CcipTxType, uint64));

        /// @notice oldProtocolEnum is meaningless here
        Strategy memory oldStrategy = Strategy({chainSelector: oldChainSelector, protocol: Protocol(0)});

        if (txType == CcipTxType.RebalanceNewStrategy) {
            _handleStrategyMoveToNewChain(strategy);
        } else {
            _handleRebalanceFromDifferentChain(oldStrategy, strategy);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    function setForwarder(address forwarder) external onlyOwner {
        s_forwarder = forwarder;
    }
}
