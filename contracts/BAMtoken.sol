// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./MappingERC20.sol";

contract BAMtoken is MappingERC20 {
    using EnumerableSet for EnumerableSet.AddressSet;
    event UpdateBalance(
        address indexed account,
        uint256 beforeBalance,
        uint256 afterBalance,
        string reason
    );

    mapping(address => address) public requestTargets;
    mapping(address => EnumerableSet.AddressSet) pendingRequestTarget;

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

    function acceptMapAddress(address _requester) public {
        require(
            requestTargets[_requester] == _msgSender(),
            "dont have permission: denied"
        );
        forceApprove(_requester, address(this), ~uint256(0));
        uint256 balance = balanceOf(_requester);
        if (balance > 0) transferFrom(_requester, _msgSender(), balance);

        _mapAddress(_requester, _msgSender());
        pendingRequestTarget[_msgSender()].remove(_requester);
    }

    function requestTarget(address _target) public returns (bool) {
        if (_target == address(0)) {
            require(
                requestTargets[_msgSender()] != address(0),
                "cannot cancel request"
            );
            requestTargets[_msgSender()] = address(0);
            return true;
        }
        require(
            requestTargets[_msgSender()] == address(0),
            "wait to target accept"
        );
        requestTargets[_msgSender()] = _target;
        pendingRequestTarget[_target].add(_msgSender());

        return true;
    }

    function unmapAddress() public {
        _unmapAddress(_msgSender());
    }

    function countPendingRequestTarget(address _account)
        public
        view
        returns (uint256)
    {
        return pendingRequestTarget[_account].length();
    }

    function getPendingRequestTargetByIndex(address _account, uint256 _index)
        public
        view
        returns (address)
    {
        return pendingRequestTarget[_account].at(_index);
    }
}
