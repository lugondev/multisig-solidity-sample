// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./SecuredTokenTransfer.sol";

contract MultiSend is SecuredTokenTransfer {
    function _multiSend(
        address _token,
        address[] memory _receivers,
        uint256[] memory _amounts
    ) internal {
        require(_receivers.length == _amounts.length, "invalid data");
        for (uint256 i = 0; i < _receivers.length; i++) {
            bool success = transferToken(_token, _receivers[i], _amounts[i]);
            require(success, "transfer failed");
        }
    }

    function _multiSendTokens(
        address[] memory _tokens,
        address[] memory _receivers,
        uint256[] memory _amounts
    ) internal {
        require(_receivers.length == _amounts.length, "invalid data");
        require(_receivers.length == _tokens.length, "invalid data");
        for (uint256 i = 0; i < _receivers.length; i++) {
            bool success = transferToken(
                _tokens[i],
                _receivers[i],
                _amounts[i]
            );
            require(success, "transfer failed");
        }
    }
}
