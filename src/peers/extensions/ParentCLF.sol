// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ParentPeer} from "../ParentPeer.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_3_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

/// @title CLY Parent Peer with Chainlink Functions
/// @author @contractlevel
/// @notice This is the contract that must be used as the ParentPeer for the CLY system as it includes essential functionality
/// @notice This contract handles the Automation of the CLY system by using Chainlink Functions to fetch the strategy with the highest yield
/// @notice This contract must inherit ParentPeer
contract ParentCLF is ParentPeer, FunctionsClient {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using FunctionsRequest for FunctionsRequest.Request;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ParentCLF__OnlyUpkeep();

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
    bytes internal constant ENCRYPTED_SECRET =
        hex"1b4e2d1a565a496c987dc6d8303c52370378b6dcecfd8c1a11b7141822be2b3cb96daba5632633858fe0f07fd5ac85b5293101588003a9f260b0c3d1134765de7b9b16bc1d9087affbf117c4b40a259bc618892ade4707190950fd320e239e36e1f16d577e8c9ed52bad67544530dbca3d846dc4b1f3f8eb6c7a6346172762f449be0d5bcfac35dde9a342db2e009d19c87facf05164b6a3ea257c5a687190b38ec8fd117bfc6a27d7da08abb980afb3aca40b71adbf1cf823b6a3b7bda583e3dc76f1e828bb991398c0b0ee96a2b6c5414c86f62e317286480850e80e8d6ab32718640ef44135f7a875b29e757566a823";
    // bytes internal constant AVALANCHE_ENCRYPTED_SECRET =
    //     hex"c37b08028a80330e0fb5c784f636424f03660be7ac1007bbdefe1a9456a3008634433ceccdb128bbd58b9c95125b3ad42751e7ba7b01f435833b30a07402ad44832b0110ad06a7c9f764cdb939292e1df97ee18ba46e93b3814ff7e205926ae072100aff074289c22d9eb342e8832790431accc8dd4e9dc868d21d944966f6c67a7574fa09c8d9c67119b0bec146f87f986d7ed9550cedef7e3c75b7feaee0722b4c82295f0c02eab7ecec08c1d22e27906179bc9dd2d11336b42793e13f24c43b2a9b993967551ff7fe619f0a31212538f973efd33d9955ac713b16717a899a17a58e8ee21160814b6464ebff934c35cdd5bd31b50a6074c08ecfb0330e435c2d";

    /// @dev Chainlink Functions DON ID
    bytes32 internal immutable i_donId;
    /// @dev Chainlink Functions subscription ID
    uint64 internal immutable i_clfSubId;

    /// @dev Chainlink Automation upkeep address
    /// @notice This is not "forwarder" because we are using time-based Automation
    address internal s_upkeepAddress;
    /// @dev Number of protocols
    /// @notice This is used to validate the protocol enum in the Chainlink Functions response
    uint8 internal s_numberOfProtocols;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when a Chainlink Functions request is sent
    event CLFRequestSent(bytes32 indexed requestId);
    /// @notice Emitted when a Chainlink Functions request returns an error
    event CLFRequestError(bytes32 indexed requestId, bytes err);
    /// @notice Emitted when a Chainlink Functions request is fulfilled
    event CLFRequestFulfilled(bytes32 indexed requestId, uint64 indexed chainSelector, uint8 indexed protocolEnum);
    /// @notice Emitted when a Chainlink Functions request returns an invalid chain selector
    event InvalidChainSelector(bytes32 indexed requestId, uint64 indexed chainSelector);
    /// @notice Emitted when a Chainlink Functions request returns an invalid protocol enum
    event InvalidProtocolEnum(bytes32 indexed requestId, uint8 indexed protocolEnum);
    /// @notice Emitted when the Chainlink Automation upkeep address is set
    event UpkeepAddressSet(address indexed upkeepAddress);
    /// @notice Emitted when the number of protocols is set
    event NumberOfProtocolsSet(uint8 indexed numberOfProtocols);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @param ccipRouter The address of the CCIP router
    /// @param link The address of the LINK token
    /// @param thisChainSelector The selector of the chain this contract is deployed on
    /// @param usdc The address of the USDC token
    /// @param aavePoolAddressesProvider The address of the Aave pool addresses provider
    /// @param comet The address of the Compound v3 Comet USDC pool
    /// @param share The address of the SHARE token native to this system that is minted in exchange for USDC deposits
    /// @param functionsRouter The address of the Chainlink Functions router
    /// @param donId The DON ID for the Chainlink Functions request
    /// @param clfSubId The subscription ID for the Chainlink Functions request
    /// @dev s_numberOfProtocols is set to 1 for now because we only have Aave V3 and Compound V3
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
        ParentPeer(ccipRouter, link, thisChainSelector, usdc, aavePoolAddressesProvider, comet, share)
        FunctionsClient(functionsRouter)
    {
        i_donId = donId;
        i_clfSubId = clfSubId;
        s_numberOfProtocols = 1;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Called by Chainlink Automation to send a Chainlink Functions request
    /// @notice The nature of the request is to fetch the strategy with the highest yield
    /// @dev Revert if the caller is not the Chainlink Automation upkeep address
    function sendCLFRequest() external {
        if (msg.sender != s_upkeepAddress) revert ParentCLF__OnlyUpkeep();

        /// @dev Send CLF request
        //slither-disable-next-line uninitialized-local
        FunctionsRequest.Request memory req;
        req.initializeRequest(FunctionsRequest.Location.Inline, FunctionsRequest.CodeLanguage.JavaScript, SOURCE);
        req.addSecretsReference(ENCRYPTED_SECRET);

        bytes32 requestId = _sendRequest(req.encodeCBOR(), i_clfSubId, CLF_GAS_LIMIT, i_donId);

        // @review I dont think we need this because _sendRequest emits an essentially identical event
        emit CLFRequestSent(requestId);
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
        (uint256 decodedSelector, uint256 decodedEnum) = abi.decode(response, (uint256, uint256));
        uint64 chainSelector = uint64(decodedSelector);
        uint8 protocolEnum = uint8(decodedEnum);

        if (!s_allowedChains[chainSelector]) {
            emit InvalidChainSelector(requestId, chainSelector);
            return;
        }
        if (protocolEnum > s_numberOfProtocols) {
            emit InvalidProtocolEnum(requestId, protocolEnum);
            return;
        }

        emit CLFRequestFulfilled(requestId, chainSelector, protocolEnum);

        _setStrategy(chainSelector, Protocol(protocolEnum));
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

    /// @notice Set the number of protocols
    /// @param numberOfProtocols The number of protocols
    /// @dev Revert if the caller is not the owner
    function setNumberOfProtocols(uint8 numberOfProtocols) external onlyOwner {
        s_numberOfProtocols = numberOfProtocols;
        emit NumberOfProtocolsSet(numberOfProtocols);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @return The address of the Chainlink Functions router
    function getFunctionsRouter() external view returns (address) {
        return address(i_functionsRouter);
    }

    /// @return The Chainlink Functions DON ID
    function getDonId() external view returns (bytes32) {
        return i_donId;
    }

    /// @return The Chainlink Functions subscription ID
    function getClfSubId() external view returns (uint64) {
        return i_clfSubId;
    }
}
