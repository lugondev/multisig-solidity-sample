// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBERC20 is IERC20 {
    function bridge(address _from,address _to, uint256 _amount) external;   
}

contract BridgeConverter {
    event Converter(address indexed user, uint256 amount);
    event Release(address indexed user, uint256 amount);
    event TransferOwnership(address indexed newOwner);
    event Safu(address indexed token, address indexed user, uint256 amount);

    IBERC20 public token;
    address public owner;
    mapping(bytes32 => bool) releasedHashs;

    constructor(IBERC20 _token) {
        token = _token;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can do action");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be 0x0");
        owner = _newOwner;

        emit TransferOwnership(_newOwner);
    }

    function convert(uint256 _amount) public {
        token.bridge(msg.sender, address(this), _amount);
        emit Converter(msg.sender, _amount);
    }

    function release(
        address _address,
        uint256 _amount,
        bytes32 _hash
    ) public onlyOwner {
        require(releasedHashs[_hash] == false, "Hash already released");
        releasedHashs[_hash] = true;
        token.transfer(_address, _amount);

        emit Release(_address, _amount);
    }

    function safu(
        address _token,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        require(_token != address(0), "Token cannot be 0x0");
        IERC20(_token).transfer(_to, _amount);

        emit Safu(_token, _to, _amount);
    }
}
