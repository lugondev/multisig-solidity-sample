// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./BToken.sol";

contract BamUSD is BToken {
    event UpdateBridge(address indexed account, bool status);
    event Bridge(address indexed from, address indexed to, uint256 amount);

    mapping(address => bool) public bridges;

    function initialize(
        string memory _name,
        string memory _symbol,
        address _iam
    ) public initializer {
        __BToken_init(_name, _symbol, _iam);
    }

    modifier onlyBridge() {
        require(bridges[msg.sender], "you are not a bridge");
        _;
    }

    function bridge(
        address _user,
        address _to,
        uint256 _amount
    ) public onlyBridge {
        _forceTransfer(_user, _to, _amount);

        emit Bridge(_user, _to, _amount);
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
