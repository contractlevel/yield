// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice These mocks will be deployed on testnets that do not have the actual Aave contracts deployed
/// Therefore there will be no borrowers and no interest accrued, hence no yield.
/// This is to allow for testing of the system without the need to deploy the actual Aave contracts.
contract MockAaveNoYield is Ownable {
    error MockAaveNoYield__OnlyPeer();

    address internal immutable i_usdc;

    mapping(address => uint256) private s_balances;
    address private s_aToken;
    address private s_peer;

    constructor(address usdc) Ownable(msg.sender) {
        i_usdc = usdc;
    }

    function supply(address, uint256 amount, address onBehalfOf, uint16) external {
        // s_balances[onBehalfOf] += amount;
        IERC20(i_usdc).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address, uint256 amount, address to) external returns (uint256) {
        if (msg.sender != s_peer) revert MockAaveNoYield__OnlyPeer();
        // require(s_balances[msg.sender] >= amount, "Insufficient balance");
        // s_balances[msg.sender] -= amount;
        IERC20(i_usdc).transfer(to, amount);
        return amount;
    }

    function getReserveData(address) external view returns (DataTypes.ReserveData memory) {
        DataTypes.ReserveData memory reserveData;
        reserveData.aTokenAddress = s_aToken;
        return reserveData;
    }

    function setATokenAddress(address aTokenAddress) external onlyOwner {
        s_aToken = aTokenAddress;
    }

    function setPeer(address peer) external onlyOwner {
        s_peer = peer;
    }

    function balanceOf(address account) external view returns (uint256) {
        return s_balances[account];
    }
}
