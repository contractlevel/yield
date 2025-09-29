// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IYieldFees} from "../interfaces/IYieldFees.sol";

/// @title YieldFees
/// @author @contractlevel
/// @notice Module for managing fees for the YieldCoin system
/// @notice This contract is abstract because it is intended to be inherited by the YieldPeer contract.
/// @notice Fees are collected on every chain during deposit.
/// @notice Fees are taken in YieldPeer::_initiateDeposit
abstract contract YieldFees is Ownable2Step, IYieldFees {
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
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/
    /// @notice Withdraws the fees
    /// @param feeToken The token to withdraw the fees in (e.g. USDC, USDT, GHO, etc.)
    /// @dev Revert if msg.sender is not the owner
    function withdrawFees(address feeToken) external onlyOwner {
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
        // @review how much more optimal in terms of gas would it be to just assign this to fee? readability would decrease
        uint256 feeRate = s_feeRate;
        // @review should we be using solady fixedpointmath?
        if (feeRate != 0) fee = (stablecoinDepositAmount * feeRate) / FEE_RATE_DIVISOR;
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    /// @notice Sets the fee rate
    /// @dev Revert if msg.sender is not the owner
    /// @param newFeeRate The new fee rate
    /// @notice Fee rate should be set on every chain if consistency is desired
    function setFeeRate(uint256 newFeeRate) external onlyOwner {
        if (newFeeRate > MAX_FEE_RATE) revert YieldFees__FeeRateTooHigh();
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
