// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./MERC20.sol";
import "./interfaces/IBridgeMERC20.sol";

abstract contract BAMtoken is MERC20 {
    event UpdateBalance(
        address indexed account,
        uint256 beforeBalance,
        uint256 afterBalance,
        string reason
    );
    event BridgeOut(address indexed account, uint256 amount);
    event BridgeIn(address indexed account, uint256 amount);

    address public lockBridge;
    mapping(IBridgeMERC20 => bool) public bridgeTokens;

    constructor(string memory name, string memory symbol) MERC20(name, symbol) {
        lockBridge = bytesToAddress("bridge");
        _approve(lockBridge, address(this), ~uint256(0));
    }

    modifier onlyBridgeToken() {
        require(
            bridgeTokens[IBridgeMERC20(_msgSender())],
            "caller is not bridge token "
        );
        _;
    }

    function mint(address _address, uint256 _amount) public onlyOwner {
        _mint(_address, _amount);
    }

    function burn(uint256 _amount) public {
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

        emit UpdateBalance(mappedAddress(_account), balance, _amount, _reason);
    }

    function bridgeOut(IBridgeMERC20 _bridgeToken, uint256 _amount) public {
        require(
            _amount >= balanceOf(_msgSender()),
            "bridge amount exceeds balance"
        );

        forceTransfer(_msgSender(), lockBridge, _amount);
        _bridgeToken.bridgeIn(mappedAddress(_msgSender()), _amount);

        emit BridgeOut(mappedAddress(_msgSender()), _amount);
    }

    function bridgeIn(address _account, uint256 _amount)
        public
        onlyBridgeToken
    {
        _mint(_account, _amount);

        emit BridgeIn(mappedAddress(_msgSender()), _amount);
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
}
