// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./VoterExecute.sol";

contract VoterMintBAM is VoterExecute {
    address public target;

    function initialize(address _target) public initializer {
        target = _target;

        _initialize();
    }

    function requestMinter(address _account, uint256 _amount) public onlyVoter {
        bytes memory data = abi.encodeWithSignature(
            "mint(address,uint256)",
            _account,
            _amount
        );
        _createRequest(target, data);
    }

    function acceptRequest(uint256 _id) public onlyVoter {
        RequestData memory requestData = _beforeAcceptRequest(_id);
        require(requestData.target == target, "invalid target");

        (bool success, ) = target.call(requestData.data);
        require(success, "target call fail");

        emit ExecuteRequest(_id);
    }
}
