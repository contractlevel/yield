// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IYieldFees {
    function getFeeRate() external view returns (uint256);
    function getFeeRateDivisor() external view returns (uint256);
    function getMaxFeeRate() external view returns (uint256);
    function setFeeRate(uint256 newFeeRate) external;
    function withdrawFees(address feeToken) external;
}
