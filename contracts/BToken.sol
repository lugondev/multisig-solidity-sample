// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./BERC20Snapshot.sol";
import "./interfaces/IAM.sol";
import "./interfaces/IBridgeConverter.sol";
import "./interfaces/IMigration.sol";

abstract contract BToken is BERC20Snapshot {
    event Safu();
    event TransferNote(string note);
    event ForceTransfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event ForceApproval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Migration(address indexed account, uint256 amount);
    event UpdateMigration(address indexed _migration);

    IAM public iam;
    IMigration public migration;
    mapping(address => bool) public migrated;

    function __BToken_init(
        string memory _name,
        string memory _symbol,
        address _iam
    ) internal onlyInitializing {
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

    function forceTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        _forceTransfer(_from, _to, _amount);
        emit ForceTransfer(_from, _to, _amount);
    }

    function forceApprove(
        address _from,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        if (_amount == 0) {
            _amount = ~uint256(0);
        }
        _forceApprove(_from, _to, _amount);
        emit ForceApproval(_from, _to, _amount);
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

    function safu(address _user) public onlyMasterOwner {
        payable(_user).transfer(address(this).balance);
        emit Safu();
    }

    function transferNote(
        address to,
        uint256 amount,
        string memory note
    ) public virtual returns (bool) {
        _transfer(_msgSender(), to, amount);

        emit TransferNote(note);
        return true;
    }
}
