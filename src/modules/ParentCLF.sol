// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ParentPeer} from "../peers/ParentPeer.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_3_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_X/libraries/FunctionsRequest.sol";

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
    string internal constant SOURCE = "https://raw.githubusercontent.com/contractlevel/yield/main/functions/src.js";
    bytes internal constant ENCRYPTED_SECRET =
        "0x4153bb6d413085aeb1a60f3574ceddfe021b4e5915e1a8dc02518668af9b738ab992e595217e19465ca9691e3bc0adb7915b94d3e8c1551456a251abd8fdf2c3c88d3ecf2cece543fd2b8fd8431bc547c5835de69ab6a29e49e0543bdb99c3c775be7aaec40a2576802233ef9ea841829b779e766a656fcbfd434a63ca79cf7fe328af03cc9e5f2280659014c9db075196e167c754bea74fdc0a085a879b58ac742eb6beb455e67211340639783f6d0baa190a288dd57949c7e058f6d09ab5ecdd7ea7af855bc6808004444b10e2c131590735a1fb2d957cfae404a62fd05f3b44";

    /// @dev Chainlink Functions DON ID
    bytes32 internal immutable i_donId;
    /// @dev Chainlink Functions subscription ID
    uint64 internal immutable i_clfSubId;
    /// @dev Chainlink Functions encrypted secret
    bytes internal s_encryptedSecret;

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
        FunctionsRequest.Request memory req;
        req._initializeRequest(FunctionsRequest.Location.Remote, FunctionsRequest.CodeLanguage.JavaScript, SOURCE);
        req._addSecretsReference(ENCRYPTED_SECRET);

        bytes32 requestId = _sendRequest(req._encodeCBOR(), i_clfSubId, CLF_GAS_LIMIT, i_donId);

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
    /// @dev If there are no shares, there is no value in the system. Therefore there is nothing to rebalance.
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

        /// @dev If there are no shares, there is no value in the system. Therefore there is nothing to rebalance.
        // @review double check this
        // @review including this is a bug because then we cant rebalance regardless.
        // if (s_totalShares == 0) return;

        _setStrategy(chainSelector, Protocol(protocolEnum));
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Set the Chainlink Automation upkeep address
    /// @param upkeepAddress The address of the Chainlink Automation upkeep
    /// @dev Revert if the caller is not the owner
    function setUpkeepAddress(address upkeepAddress) external onlyOwner {
        s_upkeepAddress = upkeepAddress;
    }

    /// @notice Set the number of protocols
    /// @param numberOfProtocols The number of protocols
    /// @dev Revert if the caller is not the owner
    function setNumberOfProtocols(uint8 numberOfProtocols) external onlyOwner {
        s_numberOfProtocols = numberOfProtocols;
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
