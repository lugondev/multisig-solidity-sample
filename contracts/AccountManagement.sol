// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract AccountManagement is Initializable, AccessControlUpgradeable {
    event BlackList(address indexed token, address user, bool status);
    event WhiteList(address indexed token, address user, bool status);

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MANAGER = keccak256("MANAGER");

    mapping(address => mapping(address => bool)) public blacklists;
    mapping(address => mapping(address => bool)) public whitelists;

    function init() public initializer {
        __AccessControl_init();

        _setRoleAdmin(ADMIN, ADMIN);
        _setRoleAdmin(MANAGER, ADMIN);
        _setupRole(ADMIN, _msgSender());
        _setupRole(MANAGER, _msgSender());
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN, _msgSender()), "Only admin can do action");
        _;
    }

    modifier onlyManager() {
        require(
            hasRole(MANAGER, _msgSender()) || hasRole(ADMIN, _msgSender()),
            "Only manager can do action"
        );
        _;
    }

    function isBlacklist(address _token, address _user)
        public
        view
        returns (bool)
    {
        return blacklists[_token][_user];
    }

    function isWhitelist(address _token, address _user)
        public
        view
        returns (bool)
    {
        return whitelists[_token][_user];
    }

    function _updateWBlist(
        bool _isBlacklist,
        address _token,
        address _user,
        bool _status
    ) internal {
        if (_isBlacklist) {
            blacklists[_token][_user] = _status;
            emit BlackList(_token, _user, _status);
        } else {
            whitelists[_token][_user] = _status;
            emit WhiteList(_token, _user, _status);
        }
    }

    function updateWhitelists(
        address _token,
        address[] calldata _users,
        bool _status
    ) public onlyManager {
        for (uint256 index = 0; index < _users.length; index++) {
            _updateWBlist(false, _token, _users[index], _status);
        }
    }

    function updateBlacklists(
        address _token,
        address[] calldata _users,
        bool _status
    ) public onlyManager {
        for (uint256 index = 0; index < _users.length; index++) {
            _updateWBlist(true, _token, _users[index], _status);
        }
    }
}
