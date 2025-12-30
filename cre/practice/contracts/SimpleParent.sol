// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IReceiver, IERC165} from "@chainlink/contracts/src/v0.8/keystone/interfaces/IReceiver.sol";

/// @title SimpleParent
/// @author George Gorzhiyev
/// @notice A very simple Parent peer on Ethereum Sepolia
/// For practicing Chainlink CRE capability to Read & Write contract
/// YieldCoin protocol: https://github.com/contractlevel/yield
/// @dev deployed address: 0x660f8ab44263347c7704aDa8C016951ecf906A80
/// https://sepolia.etherscan.io/address/0x660f8ab44263347c7704aDa8C016951ecf906A80#code

contract SimpleParent is IReceiver {
    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    struct Strategy {
        bytes32 protocolId; // ie keccak256("aave-v3") or keccak256("compound-v3")
        uint64 chainSelector;
    }

    Strategy internal s_strategy;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event StrategyUpdated(uint64 indexed chainSelector, bytes32 indexed protocolId);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() {
        /// @dev Set an 'initial' strategy, 16015286601757825753 is Ethereum Sepolia Chain Id
        s_strategy = Strategy({chainSelector: 16015286601757825753, protocolId: keccak256("aave-v3")});
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    function onReport(
        bytes calldata,
        /*metadata*/
        bytes calldata report
    )
        external
    {
        /// @dev metadata ignored, no safety checks here - for simple testing!

        Strategy memory strategy = abi.decode(report, (Strategy));
        _setStrategy(strategy.chainSelector, strategy.protocolId);
    }

    function supportsInterface(bytes4 interfaceId) external pure virtual override returns (bool) {
        return interfaceId == type(IReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL / SETTER
    //////////////////////////////////////////////////////////////*/
    function _setStrategy(uint64 chainSelector, bytes32 protocolId) internal {
        s_strategy = Strategy({chainSelector: chainSelector, protocolId: protocolId});
        emit StrategyUpdated(chainSelector, protocolId);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    function getStrategy() external view returns (Strategy memory) {
        return s_strategy;
    }
}
