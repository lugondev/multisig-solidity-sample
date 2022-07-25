// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./MultiOwners.sol";
import "./interfaces/IMintableToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiAction is MultiOwners {
    event Mint(
        IMintableToken indexed token,
        address indexed to,
        uint256 amount
    );
    event Transfer(
        IERC20 indexed token,
        address from,
        address to,
        uint256 amount
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize() public initializer {
        __Ownable_init();
    }

    function multiMinter(
        IMintableToken token,
        address[] memory _addresses,
        uint256[] memory _amounts
    ) public onlyOwner {
        require(_addresses.length == _amounts.length, "Invalid data");
        for (uint256 index = 0; index < _addresses.length; index++) {
            address _user = _addresses[index];
            token.mint(_user, _amounts[index]);
            emit Mint(token, _user, _amounts[index]);
        }
    }

    function multiTransfer(
        IERC20 token,
        address[] memory _addresses,
        uint256[] memory _amounts
    ) public onlyOwner {
        require(_addresses.length == _amounts.length, "Invalid data");
        for (uint256 index = 0; index < _addresses.length; index++) {
            address _user = _addresses[index];
            token.transferFrom(msg.sender, _user, _amounts[index]);

            emit Transfer(token, msg.sender, _user, _amounts[index]);
        }
    }
}
