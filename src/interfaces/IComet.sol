// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IComet {
    function supply(address asset, uint256 amount) external;
    function withdraw(address asset, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}
