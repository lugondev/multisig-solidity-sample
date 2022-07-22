// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract AccountManagement is Initializable, AccessControlUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event BlackListUser(address indexed target, address user, bool status);
    event WhiteListUser(address indexed target, address user, bool status);
    event BlackListStatus(address indexed target, bool status);
    event WhiteListStatus(address indexed target, bool status);

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MANAGER = keccak256("MANAGER");

    mapping(address => EnumerableSetUpgradeable.AddressSet) blacklists;
    mapping(address => EnumerableSetUpgradeable.AddressSet) whitelists;
    mapping(address => bool) public isDisableWhitelists;
    mapping(address => bool) public isDisableBlacklists;

    function init() public initializer {
        _setRoleAdmin(ADMIN, ADMIN);
        _setRoleAdmin(MANAGER, ADMIN);
        _setupRole(ADMIN, _msgSender());
    }

    modifier onlyManager() {
        require(
            hasRole(MANAGER, _msgSender()) || hasRole(ADMIN, _msgSender()),
            "Only manager can do action"
        );
        _;
    }

    function isBlacklist(address _target, address _user)
        public
        view
        returns (bool)
    {
        if (isDisableBlacklists[_target]) return false;

        return blacklists[_target].contains(_user);
    }

    function isWhitelist(address _target, address _user)
        public
        view
        returns (bool)
    {
        if (isDisableWhitelists[_target]) return true;

        return whitelists[_target].contains(_user);
    }

    function _updateWBlist(
        bool _isBlacklist,
        address _target,
        address _user,
        bool _status
    ) internal {
        if (_isBlacklist) {
            if (_status) {
                blacklists[_target].add(_user);
            } else {
                blacklists[_target].remove(_user);
            }
            emit BlackListUser(_target, _user, _status);
        } else {
            if (_status) {
                whitelists[_target].add(_user);
            } else {
                whitelists[_target].remove(_user);
            }
            emit WhiteListUser(_target, _user, _status);
        }
    }

    function updateWhitelists(
        address _target,
        address[] calldata _users,
        bool _status
    ) public onlyManager {
        for (uint256 index = 0; index < _users.length; index++) {
            _updateWBlist(false, _target, _users[index], _status);
        }
    }

    function setDisableWhitelist(address _target, bool _status)
        public
        onlyManager
    {
        isDisableWhitelists[_target] = _status;

        emit WhiteListStatus(_target, _status);
    }

    function setDisableBlacklists(address _target, bool _status)
        public
        onlyManager
    {
        isDisableBlacklists[_target] = _status;

        emit BlackListStatus(_target, _status);
    }

    function updateBlacklists(
        address _target,
        address[] calldata _users,
        bool _status
    ) public onlyManager {
        for (uint256 index = 0; index < _users.length; index++) {
            _updateWBlist(true, _target, _users[index], _status);
        }
    }

    function totalWhitelists(address _target) public view returns (uint256) {
        return whitelists[_target].length();
    }

    function totalBlacklists(address _target) public view returns (uint256) {
        return blacklists[_target].length();
    }

    function getBlacklistsByIndex(address _target, uint256 _index)
        public
        view
        returns (address)
    {
        return blacklists[_target].at(_index);
    }

    function getWhitelistsByIndex(address _target, uint256 _index)
        public
        view
        returns (address)
    {
        return whitelists[_target].at(_index);
    }
}
