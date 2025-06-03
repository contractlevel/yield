// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    /*//////////////////////////////////////////////////////////////
                             NETWORK CONFIG
    //////////////////////////////////////////////////////////////*/
    struct NetworkConfig {
        address ccipRouter;
        address link;
        uint64 thisChainSelector;
        address usdc;
        address aavePoolAddressesProvider;
        address comet;
        address share;
        uint64 parentChainSelector;
        address rmnProxy;
        address usdcTokenPool;
        address cctpMessageTransmitter;
    }

    NetworkConfig public activeNetworkConfig;

    uint64 public constant MAINNET_PARENT_CHAIN_SELECTOR = 4949039107694359620; // arbitrum
    uint64 public constant TESTNET_PARENT_CHAIN_SELECTOR = 20; // update this

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() {
        if (block.chainid == 1) activeNetworkConfig = getEthMainnetConfig();
        else if (block.chainid == 10) activeNetworkConfig = getOptimismConfig();
        else if (block.chainid == 42161) activeNetworkConfig = getArbitrumConfig();
        else if (block.chainid == 11155111) activeNetworkConfig = getEthSepoliaConfig();
        else activeNetworkConfig = getOrCreateAnvilEthConfig();
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    /*//////////////////////////////////////////////////////////////
                                MAINNETS
    //////////////////////////////////////////////////////////////*/
    function getEthMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            ccipRouter: 0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D,
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            thisChainSelector: 5009297550715157269,
            usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            aavePoolAddressesProvider: 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e,
            comet: 0xc3d688B66703497DAA19211EEdff47f25384cdc3,
            share: address(0), // needs to be deployed
            parentChainSelector: MAINNET_PARENT_CHAIN_SELECTOR,
            rmnProxy: 0x411dE17f12D1A34ecC7F45f49844626267c75e81,
            usdcTokenPool: 0xc2e3A3C18ccb634622B57fF119a1C8C7f12e8C0c,
            cctpMessageTransmitter: 0x0a992d191DEeC32aFe36203Ad87D7d289a738F81
        });
    }

    function getOptimismConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            ccipRouter: 0x3206695CaE29952f4b0c22a169725a865bc8Ce0f,
            link: 0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6,
            thisChainSelector: 3734403246176062136,
            usdc: 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85,
            aavePoolAddressesProvider: 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb,
            comet: 0x2e44e174f7D53F0212823acC11C01A11d58c5bCB,
            share: address(0), // needs to be deployed
            parentChainSelector: MAINNET_PARENT_CHAIN_SELECTOR,
            rmnProxy: 0x55b3FCa23EdDd28b1f5B4a3C7975f63EFd2d06CE,
            usdcTokenPool: 0x5931822f394baBC2AACF4588E98FC77a9f5aa8C9,
            cctpMessageTransmitter: 0x4D41f22c5a0e5c74090899E5a8Fb597a8842b3e8
        });
    }

    function getArbitrumConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            ccipRouter: 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8,
            link: 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4,
            thisChainSelector: 4949039107694359620,
            usdc: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
            aavePoolAddressesProvider: 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb,
            comet: 0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf,
            share: address(0), // needs to be deployed
            parentChainSelector: MAINNET_PARENT_CHAIN_SELECTOR,
            rmnProxy: 0xC311a21e6fEf769344EB1515588B9d535662a145,
            usdcTokenPool: 0x9fCd83bC7F67ADa1fB51a4caBEa333c72B641bd1,
            cctpMessageTransmitter: 0xC30362313FBBA5cf9163F0bb16a0e01f01A896ca
        });
    }

    /*//////////////////////////////////////////////////////////////
                                TESTNETS
    //////////////////////////////////////////////////////////////*/
    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            // DUMMY VALUES
            ccipRouter: 0x794a61358D6845594F94dc1DB02A252b5b4814aD,
            link: 0x404460C6A5EdE2D891e8297795264fDe62ADBB75,
            thisChainSelector: 10,
            usdc: 0x7F5c764cBc14f9669B88837ca1490cCa17c31607,
            aavePoolAddressesProvider: 0x794a61358D6845594F94dc1DB02A252b5b4814aD,
            comet: 0x794a61358D6845594F94dc1DB02A252b5b4814aD,
            share: 0x794a61358D6845594F94dc1DB02A252b5b4814aD,
            parentChainSelector: TESTNET_PARENT_CHAIN_SELECTOR,
            rmnProxy: 0x411dE17f12D1A34ecC7F45f49844626267c75e81,
            usdcTokenPool: address(0), // @review
            cctpMessageTransmitter: address(0) // @review
        });
    }

    /*//////////////////////////////////////////////////////////////
                                 LOCAL
    //////////////////////////////////////////////////////////////*/
    function getOrCreateAnvilEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            // DUMMY VALUES
            ccipRouter: 0x794a61358D6845594F94dc1DB02A252b5b4814aD,
            link: 0x404460C6A5EdE2D891e8297795264fDe62ADBB75,
            thisChainSelector: 10, // @review dummy value
            usdc: 0x7F5c764cBc14f9669B88837ca1490cCa17c31607,
            aavePoolAddressesProvider: 0x794a61358D6845594F94dc1DB02A252b5b4814aD,
            comet: 0x794a61358D6845594F94dc1DB02A252b5b4814aD,
            share: 0x794a61358D6845594F94dc1DB02A252b5b4814aD,
            parentChainSelector: MAINNET_PARENT_CHAIN_SELECTOR,
            rmnProxy: 0x411dE17f12D1A34ecC7F45f49844626267c75e81,
            usdcTokenPool: address(0), // @review
            cctpMessageTransmitter: address(0) // @review
        });
    }
}
