// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";

contract MockAavePool {
    // Track user balances
    mapping(address => uint256) private s_balances;
    // Track last update timestamp per user per asset
    mapping(address => uint256) private s_lastUpdateTimestamp;
    // Annual interest rate (in basis points, e.g. 500 = 5%)
    uint256 private constant STARTING_INTEREST_RATE = 500;
    // Annual interest rate (in basis points, e.g. 500 = 5%)
    uint256 internal s_interestRate = STARTING_INTEREST_RATE;

    address internal s_aToken;

    error InvalidInterestRate();
    error InvalidAmount();

    function supply(address asset, uint256 amount, address onBehalfOf, uint16) external {
        // if (amount == 0) revert InvalidAmount();
        uint256 interestAccrued = _calculateInterest(onBehalfOf);
        s_balances[onBehalfOf] += interestAccrued; // Realize interest first

        // Update balances and timestamp
        s_balances[onBehalfOf] += amount;
        s_lastUpdateTimestamp[onBehalfOf] = block.timestamp;

        // Transfer asset from user
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        // Calculate interest accrued
        uint256 interestAccrued = _calculateInterest(to);
        s_balances[to] += interestAccrued;

        // Check if user has enough balance
        require(s_balances[to] >= amount, "Insufficient balance");

        // Update balances and timestamp
        s_balances[to] -= amount;
        s_lastUpdateTimestamp[to] = block.timestamp;

        // Transfer asset back to user
        IERC20(asset).transfer(to, amount);

        return amount;
    }

    function getReserveData(address) external view returns (DataTypes.ReserveData memory) {
        DataTypes.ReserveData memory reserveData;
        reserveData.aTokenAddress = s_aToken;
        return reserveData;
    }

    // Internal function to calculate interest
    function _calculateInterest(address account) internal view returns (uint256) {
        uint256 balance = s_balances[account];
        if (balance == 0) return 0;

        uint256 timeElapsed = block.timestamp - s_lastUpdateTimestamp[account];
        // Calculate interest: balance * rate * time / (365 days * 10000)
        return (balance * s_interestRate * timeElapsed) / (365 days * 10000);
    }

    function balanceOf(address account) external view returns (uint256) {
        // Return balance plus accrued interest
        return s_balances[account] + _calculateInterest(account);
    }

    function setInterestRate(uint256 interestRate) external {
        if (interestRate > 2000) revert InvalidInterestRate();
        s_interestRate = interestRate;
    }

    function setATokenAddress(address aTokenAddress) external {
        s_aToken = aTokenAddress;
    }

    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }
}
