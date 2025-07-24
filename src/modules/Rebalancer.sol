// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IParentPeer, IYieldPeer} from "../interfaces/IParentPeer.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_3_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {ILogAutomation, Log} from "@chainlink/contracts/src/v0.8/automation/interfaces/ILogAutomation.sol";
import {AutomationBase} from "@chainlink/contracts/src/v0.8/automation/AutomationBase.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IStrategyRegistry} from "../interfaces/IStrategyRegistry.sol";

/// @title Rebalancer
/// @author @contractlevel
/// @notice Combination of previous ParentRebalancer and ParentCLF contracts
/// @notice Rebalances YieldCoin TVL across all protocols
contract Rebalancer is FunctionsClient, AutomationBase, ILogAutomation, Ownable2Step {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using FunctionsRequest for FunctionsRequest.Request;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Rebalancer__OnlyUpkeep();
    error Rebalancer__OnlyForwarder();
    error Rebalancer__UpkeepNotNeeded();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev Chainlink Functions gas limit
    uint32 internal constant CLF_GAS_LIMIT = 300_000;
    /// @dev Source code for the Chainlink Functions request
    /// @notice This includes a remote script that is fetched from the contract level repo, enabling us to add more protocols and chains without redeploying this contract
    string internal constant SOURCE =
        "try { const r = await fetch('https://raw.githubusercontent.com/contractlevel/yield/main/functions/src.min.js'); if (!r.ok) throw Error('F:' + r.status); return eval(await r.text()); } catch (e) { return Functions.encodeString(e.message.slice(0,99)); }";
    /// @dev Encrypted secret for the Chainlink Functions request
    // bytes internal constant BASE_SEPOLIA_ENCRYPTED_SECRET =
    //     hex"1b4e2d1a565a496c987dc6d8303c52370378b6dcecfd8c1a11b7141822be2b3cb96daba5632633858fe0f07fd5ac85b5293101588003a9f260b0c3d1134765de7b9b16bc1d9087affbf117c4b40a259bc618892ade4707190950fd320e239e36e1f16d577e8c9ed52bad67544530dbca3d846dc4b1f3f8eb6c7a6346172762f449be0d5bcfac35dde9a342db2e009d19c87facf05164b6a3ea257c5a687190b38ec8fd117bfc6a27d7da08abb980afb3aca40b71adbf1cf823b6a3b7bda583e3dc76f1e828bb991398c0b0ee96a2b6c5414c86f62e317286480850e80e8d6ab32718640ef44135f7a875b29e757566a823";
    bytes internal constant ETH_SEPOLIA_ENCRYPTED_SECRET =
        hex"519ffb85c8bd90ed9f422f733082d43d03332a97459dec67e5922c64af61f22c8e0f872f324c884dc55d40cade8d28e111668f614eedb48adb5519e6f1c59cdea63470052378d9d51609209505c061e5c7d5c9a703b1d27f40697c944672b6d917ad539cc5bb5da1d1de79cc4508f4c82a3fb2cd8c8f20589039a372bc419ecdda561f94472033e3fd7d43610d639592653576f506c1d9185077ac3533333998538cfb478885da3ced87752b5bb213adb918d58791e083c59d94a580f2f568c2c35345815d3722f4675f18e4286a851f757e3f8582078c321dbf1193e30112540182260fef5bf97b08ab5565a0de2d0fc3";

    /// @dev Chainlink Functions DON ID
    bytes32 internal immutable i_donId;
    /// @dev Chainlink Functions subscription ID
    uint64 internal immutable i_clfSubId;

    /// @dev Chainlink Automation upkeep address
    /// @notice This is not "forwarder" because we are using time-based Automation
    address internal s_upkeepAddress;
    /// @dev Chainlink Automation forwarder
    address internal s_forwarder;
    /// @dev ParentPeer contract address
    address internal s_parentPeer;
    /// @dev Strategy registry
    address internal s_strategyRegistry;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a Chainlink Functions request returns an error
    event CLFRequestError(bytes32 indexed requestId, bytes err);
    /// @notice Emitted when a Chainlink Functions request is fulfilled
    event CLFRequestFulfilled(bytes32 indexed requestId, uint64 indexed chainSelector, bytes32 indexed protocolId);
    /// @notice Emitted when a Chainlink Functions request returns an invalid chain selector
    event InvalidChainSelector(bytes32 indexed requestId, uint64 indexed chainSelector);
    /// @notice Emitted when a Chainlink Functions request returns an invalid protocol ID
    event InvalidProtocolId(bytes32 indexed requestId, bytes32 indexed protocolId);

    /// @notice Emitted when the Chainlink Automation upkeep address is set
    event UpkeepAddressSet(address indexed upkeepAddress);
    /// @notice Emitted when the Chainlink Automation forwarder is set
    event ForwarderSet(address indexed forwarder);
    /// @notice Emitted when the ParentPeer contract address is set
    event ParentPeerSet(address indexed parentPeer);
    /// @notice Emitted when the strategy registry is set
    event StrategyRegistrySet(address indexed strategyRegistry);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param functionsRouter The address of the Chainlink Functions router
    /// @param donId The Chainlink Functions DON ID
    /// @param clfSubId The Chainlink Functions subscription ID
    constructor(address functionsRouter, bytes32 donId, uint64 clfSubId)
        Ownable(msg.sender)
        FunctionsClient(functionsRouter)
    {
        i_donId = donId;
        i_clfSubId = clfSubId;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Called by Chainlink Automation to send a Chainlink Functions request
    /// @notice The nature of the request is to fetch the strategy with the highest yield
    /// @dev Revert if the caller is not the Chainlink Automation upkeep address
    // @review should be pausable?
    function sendCLFRequest() external {
        if (msg.sender != s_upkeepAddress) revert Rebalancer__OnlyUpkeep();

        /// @dev Send CLF request
        //slither-disable-next-line uninitialized-local
        FunctionsRequest.Request memory req;
        req.initializeRequest(FunctionsRequest.Location.Inline, FunctionsRequest.CodeLanguage.JavaScript, SOURCE);
        req.addSecretsReference(ETH_SEPOLIA_ENCRYPTED_SECRET);

        _sendRequest(req.encodeCBOR(), i_clfSubId, CLF_GAS_LIMIT, i_donId);
    }

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
        bytes32 eventSignature = keccak256("StrategyUpdated(uint64,bytes32,uint64)");
        address parentPeer = s_parentPeer;
        uint64 thisChainSelector = IParentPeer(parentPeer).getThisChainSelector();
        address forwarder = s_forwarder;

        if (log.source == parentPeer && log.topics[0] == eventSignature) {
            uint64 chainSelector = uint64(uint256(log.topics[1]));
            bytes32 protocolId = log.topics[2];
            uint64 oldChainSelector = uint64(uint256(log.topics[3]));

            if (chainSelector == thisChainSelector && oldChainSelector == thisChainSelector) {
                performData = "";
                upkeepNeeded = false;
                revert Rebalancer__UpkeepNotNeeded();
            }

            IYieldPeer.Strategy memory newStrategy =
                IYieldPeer.Strategy({chainSelector: chainSelector, protocolId: protocolId});
            IYieldPeer.CcipTxType txType;
            address oldStrategyAdapter = IYieldPeer(parentPeer).getStrategyAdapter(newStrategy.protocolId);
            // slither-disable-next-line uninitialized-local
            uint256 totalValue;

            if (oldChainSelector == thisChainSelector && chainSelector != thisChainSelector) {
                txType = IYieldPeer.CcipTxType.RebalanceNewStrategy;
                totalValue = IYieldPeer(parentPeer).getTotalValue();
            } else {
                txType = IYieldPeer.CcipTxType.RebalanceOldStrategy;
            }

            performData =
                abi.encode(forwarder, parentPeer, newStrategy, txType, oldChainSelector, oldStrategyAdapter, totalValue);
            upkeepNeeded = true;
        } else {
            performData = "";
            upkeepNeeded = false;
            revert Rebalancer__UpkeepNotNeeded();
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
            address oldStrategyAdapter,
            uint256 totalValue
        ) = abi.decode(
            performData, (address, address, IYieldPeer.Strategy, IYieldPeer.CcipTxType, uint64, address, uint256)
        );

        if (msg.sender != forwarder) revert Rebalancer__OnlyForwarder();

        if (txType == IYieldPeer.CcipTxType.RebalanceNewStrategy) {
            IParentPeer(parentPeer).rebalanceNewStrategy(oldStrategyAdapter, totalValue, strategy);
        } else {
            IParentPeer(parentPeer).rebalanceOldStrategy(oldChainSelector, strategy);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Chainlink Functions request callback
    /// @notice The CLF infrastructure calls this to return the chain selector and protocol enum for the strategy with the highest yield
    /// @param requestId The ID of the request
    /// @param response The response from the Chainlink Functions request
    /// @param err The error from the Chainlink Functions request
    /// @dev Return if the response is an error
    /// @dev Return if the chain selector is not allowed
    /// @dev Return if the protocol enum is not valid
    function _fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (err.length > 0) {
            emit CLFRequestError(requestId, err);
            return;
        }
        (uint256 decodedSelector, bytes32 protocolId) = abi.decode(response, (uint256, bytes32));
        uint64 chainSelector = uint64(decodedSelector);

        address parentPeer = s_parentPeer;

        if (!IParentPeer(parentPeer).getAllowedChain(chainSelector)) {
            emit InvalidChainSelector(requestId, chainSelector);
            return;
        }
        if (IStrategyRegistry(s_strategyRegistry).getStrategyAdapter(protocolId) == address(0)) {
            emit InvalidProtocolId(requestId, protocolId);
            return;
        }

        emit CLFRequestFulfilled(requestId, chainSelector, protocolId);

        IParentPeer(parentPeer).setStrategy(chainSelector, protocolId);
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Set the Chainlink Automation upkeep address
    /// @param upkeepAddress The address of the Chainlink Automation upkeep
    /// @dev Revert if the caller is not the owner
    //slither-disable-next-line missing-zero-check
    function setUpkeepAddress(address upkeepAddress) external onlyOwner {
        s_upkeepAddress = upkeepAddress;
        emit UpkeepAddressSet(upkeepAddress);
    }

    /// @notice Sets the Chainlink Automation forwarder
    /// @param forwarder The address of the Chainlink Automation forwarder
    /// @dev Revert if the caller is not the owner
    // slither-disable-next-line missing-zero-check
    function setForwarder(address forwarder) external onlyOwner {
        s_forwarder = forwarder;
        emit ForwarderSet(forwarder);
    }

    /// @notice Sets the ParentPeer contract address
    /// @param parentPeer The address of the ParentPeer contract
    /// @dev Revert if the caller is not the owner
    // slither-disable-next-line missing-zero-check
    function setParentPeer(address parentPeer) external onlyOwner {
        s_parentPeer = parentPeer;
        emit ParentPeerSet(parentPeer);
    }

    /// @notice Sets the strategy registry
    /// @param strategyRegistry The address of the strategy registry
    /// @dev Revert if the caller is not the owner
    function setStrategyRegistry(address strategyRegistry) external onlyOwner {
        s_strategyRegistry = strategyRegistry;
        emit StrategyRegistrySet(strategyRegistry);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @return functionsRouter The address of the Chainlink Functions router
    function getFunctionsRouter() external view returns (address functionsRouter) {
        functionsRouter = address(i_functionsRouter);
    }

    /// @return donId The Chainlink Functions DON ID
    function getDonId() external view returns (bytes32 donId) {
        donId = i_donId;
    }

    /// @return clfSubId The Chainlink Functions subscription ID
    function getClfSubId() external view returns (uint64 clfSubId) {
        clfSubId = i_clfSubId;
    }

    /// @return upkeepAddress The Chainlink Automation upkeep address
    function getUpkeepAddress() external view returns (address upkeepAddress) {
        upkeepAddress = s_upkeepAddress;
    }

    /// @return forwarder The Chainlink Automation forwarder
    function getForwarder() external view returns (address forwarder) {
        forwarder = s_forwarder;
    }

    /// @return parentPeer The ParentPeer contract address
    function getParentPeer() external view returns (address parentPeer) {
        parentPeer = s_parentPeer;
    }

    /// @return strategyRegistry The strategy registry address
    function getStrategyRegistry() external view returns (address strategyRegistry) {
        strategyRegistry = s_strategyRegistry;
    }
}
