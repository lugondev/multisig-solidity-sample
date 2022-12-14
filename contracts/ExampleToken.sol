// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ExampleToken is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public initialSupply = 10**9 * 10**18;

    constructor(string memory name_, string memory symbol_) ERC20(name_,symbol_) {
        _mint(_msgSender(), initialSupply);
    }

    function mint(uint256 _amount) external {
        _mint(_msgSender(), _amount);
    }
}
