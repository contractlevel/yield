// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {PausableWithAccessControl, Roles} from "./PausableWithAccessControl.sol";
import {IYieldFees} from "../interfaces/IYieldFees.sol";

/// @title YieldFees
/// @author @contractlevel
/// @notice Module for managing fees for the YieldCoin system
/// @notice This contract is abstract because it is intended to be inherited by the YieldPeer contract.
/// @notice Fees are collected on every chain during deposit if s_feeRate is not 0.
/// @notice Fees are taken in YieldPeer::_initiateDeposit
/// @notice FV for this contract is in certora/spec/yield/BasePeer.spec
abstract contract YieldFees is PausableWithAccessControl, IYieldFees {
    /*//////////////////////////////////////////////////////////////
                           TYPE DECLARATIONS
    //////////////////////////////////////////////////////////////*/
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error YieldFees__FeeRateTooHigh();
    error YieldFees__NoFeesToWithdraw();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev The divisor used to calculate the fee rate in basis points
    uint256 internal constant FEE_RATE_DIVISOR = 1_000_000; // 1e6 (same as USDC decimals)
    /// @dev The maximum fee rate: 1% = 10_000 / 1e6
    uint256 internal constant MAX_FEE_RATE = 10_000;
    /// @dev The initial fee rate
    uint256 internal constant INITIAL_FEE_RATE = 1_000; // 0.1%

    /// @dev The fee rate
    uint256 internal s_feeRate;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Emitted when the fee rate is set
    event FeeRateSet(uint256 indexed feeRate);
    /// @notice Emitted when a fee is taken during a deposit
    event FeeTaken(uint256 indexed feeAmountInStablecoin);
    /// @notice Emitted when fees are withdrawn
    event FeesWithdrawn(uint256 indexed feesWithdrawn);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() {
        s_feeRate = INITIAL_FEE_RATE;
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/
    /// @notice Withdraws the fees
    /// @param feeToken The token to withdraw the fees in (e.g. USDC, USDT, GHO, etc.)
    /// @dev Revert if msg.sender does not have role of "FEE_WITHDRAWER_ROLE" in access control
    /// @dev Revert if the main inheriting Yield contract is paused (in case of emergency)
    function withdrawFees(address feeToken) external whenNotPaused onlyRole(Roles.FEE_WITHDRAWER_ROLE) {
        uint256 fees = IERC20(feeToken).balanceOf(address(this));
        if (fees != 0) {
            emit FeesWithdrawn(fees);
            IERC20(feeToken).safeTransfer(msg.sender, fees);
        } else {
            revert YieldFees__NoFeesToWithdraw();
        }
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    /// @notice Calculates the fee for a deposit
    /// @param stablecoinDepositAmount The amount of stablecoins being deposited
    /// @return fee The fee for the deposit
    /// @notice The fee is paid to the YieldCoin infrastructure to cover development and Chainlink costs
    function _calculateFee(uint256 stablecoinDepositAmount) internal view returns (uint256 fee) {
        fee = s_feeRate;
        // @review:certora check if certora timeouts with solady
        if (fee != 0) fee = (stablecoinDepositAmount * fee) / FEE_RATE_DIVISOR;
        // if (fee != 0) fee = FixedPointMathLib.mulDivUp(stablecoinDepositAmount, fee, FEE_RATE_DIVISOR);
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the fee rate
    /// @notice Fee rate should be set on every chain if consistency is desired
    /// @param newFeeRate The new fee rate
    /// @dev Revert if msg.sender does not have role of "FEE_RATE_SETTER_ROLE" in access control
    function setFeeRate(uint256 newFeeRate) external onlyRole(Roles.FEE_RATE_SETTER_ROLE) {
        if (newFeeRate > MAX_FEE_RATE) {
            revert YieldFees__FeeRateTooHigh();
        }
        s_feeRate = newFeeRate;
        emit FeeRateSet(newFeeRate);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Get the current fee rate
    /// @return feeRate The current fee rate
    function getFeeRate() external view returns (uint256) {
        return s_feeRate;
    }

    /// @notice Get the current fee rate divisor
    /// @return feeRateDivisor The current fee rate divisor
    function getFeeRateDivisor() external pure returns (uint256) {
        return FEE_RATE_DIVISOR;
    }

    /// @notice Get the maximum fee rate
    /// @return maxFeeRate The maximum fee rate
    function getMaxFeeRate() external pure returns (uint256) {
        return MAX_FEE_RATE;
    }
}
