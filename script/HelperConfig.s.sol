// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {MockAavePool} from "../test/mocks/MockAavePool.sol";
import {MockComet} from "../test/mocks/MockComet.sol";
import {MockAToken} from "../test/mocks/MockAToken.sol";
import {MockPoolAddressesProvider} from "../test/mocks/MockPoolAddressesProvider.sol";
import {MockAToken} from "../test/mocks/MockAToken.sol";
import {MockUsdc} from "../test/mocks/MockUsdc.sol";
import {MockFunctionsRouter} from "../test/mocks/MockFunctionsRouter.sol";
import {CCIPLocalSimulator, LinkToken, IRouterClient} from "@chainlink-local/src/ccip/CCIPLocalSimulator.sol";
import {Share} from "../src/token/Share.sol";

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
        address tokenAdminRegistry;
        address registryModuleOwnerCustom;
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
    }

    struct NetworkConfig {
        CCIPConfig ccip;
        TokensConfig tokens;
        ProtocolsConfig protocols;
        CLFConfig clf;
    }

    NetworkConfig public activeNetworkConfig;

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
        else if (block.chainid == 84532) activeNetworkConfig = getBaseSepoliaConfig();
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
                cctpMessageTransmitter: 0x0a992d191DEeC32aFe36203Ad87D7d289a738F81,
                tokenAdminRegistry: 0xb22764f98dD05c789929716D677382Df22C05Cb6,
                registryModuleOwnerCustom: 0x4855174E9479E211337832E109E7721d43A4CA64
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
                clfSubId: 0 // @review dummy value
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
                cctpMessageTransmitter: 0x4D41f22c5a0e5c74090899E5a8Fb597a8842b3e8,
                tokenAdminRegistry: 0x657c42abE4CD8aa731Aec322f871B5b90cf6274F,
                registryModuleOwnerCustom: 0xAFEd606Bd2CAb6983fC6F10167c98aaC2173D77f
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
                clfSubId: 0 // @review dummy value
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
                cctpMessageTransmitter: 0xC30362313FBBA5cf9163F0bb16a0e01f01A896ca,
                tokenAdminRegistry: 0x39AE1032cF4B334a1Ed41cdD0833bdD7c7E7751E,
                registryModuleOwnerCustom: 0x1f1df9f7fc939E71819F766978d8F900B816761b
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
                clfSubId: 0 // @review dummy value
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
                cctpMessageTransmitter: 0xAD09780d193884d503182aD4588450C416D6F9D4,
                tokenAdminRegistry: 0x6f6C373d09C07425BaAE72317863d7F6bb731e37,
                registryModuleOwnerCustom: 0xAFEd606Bd2CAb6983fC6F10167c98aaC2173D77f
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
                clfSubId: 0 // @review dummy value
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
                cctpMessageTransmitter: address(0), // @review
                tokenAdminRegistry: 0x95F29FEE11c5C55d26cCcf1DB6772DE953B37B82,
                registryModuleOwnerCustom: 0x62e731218d0D47305aba2BE3751E7EE9E5520790
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
                clfSubId: 0 // @review dummy value
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
                cctpMessageTransmitter: 0x7865fAfC2db2093669d92c0F33AeEF291086BEFD,
                tokenAdminRegistry: 0x736D0bBb318c1B27Ff686cd19804094E66250e17,
                registryModuleOwnerCustom: 0x8A55C61227f26a3e2f217842eCF20b52007bAaBe
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
                clfSubId: 333
            })
        });
    }

    /*//////////////////////////////////////////////////////////////
                                 LOCAL
    //////////////////////////////////////////////////////////////*/
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        MockUsdc usdc = new MockUsdc();
        MockAavePool aavePool = new MockAavePool(address(usdc)); // need to set aToken address later
        MockAToken aToken = new MockAToken(address(aavePool));
        MockPoolAddressesProvider poolAddressesProvider = new MockPoolAddressesProvider(address(aavePool));
        aavePool.setATokenAddress(address(aToken));
        MockComet comet = new MockComet();
        MockFunctionsRouter functionsRouter = new MockFunctionsRouter();

        CCIPLocalSimulator ccipLocalSimulator = new CCIPLocalSimulator();
        (, IRouterClient ccipRouter,,, LinkToken link,,) = ccipLocalSimulator.configuration();

        Share share = new Share();
        ccipLocalSimulator.supportNewTokenViaOwner(address(usdc));
        ccipLocalSimulator.supportNewTokenViaGetCCIPAdmin(address(share));

        return NetworkConfig({
            ccip: CCIPConfig({
                ccipRouter: address(ccipRouter),
                thisChainSelector: 0, // @review dummy value
                parentChainSelector: 0, // set these with separate values
                rmnProxy: 0x411dE17f12D1A34ecC7F45f49844626267c75e81,
                usdcTokenPool: address(0), // @review
                cctpMessageTransmitter: address(0), // @review
                tokenAdminRegistry: address(0), // @review
                registryModuleOwnerCustom: address(0) // @review
            }),
            tokens: TokensConfig({link: address(link), usdc: address(usdc), share: address(share)}),
            protocols: ProtocolsConfig({aavePoolAddressesProvider: address(poolAddressesProvider), comet: address(comet)}),
            clf: CLFConfig({
                functionsRouter: address(functionsRouter),
                donId: "",
                clfSubId: 0 // @review dummy value
            })
        });
    }
}
