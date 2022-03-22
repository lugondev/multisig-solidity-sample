// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./MERC20.sol";
import "./interfaces/IBamMERC20.sol";

abstract contract BAMPublicMERC20 is MERC20 {
    event BridgeOut(address indexed account, bytes32 id, uint256 amount);
    event CancelBridge(address indexed account, bytes32 id);
    event ApproveBridge(address indexed account, bytes32 id);
    struct BridgeInfo {
        address account;
        uint256 amount;
        bool done;
    }

    mapping(address => uint256) nonces;
    mapping(bytes32 => BridgeInfo) public bridgeInfos;

    IBamMERC20 public merc20;

    constructor(IBamMERC20 _merc20) MERC20(merc20.name(), _merc20.symbol()) {
        merc20 = _merc20;
    }

    modifier onlyPrivMerc20() {
        require(
            _msgSender() == address(merc20),
            "caller is not Private MERC20"
        );
        _;
    }

    function isMainMERC20(address _merc20) public view returns (bool) {
        return _merc20 == address(merc20);
    }

    function bridgeIn(address _address, uint256 _amount) public onlyPrivMerc20 {
        _mint(_address, _amount);
    }

    function bridgeOut(uint256 _amount) public {
        require(_amount > 0, "amount must be greater than 0");
        require(
            _amount > balanceOf(_msgSender()),
            "bridge amount exceeds balance"
        );

        forceTransfer(_msgSender(), address(this), _amount);
        BridgeInfo memory data = BridgeInfo({
            account: _msgSender(),
            amount: _amount,
            done: false
        });

        bytes32 id = _generateId(_msgSender(), _amount, nonces[_msgSender()]);
        bridgeInfos[id] = data;
        nonces[_msgSender()]++;

        emit BridgeOut(_msgSender(), id, _amount);
    }

    function cancelBridge(bytes32 _id) public {
        BridgeInfo memory data = bridgeInfos[_id];
        require(
            data.account == _msgSender(),
            "caller is not owner bridge data"
        );
        require(!data.done, "data is approved");

        delete bridgeInfos[_id];
        transfer(address(this), data.amount);

        emit CancelBridge(_msgSender(), _id);
    }

    function approveBridge(address _account, bytes32 _id)
        external
        onlyPrivMerc20
    {
        BridgeInfo memory data = bridgeInfos[_id];
        require(data.account == _account, "caller is not owner bridge data");
        require(!data.done, "data is approved");

        bridgeInfos[_id].done = true;
        _burn(address(this), data.amount);

        emit ApproveBridge(_msgSender(), _id);
    }

    function getBridgeOwner(bytes32 _id) public view returns (address) {
        return bridgeInfos[_id].account;
    }

    function getBridgeAmount(bytes32 _id) public view returns (uint256) {
        return bridgeInfos[_id].amount;
    }

    function isPendingBridge(bytes32 _id) public view returns (bool) {
        return !bridgeInfos[_id].done;
    }

    function _generateId(
        address _account,
        uint256 _amount,
        uint256 _nonce
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _amount, _nonce));
    }
}
