// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./MultiSigExecute.sol";

abstract contract VoterMintBAM is MultiSigExecute {
    address public target;
}
