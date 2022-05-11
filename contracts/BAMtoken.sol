// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./MERC20Snapshot.sol";
import "./interfaces/IAM.sol";
import "./interfaces/IBridgeMERC20.sol";

contract BAMtoken is MERC20Snapshot {
    event UpdateBalance(
        address indexed account,
        uint256 beforeBalance,
        uint256 afterBalance,
        string reason
    );
    event BridgeOut(address indexed account, uint256 amount);
    event BridgeIn(address indexed account, uint256 amount);

    IAM public iam;
    address public lockBridge;
    mapping(IBridgeMERC20 => bool) public bridgeTokens;

    function initialize(
        string memory _name,
        string memory _symbol,
        address _iam
    ) public initializer {
        __MERC20_init(_name, _symbol);
        lockBridge = bytesToAddress("bridge");
        _approve(lockBridge, address(this), ~uint256(0));

        iam = IAM(_iam);
    }

    modifier onlyBridgeToken() {
        require(
            bridgeTokens[IBridgeMERC20(_msgSender())],
            "caller is not bridge token "
        );
        _;
    }

    modifier onlyWhitelist() {
        require(
            iam.whitelists(address(this), msg.sender),
            "only accept whitelist"
        );
        _;
    }

    modifier rejectBlacklist() {
        require(
            !iam.blacklists(address(this), msg.sender),
            "you are in blacklist"
        );
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override onlyWhitelist rejectBlacklist {
        super._beforeTokenTransfer(from, to, amount);
    }

    function mint(address _address, uint256 _amount) public override {
        _mint(_address, _amount);
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function burn(uint256 _amount) public override {
        _burn(_msgSender(), _amount);
    }

    function updateBalance(
        address _account,
        uint256 _amount,
        string memory _reason
    ) public onlyOwner {
        uint256 balance = balanceOf(_account);
        require(balance != _amount, "amount is equal current balance");
        if (_amount > balance) {
            _mint(_account, _amount - balance);
        } else {
            _burn(_account, balance - _amount);
        }

        emit UpdateBalance(getMappedAddress(_account), balance, _amount, _reason);
    }

    function bridgeOut(IBridgeMERC20 _bridgeToken, uint256 _amount) public {
        require(_amount > 0, "amount must be greater than 0");
        require(
            _amount >= balanceOf(_msgSender()),
            "bridge amount exceeds balance"
        );

        forceTransfer(_msgSender(), lockBridge, _amount);
        _bridgeToken.bridgeIn(getMappedAddress(_msgSender()), _amount);

        emit BridgeOut(getMappedAddress(_msgSender()), _amount);
    }

    function bridgeIn(IBridgeMERC20 _bridgeToken, bytes32 _id) public {
        address account = _bridgeToken.getBridgeOwner(_id);

        require(_msgSender() == account, "invalid caller");
        require(
            _bridgeToken.isPendingBridge(_id),
            "invalid id bridge"
        );

        uint256 amount = _bridgeToken.getBridgeAmount(_id);
        _bridgeToken.approveBridge(account, _id);
        forceTransfer(lockBridge, account, amount);

        emit BridgeIn(getMappedAddress(_msgSender()), amount);
    }

    function addBridge(IBridgeMERC20 _bridge) public onlyOwner returns (bool) {
        require(!bridgeTokens[_bridge], "bridge is added");
        require(_bridge.isMainMERC20(address(this)), "invalid bridge");
        bridgeTokens[_bridge] = true;

        return true;
    }

    function removeBridge(IBridgeMERC20 _bridge)
        public
        onlyOwner
        returns (bool)
    {
        require(bridgeTokens[_bridge], "not bridge address");

        bridgeTokens[_bridge] = false;

        return true;
    }

    function bytesToAddress(string memory _name)
        private
        pure
        returns (address addr)
    {
        bytes memory data = bytes(_name);
        assembly {
            addr := mload(add(data, 20))
        }
    }

    function getCurrentSnapshotId() public view returns (uint256) {
        return _getCurrentSnapshotId();
    }

    function privTransfer(address recipient, uint256 amount)
        public
        returns (bool)
    {
        return transfer(recipient, amount);
    }
}
