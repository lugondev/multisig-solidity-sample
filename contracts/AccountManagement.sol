// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract AccountManagement is Initializable, AccessControlUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event BlackList(address indexed token, address user, bool status);
    event WhiteList(address indexed token, address user, bool status);

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MANAGER = keccak256("MANAGER");

    mapping(address => EnumerableSetUpgradeable.AddressSet) blacklists;
    mapping(address => EnumerableSetUpgradeable.AddressSet) whitelists;

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
        return blacklists[_token].contains(_user);
    }

    function isWhitelist(address _token, address _user)
        public
        view
        returns (bool)
    {
        return whitelists[_token].contains(_user);
    }

    function _updateWBlist(
        bool _isBlacklist,
        address _token,
        address _user,
        bool _status
    ) internal {
        if (_isBlacklist) {
            if (_status) {
                blacklists[_token].add(_user);
            } else {
                blacklists[_token].remove(_user);
            }
            emit BlackList(_token, _user, _status);
        } else {
            if (_status) {
                whitelists[_token].add(_user);
            } else {
                whitelists[_token].remove(_user);
            }
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

    function totalWhitelists(address _token) public view returns (uint256) {
        return whitelists[_token].length();
    }

    function totalBlacklists(address _token) public view returns (uint256) {
        return blacklists[_token].length();
    }

    function getBlacklistsByIndex(address _token, uint256 _index)
        public
        view
        returns (address)
    {
        return blacklists[_token].at(_index);
    }

    function getWhitelistsByIndex(address _token, uint256 _index)
        public
        view
        returns (address)
    {
        return whitelists[_token].at(_index);
    }
}