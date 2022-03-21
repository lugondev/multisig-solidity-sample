// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IMERC20.sol";

interface IBridgeMERC20 is IMERC20 {
    function bridgeIn(address _address, uint256 _amount) external;

    function bridgeOut(address _address, uint256 _amount) external;

    function isMainMERC20(address _address) external view returns (bool);

    function getBridgeOwner(bytes32 _id) external view returns (address);

    function getBridgeAmount(bytes32 _id) external view returns (uint256);

    function isPendingBridge(bytes32 _id) external view returns (bool);

    function approveBridge(address _account, bytes32 _id) external;
}
