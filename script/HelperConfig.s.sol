// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    /*//////////////////////////////////////////////////////////////
                             NETWORK CONFIG
    //////////////////////////////////////////////////////////////*/
    struct CCIPConfig {
        address ccipRouter;
        uint64 thisChainSelector;
        uint64 parentChainSelector;
        address rmnProxy;
        address usdcTokenPool;
        address cctpMessageTransmitter;
    }

    struct TokensConfig {
        address link;
        address usdc;
        address share;
    }

    struct ProtocolsConfig {
        address aavePoolAddressesProvider;
        address comet;
    }

    struct CLFConfig {
        address functionsRouter;
        bytes32 donId;
        uint64 clfSubId;
        bytes encryptedSecret;
    }

    struct NetworkConfig {
        CCIPConfig ccip;
        TokensConfig tokens;
        ProtocolsConfig protocols;
        CLFConfig clf;
    }

    NetworkConfig public activeNetworkConfig;

    // uint64 public constant MAINNET_PARENT_CHAIN_SELECTOR = 4949039107694359620; // arbitrum
    uint64 public constant MAINNET_PARENT_CHAIN_SELECTOR = 15971525489660198786; // base
    uint64 public constant TESTNET_PARENT_CHAIN_SELECTOR = 20; // update this

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() {
        if (block.chainid == 1) activeNetworkConfig = getEthMainnetConfig();
        else if (block.chainid == 10) activeNetworkConfig = getOptimismConfig();
        else if (block.chainid == 42161) activeNetworkConfig = getArbitrumConfig();
        else if (block.chainid == 8453) activeNetworkConfig = getBaseConfig();
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
            ccip: CCIPConfig({
                ccipRouter: 0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D,
                thisChainSelector: 5009297550715157269,
                parentChainSelector: MAINNET_PARENT_CHAIN_SELECTOR,
                rmnProxy: 0x411dE17f12D1A34ecC7F45f49844626267c75e81,
                usdcTokenPool: 0xc2e3A3C18ccb634622B57fF119a1C8C7f12e8C0c,
                cctpMessageTransmitter: 0x0a992d191DEeC32aFe36203Ad87D7d289a738F81
            }),
            tokens: TokensConfig({
                link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
                usdc: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                share: address(0) // needs to be deployed
            }),
            protocols: ProtocolsConfig({
                aavePoolAddressesProvider: 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e,
                comet: 0xc3d688B66703497DAA19211EEdff47f25384cdc3
            }),
            clf: CLFConfig({
                functionsRouter: 0x65Dcc24F8ff9e51F10DCc7Ed1e4e2A61e6E14bd6,
                donId: 0x66756e2d657468657265756d2d6d61696e6e65742d3100000000000000000000,
                clfSubId: 0, // @review dummy value
                encryptedSecret: ""
            })
        });
    }

    function getOptimismConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            ccip: CCIPConfig({
                ccipRouter: 0x3206695CaE29952f4b0c22a169725a865bc8Ce0f,
                thisChainSelector: 3734403246176062136,
                parentChainSelector: MAINNET_PARENT_CHAIN_SELECTOR,
                rmnProxy: 0x55b3FCa23EdDd28b1f5B4a3C7975f63EFd2d06CE,
                usdcTokenPool: 0x5931822f394baBC2AACF4588E98FC77a9f5aa8C9,
                cctpMessageTransmitter: 0x4D41f22c5a0e5c74090899E5a8Fb597a8842b3e8
            }),
            tokens: TokensConfig({
                link: 0x350a791Bfc2C21F9Ed5d10980Dad2e2638ffa7f6,
                usdc: 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85,
                share: address(0) // needs to be deployed
            }),
            protocols: ProtocolsConfig({
                aavePoolAddressesProvider: 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb,
                comet: 0x2e44e174f7D53F0212823acC11C01A11d58c5bCB
            }),
            clf: CLFConfig({
                functionsRouter: 0xaA8AaA682C9eF150C0C8E96a8D60945BCB21faad,
                donId: 0x66756e2d6f7074696d69736d2d6d61696e6e65742d310a000000000000000000,
                clfSubId: 0, // @review dummy value
                encryptedSecret: ""
            })
        });
    }

    function getArbitrumConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            ccip: CCIPConfig({
                ccipRouter: 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8,
                thisChainSelector: 4949039107694359620,
                parentChainSelector: MAINNET_PARENT_CHAIN_SELECTOR,
                rmnProxy: 0xC311a21e6fEf769344EB1515588B9d535662a145,
                usdcTokenPool: 0x9fCd83bC7F67ADa1fB51a4caBEa333c72B641bd1,
                cctpMessageTransmitter: 0xC30362313FBBA5cf9163F0bb16a0e01f01A896ca
            }),
            tokens: TokensConfig({
                link: 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4,
                usdc: 0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
                share: address(0) // needs to be deployed
            }),
            protocols: ProtocolsConfig({
                aavePoolAddressesProvider: 0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb,
                comet: 0x9c4ec768c28520B50860ea7a15bd7213a9fF58bf
            }),
            clf: CLFConfig({
                functionsRouter: 0x97083E831F8F0638855e2A515c90EdCF158DF238,
                donId: 0x66756e2d617262697472756d2d6d61696e6e65742d3100000000000000000000,
                clfSubId: 0, // @review dummy value
                encryptedSecret: ""
            })
        });
    }

    function getBaseConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            ccip: CCIPConfig({
                ccipRouter: 0x881e3A65B4d4a04dD529061dd0071cf975F58bCD,
                thisChainSelector: 15971525489660198786,
                parentChainSelector: MAINNET_PARENT_CHAIN_SELECTOR,
                rmnProxy: 0xC842c69d54F83170C42C4d556B4F6B2ca53Dd3E8,
                usdcTokenPool: 0x5931822f394baBC2AACF4588E98FC77a9f5aa8C9,
                cctpMessageTransmitter: 0xAD09780d193884d503182aD4588450C416D6F9D4
            }),
            tokens: TokensConfig({
                link: 0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196,
                usdc: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
                share: address(0) // needs to be deployed
            }),
            protocols: ProtocolsConfig({
                aavePoolAddressesProvider: 0xe20fCBdBfFC4Dd138cE8b2E6FBb6CB49777ad64D,
                comet: 0xb125E6687d4313864e53df431d5425969c15Eb2F
            }),
            clf: CLFConfig({
                functionsRouter: 0xf9B8fc078197181C841c296C876945aaa425B278,
                donId: 0x66756e2d626173652d6d61696e6e65742d310000000000000000000000000000,
                clfSubId: 0, // @review dummy value
                encryptedSecret: ""
            })
        });
    }

    /*//////////////////////////////////////////////////////////////
                                TESTNETS
    //////////////////////////////////////////////////////////////*/
    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            ccip: CCIPConfig({
                ccipRouter: 0x794a61358D6845594F94dc1DB02A252b5b4814aD,
                thisChainSelector: 10,
                parentChainSelector: TESTNET_PARENT_CHAIN_SELECTOR,
                rmnProxy: 0x411dE17f12D1A34ecC7F45f49844626267c75e81,
                usdcTokenPool: address(0), // @review
                cctpMessageTransmitter: address(0) // @review
            }),
            tokens: TokensConfig({
                link: 0x404460C6A5EdE2D891e8297795264fDe62ADBB75,
                usdc: 0x7F5c764cBc14f9669B88837ca1490cCa17c31607,
                share: 0x794a61358D6845594F94dc1DB02A252b5b4814aD
            }),
            protocols: ProtocolsConfig({
                aavePoolAddressesProvider: 0x794a61358D6845594F94dc1DB02A252b5b4814aD,
                comet: 0x794a61358D6845594F94dc1DB02A252b5b4814aD
            }),
            clf: CLFConfig({
                functionsRouter: 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0,
                donId: 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000,
                clfSubId: 0, // @review dummy value
                encryptedSecret: ""
            })
        });
    }

    function getBaseSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            ccip: CCIPConfig({
                ccipRouter: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
                thisChainSelector: 10344971235874465080,
                parentChainSelector: 10344971235874465080,
                rmnProxy: 0x99360767a4705f68CcCb9533195B761648d6d807,
                usdcTokenPool: 0x5931822f394baBC2AACF4588E98FC77a9f5aa8C9,
                cctpMessageTransmitter: 0x7865fAfC2db2093669d92c0F33AeEF291086BEFD
            }),
            tokens: TokensConfig({
                link: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410,
                usdc: 0x036CbD53842c5426634e7929541eC2318f3dCF7e,
                share: address(0) // needs to be deployed
            }),
            protocols: ProtocolsConfig({
                aavePoolAddressesProvider: address(0),
                comet: 0x571621Ce60Cebb0c1D442B5afb38B1663C6Bf017
            }),
            clf: CLFConfig({
                functionsRouter: 0xf9B8fc078197181C841c296C876945aaa425B278,
                donId: 0x66756e2d626173652d7365706f6c69612d310000000000000000000000000000,
                clfSubId: 333,
                encryptedSecret: "0xed68cd6fa80efc88a377b9a7c00a11fd0305cba98d104f23153e6a829637653f123555bbf3f9e4654f87f2d74f95163ffb153a856288472008ae2d37c8f5f878f31dc3dae151646a79e5c7a7cbec82900231eb08906849fd81deef3300259edddb62817452e51f650152c27a648669c8414eb714b6c39cdb1c118e776bac29c6e0ca4ac90884c0119a43cbda28e024b15f2a1835ae59ea003ed3426d403a5dfa4b16707d3846a2e6085e03161a4d07640ae17f9485f8c72a8b8170169b2d14bba5f9cf0705986023811f7e6ee9f7025f8668b91f64829b5e587c681a252ae0ae8f"
            })
        });
    }

    /*//////////////////////////////////////////////////////////////
                                 LOCAL
    //////////////////////////////////////////////////////////////*/
    function getOrCreateAnvilEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            ccip: CCIPConfig({
                ccipRouter: 0x794a61358D6845594F94dc1DB02A252b5b4814aD,
                thisChainSelector: 10, // @review dummy value
                parentChainSelector: MAINNET_PARENT_CHAIN_SELECTOR,
                rmnProxy: 0x411dE17f12D1A34ecC7F45f49844626267c75e81,
                usdcTokenPool: address(0), // @review
                cctpMessageTransmitter: address(0) // @review
            }),
            tokens: TokensConfig({
                link: 0x404460C6A5EdE2D891e8297795264fDe62ADBB75,
                usdc: 0x7F5c764cBc14f9669B88837ca1490cCa17c31607,
                share: 0x794a61358D6845594F94dc1DB02A252b5b4814aD
            }),
            protocols: ProtocolsConfig({
                aavePoolAddressesProvider: 0x794a61358D6845594F94dc1DB02A252b5b4814aD,
                comet: 0x794a61358D6845594F94dc1DB02A252b5b4814aD
            }),
            clf: CLFConfig({
                functionsRouter: address(0),
                donId: "",
                clfSubId: 0, // @review dummy value
                encryptedSecret: ""
            })
        });
    }
}
