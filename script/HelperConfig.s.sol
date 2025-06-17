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
        PeersConfig peers;
    }

    struct PeersConfig {
        address localPeer;
        uint64 localChainSelector;
        address[] remotePeers;
        uint64[] remoteChainSelectors;
        address localSharePool;
        address[] remoteSharePools;
        address localShare;
        address[] remoteShares;
        address parentRebalancer;
    }

    NetworkConfig public activeNetworkConfig;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint64 public constant MAINNET_PARENT_CHAIN_SELECTOR = 15971525489660198786; // base
    uint64 public constant TESTNET_PARENT_CHAIN_SELECTOR = 14767482510784806043; // avalanche fuji

    uint64 public constant AVALANCHE_FUJI_CHAIN_SELECTOR = 14767482510784806043;
    uint64 public constant BASE_SEPOLIA_CHAIN_SELECTOR = 10344971235874465080;
    uint64 public constant ETH_SEPOLIA_CHAIN_SELECTOR = 16015286601757825753;

    address public constant AVALANCHE_FUJI_PEER = 0xc19688E191dEB933B99cc78D94c227784c8062F9;
    address public constant AVALANCHE_FUJI_SHARE_TOKEN = 0x2891C37D5104446d10dc29eA06c25C6f0cA233Ec;
    address public constant AVALANCHE_FUJI_SHARE_POOL = 0x9bf12E915461A48bc61ddca5f295A0E20BBBa5D7;

    address public constant ETH_SEPOLIA_PEER = 0xBE679979Eaec355d1030d6f117Ce5B4b5388318E;
    address public constant ETH_SEPOLIA_SHARE_TOKEN = 0x37D13c62D2FDe4A400e2018f2fA0e3da6b15718D;
    address public constant ETH_SEPOLIA_SHARE_POOL = 0x9CF6491ace3FDD614FB8209ec98dcF98b1e70e4D;

    address public constant BASE_SEPOLIA_PEER = 0x94563Bfe55D8Df522FE94e7D60D2D949ef21BF1c;
    address public constant BASE_SEPOLIA_SHARE_TOKEN = 0x2DF8c615858B479cBC3Bfef3bBfE34842d7AaA90;
    address public constant BASE_SEPOLIA_SHARE_POOL = 0xEF13904800eFA60BB1ea5f70645Fc55609F00320;

    /*//////////////////////////////////////////////////////////////
                                 ARRAYS
    //////////////////////////////////////////////////////////////*/
    address[] public remotePeers = new address[](2);
    uint64[] public remoteChainSelectors = new uint64[](2);
    address[] public remoteSharePools = new address[](2);
    address[] public remoteShares = new address[](2);

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
        else if (block.chainid == 43113) activeNetworkConfig = getAvalancheFujiConfig();
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
                clfSubId: 0 // dummy value
            }),
            peers: PeersConfig({
                localPeer: 0x0000000000000000000000000000000000000000,
                localChainSelector: 0,
                remotePeers: new address[](0),
                remoteChainSelectors: new uint64[](0),
                localSharePool: 0x0000000000000000000000000000000000000000,
                remoteSharePools: new address[](0),
                localShare: 0x0000000000000000000000000000000000000000,
                remoteShares: new address[](0),
                parentRebalancer: 0x0000000000000000000000000000000000000000
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
                clfSubId: 0 // dummy value
            }),
            peers: PeersConfig({
                localPeer: 0x0000000000000000000000000000000000000000,
                localChainSelector: 0,
                remotePeers: new address[](0),
                remoteChainSelectors: new uint64[](0),
                localSharePool: 0x0000000000000000000000000000000000000000,
                remoteSharePools: new address[](0),
                localShare: 0x0000000000000000000000000000000000000000,
                remoteShares: new address[](0),
                parentRebalancer: 0x0000000000000000000000000000000000000000
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
            }),
            peers: PeersConfig({
                localPeer: 0x0000000000000000000000000000000000000000,
                localChainSelector: 0,
                remotePeers: new address[](0),
                remoteChainSelectors: new uint64[](0),
                localSharePool: 0x0000000000000000000000000000000000000000,
                remoteSharePools: new address[](0),
                localShare: 0x0000000000000000000000000000000000000000,
                remoteShares: new address[](0),
                parentRebalancer: 0x0000000000000000000000000000000000000000
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
            }),
            peers: PeersConfig({
                localPeer: 0x0000000000000000000000000000000000000000,
                localChainSelector: 0,
                remotePeers: new address[](0),
                remoteChainSelectors: new uint64[](0),
                localSharePool: 0x0000000000000000000000000000000000000000,
                remoteSharePools: new address[](0),
                localShare: 0x0000000000000000000000000000000000000000,
                remoteShares: new address[](0),
                parentRebalancer: 0x0000000000000000000000000000000000000000
            })
        });
    }

    /*//////////////////////////////////////////////////////////////
                                TESTNETS
    //////////////////////////////////////////////////////////////*/
    function getEthSepoliaConfig() public returns (NetworkConfig memory) {
        remotePeers[0] = BASE_SEPOLIA_PEER;
        remotePeers[1] = AVALANCHE_FUJI_PEER;

        remoteChainSelectors[0] = BASE_SEPOLIA_CHAIN_SELECTOR;
        remoteChainSelectors[1] = AVALANCHE_FUJI_CHAIN_SELECTOR;

        remoteSharePools[0] = BASE_SEPOLIA_SHARE_POOL;
        remoteSharePools[1] = AVALANCHE_FUJI_SHARE_POOL;

        remoteShares[0] = BASE_SEPOLIA_SHARE_TOKEN;
        remoteShares[1] = AVALANCHE_FUJI_SHARE_TOKEN;

        return NetworkConfig({
            ccip: CCIPConfig({
                ccipRouter: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59,
                thisChainSelector: 16015286601757825753,
                parentChainSelector: ETH_SEPOLIA_CHAIN_SELECTOR,
                rmnProxy: 0xba3f6251de62dED61Ff98590cB2fDf6871FbB991,
                usdcTokenPool: 0xAff3fE524ea94118EF09DaDBE3c77ba6AA0005EC,
                cctpMessageTransmitter: 0x7865fAfC2db2093669d92c0F33AeEF291086BEFD,
                tokenAdminRegistry: 0x95F29FEE11c5C55d26cCcf1DB6772DE953B37B82,
                registryModuleOwnerCustom: 0x62e731218d0D47305aba2BE3751E7EE9E5520790
            }),
            tokens: TokensConfig({
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                usdc: 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238,
                share: ETH_SEPOLIA_SHARE_TOKEN
            }),
            protocols: ProtocolsConfig({
                aavePoolAddressesProvider: 0xf7869E9D4227c53AbCD5b4964fC7f502C2FC7A58,
                comet: 0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e
            }),
            clf: CLFConfig({
                functionsRouter: 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0,
                donId: 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000,
                clfSubId: 5026
            }),
            peers: PeersConfig({
                localPeer: ETH_SEPOLIA_PEER,
                localChainSelector: ETH_SEPOLIA_CHAIN_SELECTOR,
                remotePeers: remotePeers,
                remoteChainSelectors: remoteChainSelectors,
                localSharePool: ETH_SEPOLIA_SHARE_POOL,
                remoteSharePools: remoteSharePools,
                localShare: ETH_SEPOLIA_SHARE_TOKEN,
                remoteShares: remoteShares,
                parentRebalancer: 0x107C9A78c447c99289B84476f53620236114AbAa
            })
        });
    }

    function getBaseSepoliaConfig() public returns (NetworkConfig memory) {
        remotePeers[0] = ETH_SEPOLIA_PEER;
        remotePeers[1] = AVALANCHE_FUJI_PEER;

        remoteChainSelectors[0] = ETH_SEPOLIA_CHAIN_SELECTOR;
        remoteChainSelectors[1] = AVALANCHE_FUJI_CHAIN_SELECTOR;

        remoteSharePools[0] = ETH_SEPOLIA_SHARE_POOL;
        remoteSharePools[1] = AVALANCHE_FUJI_SHARE_POOL;

        remoteShares[0] = ETH_SEPOLIA_SHARE_TOKEN;
        remoteShares[1] = AVALANCHE_FUJI_SHARE_TOKEN;

        return NetworkConfig({
            ccip: CCIPConfig({
                ccipRouter: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
                thisChainSelector: 10344971235874465080,
                parentChainSelector: ETH_SEPOLIA_CHAIN_SELECTOR,
                rmnProxy: 0x99360767a4705f68CcCb9533195B761648d6d807,
                usdcTokenPool: 0x5931822f394baBC2AACF4588E98FC77a9f5aa8C9,
                cctpMessageTransmitter: 0x7865fAfC2db2093669d92c0F33AeEF291086BEFD,
                tokenAdminRegistry: 0x736D0bBb318c1B27Ff686cd19804094E66250e17,
                registryModuleOwnerCustom: 0x8A55C61227f26a3e2f217842eCF20b52007bAaBe
            }),
            tokens: TokensConfig({
                link: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410,
                usdc: 0x036CbD53842c5426634e7929541eC2318f3dCF7e,
                share: BASE_SEPOLIA_SHARE_TOKEN
            }),
            protocols: ProtocolsConfig({
                aavePoolAddressesProvider: 0x9bf12E915461A48bc61ddca5f295A0E20BBBa5D7,
                comet: 0x571621Ce60Cebb0c1D442B5afb38B1663C6Bf017
            }),
            clf: CLFConfig({
                functionsRouter: 0xf9B8fc078197181C841c296C876945aaa425B278,
                donId: 0x66756e2d626173652d7365706f6c69612d310000000000000000000000000000,
                clfSubId: 333
            }),
            peers: PeersConfig({
                localPeer: BASE_SEPOLIA_PEER,
                localChainSelector: BASE_SEPOLIA_CHAIN_SELECTOR,
                remotePeers: remotePeers,
                remoteChainSelectors: remoteChainSelectors,
                localSharePool: BASE_SEPOLIA_SHARE_POOL,
                remoteSharePools: remoteSharePools,
                localShare: BASE_SEPOLIA_SHARE_TOKEN,
                remoteShares: remoteShares,
                parentRebalancer: 0x0000000000000000000000000000000000000000
            })
        });
    }

    function getAvalancheFujiConfig() public returns (NetworkConfig memory) {
        remotePeers[0] = ETH_SEPOLIA_PEER;
        remotePeers[1] = BASE_SEPOLIA_PEER;

        remoteChainSelectors[0] = ETH_SEPOLIA_CHAIN_SELECTOR;
        remoteChainSelectors[1] = BASE_SEPOLIA_CHAIN_SELECTOR;

        remoteSharePools[0] = ETH_SEPOLIA_SHARE_POOL;
        remoteSharePools[1] = BASE_SEPOLIA_SHARE_POOL;

        remoteShares[0] = ETH_SEPOLIA_SHARE_TOKEN;
        remoteShares[1] = BASE_SEPOLIA_SHARE_TOKEN;

        return NetworkConfig({
            ccip: CCIPConfig({
                ccipRouter: 0xF694E193200268f9a4868e4Aa017A0118C9a8177,
                thisChainSelector: 14767482510784806043,
                parentChainSelector: ETH_SEPOLIA_CHAIN_SELECTOR,
                rmnProxy: 0xAc8CFc3762a979628334a0E4C1026244498E821b,
                usdcTokenPool: 0x5931822f394baBC2AACF4588E98FC77a9f5aa8C9,
                cctpMessageTransmitter: 0xa9fB1b3009DCb79E2fe346c16a604B8Fa8aE0a79,
                tokenAdminRegistry: 0xA92053a4a3922084d992fD2835bdBa4caC6877e6,
                registryModuleOwnerCustom: 0x97300785aF1edE1343DB6d90706A35CF14aA3d81
            }),
            tokens: TokensConfig({
                link: 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846,
                usdc: 0x5425890298aed601595a70AB815c96711a31Bc65,
                share: AVALANCHE_FUJI_SHARE_TOKEN
            }),
            protocols: ProtocolsConfig({
                aavePoolAddressesProvider: 0xc314344EA3676CD43EAc7c9B02B00e6cfE1Af774,
                comet: 0x43a5Ddb9561762D835B6c0f15Cb8a7ed02F6D958
            }),
            clf: CLFConfig({
                functionsRouter: 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0,
                donId: 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000,
                clfSubId: 15593
            }),
            peers: PeersConfig({
                localPeer: AVALANCHE_FUJI_PEER,
                localChainSelector: AVALANCHE_FUJI_CHAIN_SELECTOR,
                remotePeers: remotePeers,
                remoteChainSelectors: remoteChainSelectors,
                localSharePool: AVALANCHE_FUJI_SHARE_POOL,
                remoteSharePools: remoteSharePools,
                localShare: AVALANCHE_FUJI_SHARE_TOKEN,
                remoteShares: remoteShares,
                parentRebalancer: 0x0000000000000000000000000000000000000000
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
            }),
            peers: PeersConfig({
                localPeer: 0x0000000000000000000000000000000000000000,
                localChainSelector: 0,
                remotePeers: new address[](0),
                remoteChainSelectors: new uint64[](0),
                localSharePool: 0x0000000000000000000000000000000000000000,
                remoteSharePools: new address[](0),
                localShare: 0x0000000000000000000000000000000000000000,
                remoteShares: new address[](0),
                parentRebalancer: 0x0000000000000000000000000000000000000000
            })
        });
    }
}
