// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IController {
    struct ControllerRequest {
        address verifier;
        address to;
        uint256 nonce;
        uint256 tokenId;
        bytes data;
    }

    function nonceOf(uint256 tokenId) external view returns (uint256);

    function verify(
        ControllerRequest calldata req,
        bytes calldata signature
    ) external view returns (bool);

    function execute(ControllerRequest calldata req, bytes calldata signature)
        external
        returns (bytes memory);
}
