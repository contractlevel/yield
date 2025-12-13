// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// deployed on eth sepolia: 0xad024a165c3c973ad74f8b038d386686ec534006
contract SimpleParentPeer {
    struct Strategy {
        bytes32 protocolId;
        uint64 chainSelector;
    }

    Strategy internal s_strategy;
    uint256 internal s_totalValue;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() {
        s_strategy = Strategy({protocolId: keccak256("aave-v3"), chainSelector: 14767482510784806043}); // fuji selector
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    function setTotalValue(uint256 totalValue) external {
        s_totalValue = totalValue;
    }

    function setStrategy(Strategy memory strategy) external {
        s_strategy = strategy;
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    function getStrategy() external view returns (Strategy memory) {
        return s_strategy;
    }

    function getTotalValue() external view returns (uint256) {
        return s_totalValue;
    }
    
}