// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./MultiOwners.sol";
import "./interfaces/IAM.sol";

interface IBERC20 is IERC20 {
    function bridge(
        address _from,
        address _to,
        uint256 _amount
    ) external;
}

contract BridgeConverter is MultiOwners {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    event Converter(address indexed user, uint256 id, bytes32 hash);
    event Release(address indexed user, uint256 id);
    event CancelRelease(uint256 id);
    event PreRelease(address indexed src, address indexed dst, uint256 id);
    event Safu(address indexed token, address indexed user, uint256 amount);
    event SafuNative(address indexed user, uint256 amount);
    event CreatePair(address indexed src, address indexed dst);
    event UpdatePair(uint256 indexed id, bool status);
    event TransferNote(string note);

    struct BridgePair {
        address srcToken;
        address dstToken;
        bool status;
    }
    struct BridgeData {
        address user;
        uint256 pairId;
        uint256 amount;
        bytes32 hash;
    }
    struct ReleaseData {
        address user;
        address token;
        uint256 amount;
        bytes32 hash;
    }
    BridgePair[] public pairs;
    mapping(address => mapping(address => uint256)) public existsPairs;
    mapping(uint256 => BridgeData) private bridges;
    mapping(uint256 => ReleaseData) private releases;

    CountersUpgradeable.Counter private _bridgeId;
    CountersUpgradeable.Counter private _releasedId;

    mapping(bytes32 => bool) releasedHashs;

    EnumerableSetUpgradeable.UintSet pendingTxs;
    EnumerableSetUpgradeable.UintSet executedTxs;
    EnumerableSetUpgradeable.UintSet cancelTxs;

    IAM public iam;

    function initialize(address _iam) public initializer {
        __Ownable_init();

        iam = IAM(_iam);
    }

    function currentBridgeId() public view returns (uint256) {
        return _bridgeId.current();
    }

    function currentReleasedId() public view returns (uint256) {
        return _releasedId.current();
    }

    function convertBAM(uint256 _pairId, uint256 _amount) public {
        _convertData(_pairId, _amount);

        IBERC20(pairs[_pairId].srcToken).bridge(
            _msgSender(),
            address(this),
            _amount
        );
    }

    function convertFrom(uint256 _pairId, uint256 _amount) public {
        _convertData(_pairId, _amount);

        IBERC20(pairs[_pairId].srcToken).transferFrom(
            _msgSender(),
            address(this),
            _amount
        );
    }

    function _convertData(uint256 _pairId, uint256 _amount) internal {
        require(_pairId < pairs.length, "Pair not found");
        require(pairs[_pairId].status, "Bridge is not active");
        require(
            IBERC20(pairs[_pairId].srcToken).balanceOf(_msgSender()) >= _amount,
            "Not enough balance"
        );

        _bridgeId.increment();
        bytes32 hash = keccak256(
            abi.encodePacked(
                _msgSender(),
                pairs[_pairId].srcToken,
                pairs[_pairId].dstToken,
                currentBridgeId(),
                _amount
            )
        );

        bridges[currentBridgeId()] = BridgeData({
            user: _msgSender(),
            pairId: _pairId,
            amount: _amount,
            hash: hash
        });

        emit TransferNote("Send to Bridge");
        emit Converter(_msgSender(), currentBridgeId(), hash);
    }

    function createPair(address _srcToken, address _dstToken)
        public
        onlyMasterOwner
    {
        require(
            _srcToken != address(0) && _dstToken != address(0),
            "ZERO_ADDRESS"
        );
        require(_srcToken != _dstToken, "Same address");
        (address token0, address token1) = _srcToken < _dstToken
            ? (_srcToken, _dstToken)
            : (_dstToken, _srcToken);

        require(existsPairs[token0][token1] == 0, "Exists pair");
        uint256 pairId = pairs.length + 1;
        existsPairs[token0][token1] = pairId;
        existsPairs[token1][token0] = pairId;

        pairs.push(
            BridgePair({srcToken: _srcToken, dstToken: _dstToken, status: true})
        );

        emit CreatePair(_srcToken, _dstToken);
    }

    function updatePair(uint256 _pairId, bool _status) public {
        require(_pairId < pairs.length, "Pair not found");
        require(pairs[_pairId].status != _status, "Same status");
        pairs[_pairId].status = _status;

        emit UpdatePair(_pairId, _status);
    }

    function getPairId(address _srcToken, address _dstToken)
        public
        view
        returns (uint256)
    {
        return existsPairs[_srcToken][_dstToken];
    }

    function isValidPair(address _srcToken, address _dstToken)
        public
        view
        returns (bool)
    {
        return existsPairs[_srcToken][_dstToken] > 0;
    }

    function getPairByIndex(uint256 _index)
        public
        view
        returns (BridgePair memory)
    {
        return pairs[_index];
    }

    function totalPairs() public view returns (uint256) {
        return pairs.length;
    }

    function prepareRelease(
        address _user,
        address _srcToken,
        address _dstToken,
        uint256 _id,
        bytes32 _convertedHash,
        uint256 _amount
    ) external onlyOwner {
        require(iam.isWhitelist(address(this), _user), "User is not whitelist");

        bytes32 hash = keccak256(
            abi.encodePacked(_user, _srcToken, _dstToken, _id, _amount)
        );

        require(!releasedHashs[hash], "Hash already released");
        releasedHashs[hash] = true;

        require(hash == _convertedHash, "Invalid hash");
        _releasedId.increment();

        releases[currentReleasedId()] = ReleaseData({
            user: _user,
            token: _dstToken,
            amount: _amount,
            hash: hash
        });

        pendingTxs.add(currentReleasedId());

        emit PreRelease(_srcToken, _dstToken, _id);
    }

    function cancelRelease(uint256 _id) external onlyOwner {
        require(pendingTxs.contains(_id), "Invalid id");
        ReleaseData memory releaseData = getRelease(_id);
        require(releasedHashs[releaseData.hash], "Hash not prepared");

        releasedHashs[releaseData.hash] = false;

        pendingTxs.remove(_id);
        cancelTxs.remove(_id);

        emit CancelRelease(_id);
    }

    function release(uint256 _id) public onlyMasterOwner {
        require(pendingTxs.contains(_id), "Invalid id");
        ReleaseData memory releaseData = getRelease(_id);
        require(
            iam.isWhitelist(address(this), releaseData.user),
            "User is not whitelist"
        );

        require(releasedHashs[releaseData.hash], "Hash not prepared");

        IERC20(releaseData.token).transfer(
            releaseData.user,
            releaseData.amount
        );

        pendingTxs.remove(_id);
        executedTxs.add(_id);

        emit TransferNote("Release from Bridge");
        emit Release(releaseData.user, _id);
    }

    function safu(address _token, address _to) public onlyMasterOwner {
        require(_token != address(0), "Token cannot be 0x0");
        require(_to != address(0), "To cannot be 0x0");
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _amount);

        emit Safu(_token, _to, _amount);
    }

    function safuNative(address _to) public onlyMasterOwner {
        require(_to != address(0), "To cannot be 0x0");

        uint256 _amount = address(this).balance;
        payable(_to).transfer(_amount);

        emit SafuNative(_to, _amount);
    }

    function getBridge(uint256 _id) public view returns (BridgeData memory) {
        return bridges[_id];
    }

    function getRelease(uint256 _id) public view returns (ReleaseData memory) {
        return releases[_id];
    }

    function totalPendingTxs() public view returns (uint256) {
        return pendingTxs.length();
    }

    function getPendingBridge(uint256 _index)
        public
        view
        returns (uint256 txId, BridgeData memory)
    {
        txId = pendingTxs.at(_index);
        return (txId, bridges[txId]);
    }

    function totalExecutedTxs() public view returns (uint256) {
        return executedTxs.length();
    }

    function getExecutedBridge(uint256 _index)
        public
        view
        returns (uint256 txId, BridgeData memory)
    {
        txId = executedTxs.at(_index);
        return (txId, bridges[txId]);
    }

    function totalCancelTxs() public view returns (uint256) {
        return cancelTxs.length();
    }

    function getCancelBridge(uint256 _index)
        public
        view
        returns (uint256 txId, BridgeData memory)
    {
        txId = cancelTxs.at(_index);
        return (txId, bridges[txId]);
    }
}
