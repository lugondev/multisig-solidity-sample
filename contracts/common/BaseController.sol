// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IController.sol";

abstract contract BaseController is IController, Context, Ownable {
    using ECDSAUpgradeable for bytes32;

    function _verify(ControllerRequest memory req, bytes memory signature)
        internal
        view
        virtual
        returns (bool)
    {
        uint256 nonce = this.nonceOf(req.tokenId);
        address signer = _recover(
            keccak256(req.data),
            req.to,
            nonce,
            signature
        );
        return nonce == req.nonce && signer == req.verifier;
    }

    function _recover(
        bytes32 digest,
        address target,
        uint256 nonce,
        bytes memory signature
    ) internal pure virtual returns (address signer) {
        return
            keccak256(abi.encodePacked(digest, target, nonce))
                .toEthSignedMessageHash()
                .recover(signature);
    }

    function _execute(
        address from,
        address to,
        uint256 tokenId,
        uint256 gas,
        bytes memory data,
        bytes memory signature
    ) internal virtual returns (bytes memory) {
        _invalidateNonce(tokenId);

        (bool success, bytes memory returndata) = to.call{gas: gas}(
            _buildData(from, tokenId, data, signature)
        );
        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        assert(gasleft() > gas / 63);

        return
            _verifyCallResult(
                success,
                returndata,
                "BaseController: CALL_FAILED"
            );
    }

    function _invalidateNonce(
        uint256 /* tokenId */
    ) internal virtual {}

    function _buildData(
        address from,
        uint256 tokenId,
        bytes memory data,
        bytes memory /* signature */
    ) internal view virtual returns (bytes memory) {
        return abi.encodePacked(data, from, tokenId);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                //solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
