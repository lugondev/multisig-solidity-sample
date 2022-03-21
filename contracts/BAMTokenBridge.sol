// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./MERC20.sol";
import "./interfaces/IBamMERC20.sol";

abstract contract BAMPublicMERC20 is MERC20 {
    IBamMERC20 merc20;

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
        require(
            _amount >= balanceOf(_msgSender()),
            "bridge amount exceeds balance"
        );

        _burn(_msgSender(), _amount);
        merc20.bridgeIn(mappedAddress(_msgSender()), _amount);
    }
}
