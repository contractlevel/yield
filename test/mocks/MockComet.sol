// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IComet} from "../../src/interfaces/IComet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockComet is IComet {
    // Track user balances
    mapping(address => uint256) private s_balances;
    // Track last update timestamp per user
    mapping(address => uint256) private s_lastUpdateTimestamp;
    // Annual interest rate (in basis points, e.g. 500 = 5%)
    uint256 private constant STARTING_INTEREST_RATE = 500;
    // Annual interest rate (in basis points, e.g. 500 = 5%)
    uint256 internal s_interestRate = STARTING_INTEREST_RATE;

    function supply(address asset, uint256 amount) external override {
        uint256 interestAccrued = _calculateInterest(msg.sender);
        s_balances[msg.sender] += interestAccrued;
        s_balances[msg.sender] += amount;
        s_lastUpdateTimestamp[msg.sender] = block.timestamp;
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address asset, uint256 amount) external override {
        // Calculate interest accrued
        uint256 interestAccrued = _calculateInterest(msg.sender);
        s_balances[msg.sender] += interestAccrued;

        // Check if user has enough balance
        require(s_balances[msg.sender] >= amount, "Insufficient balance");

        // Update balances and timestamp
        s_balances[msg.sender] -= amount;
        s_lastUpdateTimestamp[msg.sender] = block.timestamp;

        // Transfer USDC back to user
        IERC20(asset).transfer(msg.sender, amount);
    }

    function balanceOf(address account) external view override returns (uint256) {
        // Return balance plus accrued interest
        return s_balances[account] + _calculateInterest(account);
    }

    // Internal function to calculate interest
    function _calculateInterest(address account) internal view returns (uint256) {
        uint256 balance = s_balances[account];
        if (balance == 0) return 0;

        uint256 timeElapsed = block.timestamp - s_lastUpdateTimestamp[account];
        // Calculate interest: balance * rate * time / (365 days * 10000)
        return (balance * s_interestRate * timeElapsed) / (365 days * 10000);
    }
}
