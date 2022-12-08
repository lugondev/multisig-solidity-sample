// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IController.sol";
import "./common/BaseController.sol";

contract ControllerManager is BaseController {
    mapping(uint256 => uint256) private _nonces;
    mapping(address => bool) private controllers;

    event ControllerUpdated(address indexed controller, bool status);

    constructor() {
        controllers[_msgSender()] = true;
    }

    function isController(address _user) public view returns (bool) {
        return controllers[_user];
    }

    function updateController(address _ctrler, bool _status)
        external
        onlyOwner
    {
        controllers[_ctrler] = _status;
        emit ControllerUpdated(_ctrler, _status);
    }

    function nonceOf(uint256 tokenId) external view override returns (uint256) {
        return _nonces[tokenId];
    }

    function verify(
        ControllerRequest calldata req,
        address verifier,
        bytes calldata signature
    ) public view override returns (bool) {
        return _verify(req, verifier, signature);
    }

    function execute(ControllerRequest calldata req, bytes calldata signature)
        external
        override
        returns (bytes memory)
    {
        uint256 gas = gasleft();
        require(
            isController(req.verifier),
            "ControllerManager: CALLER_NOT_CONTROLLER"
        );
        require(
            verify(req, req.verifier, signature),
            "ControllerManager: SIGNATURE_INVALID"
        );
        return
            _execute(
                req.verifier,
                req.to,
                req.tokenId,
                gas,
                req.data,
                signature
            );
    }

    function _invalidateNonce(uint256 tokenId) internal override {
        _nonces[tokenId] = _nonces[tokenId] + 1;
    }
}
