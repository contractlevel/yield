// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from "@aave/v3-origin/src/contracts/protocol/libraries/types/DataTypes.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice These mocks will be deployed on testnets that do not have the actual Compound contracts deployed
/// Therefore there will be no borrowers and no interest accrued, hence no yield.
/// This is to allow for testing of the system without the need to deploy the actual Compound contracts.
contract MockCometNoYield is Ownable {
    error MockCometNoYield__OnlyPeer();

    mapping(address => uint256) private s_balances;
    address private s_peer;

    constructor() Ownable(msg.sender) {}

    function supply(address asset, uint256 amount) external {
        s_balances[msg.sender] += amount;
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address asset, uint256 amount) external {
        if (msg.sender != s_peer) revert MockCometNoYield__OnlyPeer();
        require(s_balances[msg.sender] >= amount, "Insufficient balance");
        s_balances[msg.sender] -= amount;
        IERC20(asset).transfer(msg.sender, amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return s_balances[account];
    }

    function setPeer(address peer) external onlyOwner {
        s_peer = peer;
    }

    function getPeer() external view returns (address) {
        return s_peer;
    }
}
