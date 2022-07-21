// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./BERC20Snapshot.sol";
import "./interfaces/IAM.sol";
import "./interfaces/IBridgeConverter.sol";
import "./interfaces/IMigration.sol";

contract BToken is BERC20Snapshot {
    event Migration(address indexed account, uint256 amount);
    event UpdateMigration(address indexed _migration);

    IAM public iam;
    IMigration public migration;
    mapping(address => bool) public migrated;

    function __BToken_init(
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override rejectBlacklist whenNotPaused {
        require(!migrated[from] && !migrated[to], "migrated");

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

    function getCurrentSnapshotId() public view returns (uint256) {
        return _getCurrentSnapshotId();
    }

    function setMigration(address _migration) public onlyOwner {
        require(_migration != address(0), "invalid address");
        require(address(migration) != address(0), "only migrate once time");
        migration = IMigration(_migration);

        emit UpdateMigration(_migration);
    }

    function migrate() public {
        require(address(migration) != address(0), "not time to migrate");
        require(!migrated[_msgSender()], "you migrated");

        uint256 _amount = balanceOf(_msgSender());

        migrated[_msgSender()] = true;
        migration.migrate(_msgSender(), _amount);

        emit Migration(_msgSender(), _amount);
    }
}
