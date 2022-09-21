// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IMasterOwners.sol";

abstract contract IMPCBridgeConverter is IMasterOwners {
    struct BridgePair {
        address srcToken;
        address dstToken;
        uint256 min;
        bool status;
    }
    struct BridgeData {
        address user;
        uint256 pairId;
        uint256 amount;
        bytes32 hash;
    }
    BridgePair[] public pairs;
    mapping(address => mapping(address => uint256)) public existsPairIds;
    mapping(address => bool) public srcTokens;
    mapping(address => bool) public dstTokens;

    mapping(bytes32 => bool) public releasedHashs;

    address public iam;
    bool public isOpenMpc;

    function initialize(address _iam) external virtual;

    function updateIAM(address _newIAM) external virtual;

    modifier isSrcToken(address _token) {
        require(srcTokens[_token], "not source token");
        _;
    }

    modifier isDstToken(address _token) {
        require(dstTokens[_token], "not destination token");
        _;
    }

    function currentBridgeId() external view virtual returns (uint256);

    function currentReleasedId() external view virtual returns (uint256);

    function convertBAM(uint256 _pairId, uint256 _amount) external virtual;

    function convertFrom(uint256 _pairId, uint256 _amount) external virtual;

    function createPair(
        address _srcToken,
        address _dstToken,
        uint256 _min
    ) external virtual;

    function updatePair(uint256 _pairId, bool _status) external virtual;

    function updateMinPair(uint256 _pairId, uint256 _min) external virtual;

    function updateStatusOpenMPC(bool _status) external virtual;

    function updateSrcToken(address _token, bool _status) external virtual;

    function updateDstToken(address _token, bool _status) external virtual;

    function getPairId(address _srcToken, address _dstToken)
        external
        view
        virtual
        returns (uint256);

    function isValidPair(address _srcToken, address _dstToken)
        external
        view
        virtual
        returns (bool);

    function getPairByIndex(uint256 _index)
        external
        view
        virtual
        returns (BridgePair memory);

    function totalPairs() external view virtual returns (uint256);

    function mpcRelease(
        address _user,
        address _srcToken,
        address _dstToken,
        uint256 _id,
        bytes32 _convertedHash,
        uint256 _amount,
        bytes memory _signature
    ) external virtual;

    function burn(address _token, uint256 _amount) external virtual;

    function safu(address _token, address _to) external virtual;

    function safuNative(address _to) external virtual;

    function getBridge(uint256 _id)
        external
        view
        virtual
        returns (BridgeData memory);

    function isReleased(bytes32 _hash) external view virtual returns (bool);
}
