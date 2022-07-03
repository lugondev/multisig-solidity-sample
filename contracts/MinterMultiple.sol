// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./MultiOwners.sol";

interface IMintableToken {
    function mint(address _user, uint256 _amount) external;
}

contract MinterMultiple is MultiOwners {
    event Mint(address indexed to, uint256 amount);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address _owner) public initializer {
        masterOwner = _owner;
    }

    function mint(
        IMintableToken token,
        address[] memory _addresses,
        uint256[] memory _amounts
    ) public onlyOwner {
        require(_addresses.length == _amounts.length, "Invalid data");
        for (uint256 index = 0; index < _addresses.length; index++) {
            address _user = _addresses[index];
            token.mint(_user, _amounts[index]);
            emit Mint(_user, _amounts[index]);
        }
    }
}
