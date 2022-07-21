// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./BERC20Snapshot.sol";
import "./interfaces/IAM.sol";
import "./interfaces/IBridgeConverter.sol";
import "./interfaces/IMigration.sol";

contract BamUSD is BERC20Snapshot {
    event Migration(address indexed account, uint256 amount);
    event UpdateBridge(address indexed account, bool status);
    event Bridge(address indexed from, address indexed to, uint256 amount);

    IAM public iam;
    IMigration public migration;
    mapping(address => bool) public migrated;
    mapping(address => bool) public bridges;

    function initialize(
        string memory _name,
        string memory _symbol,
        address _iam
    ) public initializer {
        __BERC20_init(_name, _symbol);

        iam = IAM(_iam);
    }

    modifier rejectBlacklist() {
        require(
            !iam.isBlacklist(address(this), msg.sender),
            "you are in blacklist"
        );
        _;
    }

    modifier onlyBridge() {
        require(bridges[msg.sender], "you are not a bridge");
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override rejectBlacklist whenNotPaused {
        require(address(migration) == address(0), "time to migrate");
        super._beforeTokenTransfer(from, to, amount);
    }

    function updateIAM(address _iam) public onlyOwner {
        iam = IAM(_iam);
    }

    function mint(address _address, uint256 _amount) public onlyOwner {
        _mint(_address, _amount);
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function burn(uint256 _amount) public {
        _burn(_msgSender(), _amount);
    }

    function bridge(
        address _user,
        address _to,
        uint256 _amount
    ) public onlyBridge {
        _forceTransfer(_user, _to, _amount);

        emit Bridge(_user, _to, _amount);
    }

    function getCurrentSnapshotId() public view returns (uint256) {
        return _getCurrentSnapshotId();
    }

    function setMigration(address _migration) public onlyOwner {
        require(_migration != address(0), "invalid address");
        require(address(migration) != address(0), "only migrate once time");
        migration = IMigration(_migration);
    }

    function migrate(uint256 _amount) public {
        require(address(migration) != address(0), "not time to migrate");
        require(!migrated[_msgSender()], "you migrated");

        migrated[_msgSender()] = true;
        migration.migrate(_msgSender(), _amount);

        emit Migration(_msgSender(), _amount);
    }

    function addBridge(address _bridge) public onlyOwner {
        require(!bridges[_bridge], "bridge is added");
        bridges[_bridge] = true;

        emit UpdateBridge(_bridge, true);
    }

    function removeBridge(address _bridge) public onlyMasterOwner {
        require(bridges[_bridge], "not bridge address");

        bridges[_bridge] = false;

        emit UpdateBridge(_bridge, false);
    }
}