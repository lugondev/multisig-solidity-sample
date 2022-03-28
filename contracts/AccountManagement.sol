// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract AccountManagement is Initializable, AccessControlUpgradeable {
    event UpdateBalance(
        address indexed account,
        uint256 beforeBalance,
        uint256 afterBalance,
        string reason
    );
    event BridgeOut(address indexed account, uint256 amount);
    event BridgeIn(address indexed account, uint256 amount);

}
