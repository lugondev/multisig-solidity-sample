// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IMERC20 is IERC20Metadata {
    function getMappedAddress(address account) external view returns (address);

    function getRequestTargets(address _token) external view returns (address);

    function mint(address _address, uint256 _amount) external;

    function burn(uint256 _amount) external;

    function acceptMapAddress(address _requester) external;

    function requestTarget(address _target) external returns (bool);

    function unmapAddress() external;

    function countPendingRequestTarget(address _account)
        external
        view
        returns (uint256);

    function getPendingRequestTargetByIndex(address _account, uint256 _index)
        external
        view
        returns (address);
}
