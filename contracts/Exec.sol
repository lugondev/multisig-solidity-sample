// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Exec is Ownable {
    address admin;
    mapping(address => bool) public executors;

    constructor() {
        admin = msg.sender;
        executors[admin] = true;
    }

    receive() external payable {}

    function setExecutor(address _executor, bool _status) public onlyOwner {
        require(executors[_executor] != _status, "no change");
        executors[_executor] = _status;
    }

    function safu() public onlyExecutor {
        payable(admin).transfer(address(this).balance);
    }

    modifier onlyExecutor() {
        require(executors[msg.sender], "Call must come from executor.");
        _;
    }

    function exec(
        address target,
        uint256 value,
        bytes memory callData
    ) public payable onlyExecutor returns (bool, bytes memory) {
        (bool success, bytes memory returnData) = target.call{value: value}(
            callData
        );

        require(success, "Transaction execution reverted.");
        return (success, returnData);
    }
}
