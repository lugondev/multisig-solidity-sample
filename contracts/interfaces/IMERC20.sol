// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IMERC20 is IERC20Metadata {
    function getTargetOfAddress(address _account) external view returns (address);

    function getCurrentRequestMapping(address _account)
        external
        view
        returns (address);

    function acceptMappingAddress(address _requester) external;

    function rejectMappedAddress(address _mapped) external;

    function requestMappingToTarget(address _target) external returns (bool);

    function unmappingAddress() external;

    function cancelPendingMapping() external;

    function isTargetMappingAddress(address _account)
        external
        view
        returns (bool);

    function countPendingRequestMapping(address _account)
        external
        view
        returns (uint256);

    function countMappedAddresses(address _account)
        external
        view
        returns (uint256);

    function getPendingRequestMappingByIndex(address _account, uint256 _index)
        external
        view
        returns (address);

    function getMappedAddressByIndex(address _account, uint256 _index)
        external
        view
        returns (address);
}
