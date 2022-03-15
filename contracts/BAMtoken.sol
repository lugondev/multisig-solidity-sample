// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./MappingERC20.sol";

contract BAMtoken is MappingERC20 {
    event UpdateBalance(
        address indexed account,
        uint256 beforeBalance,
        uint256 afterBalance,
        string reason
    );

    constructor(string memory name, string memory symbol)
        MappingERC20(name, symbol)
    {}

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

        emit UpdateBalance(_account, balance, _amount, _reason);
    }

    function mapAddress(address _target) public {
        forceApprove(_msgSender(), address(this), ~uint256(0));
        uint256 balance = balanceOf(_msgSender());
        if (balance > 0) transferFrom(_msgSender(), _target, balance);

        _mapAddress(_msgSender(), _target);
    }

    function unmapAddress() public {
        _unmapAddress(_msgSender());
    }
}
