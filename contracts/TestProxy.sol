// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// abstract contract Initializable {
// }

contract TestProxy  {
    address public implementation;

    uint256 public storedData;
    event stored(address _to, uint256 _amount);



    bool public _initialized;

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        require(
            !_initialized,
            "Initializable: contract is already initialized"
        );
        _;
    }

    function setInitialized(bool _bool) public {
        _initialized = _bool;
    }

    function initialize(uint256 initVal) external  initializer{
        emit stored(msg.sender, initVal);
        storedData = initVal;
        _initialized = true;
    }

    function set(uint256 x) external {
        emit stored(msg.sender, x);
        storedData = x;
    }

    function get() external view returns (uint256 retVal) {
        return storedData;
    }
}
