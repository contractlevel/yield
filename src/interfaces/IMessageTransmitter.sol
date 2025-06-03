// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IMessageTransmitter {
    function owner() external view returns (address);
    function updateAttesterManager(address attesterManager) external;
    function enableAttester(address attester) external;
    function receiveMessage(bytes calldata message, bytes calldata attestation) external returns (bool success);
    function setSignatureThreshold(uint256 threshold) external;
    function isEnabledAttester(address attester) external view returns (bool);
}
