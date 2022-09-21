// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./MultiOwners.sol";
import "./interfaces/IAM.sol";
import "./interfaces/IBERC20.sol";
import "./interfaces/IBurnERC20.sol";

contract MPCBridgeConverter is MultiOwners {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    event Converter(
        address indexed user,
        uint256 id,
        uint256 amount,
        bytes32 hash
    );
    event MPCRelease(address indexed user, uint256 amount, bytes32 hash);
    event Safu(address indexed token, address indexed user, uint256 amount);
    event SafuNative(address indexed user, uint256 amount);
    event CreatePair(address indexed src, address indexed dst);
    event UpdatePair(uint256 indexed id, bool status);
    event UpdateMinPair(uint256 indexed id, uint256 min);
    event UpdateOpenMpc(bool status);
    event UpdateSigner(address indexed signer, bool status);
    event TransferNote(string note);
    event UpdateIAM(address newIAM);

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
    mapping(uint256 => BridgeData) private bridges;
    mapping(address => bool) public srcTokens;
    mapping(address => bool) public dstTokens;

    CountersUpgradeable.Counter private _bridgeId;
    CountersUpgradeable.Counter private _releasedId;

    mapping(bytes32 => bool) public releasedHashs;

    IAM public iam;
    bool public isOpenMpc;

    function initialize(address _iam) public initializer {
        __Ownable_init();

        iam = IAM(_iam);
        isOpenMpc = true;
    }

    modifier isMpcReleaser() {
        if (!isOpenMpc) {
            require(isOwner(_msgSender()), "BridgeConverter: not mpc releaser");
        }
        _;
    }

    function updateIAM(address _newIAM) public onlyMasterOwner {
        require(_newIAM != address(0), "ZERO_ADDRESS");

        iam = IAM(_newIAM);

        emit UpdateIAM(_newIAM);
    }

    modifier isSrcToken(address _token) {
        require(srcTokens[_token], "not source token");
        _;
    }

    modifier isDstToken(address _token) {
        require(dstTokens[_token], "not destination token");
        _;
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
            _amount >= pairs[_pairId].min,
            "Amount is less than min amount"
        );
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
        emit Converter(_msgSender(), currentBridgeId(), _amount, hash);
    }

    function createPair(
        address _srcToken,
        address _dstToken,
        uint256 _min
    ) public onlyMasterOwner {
        require(
            _srcToken != address(0) && _dstToken != address(0),
            "ZERO_ADDRESS"
        );
        require(_srcToken != _dstToken, "Same address");
        (address token0, address token1) = _srcToken < _dstToken
            ? (_srcToken, _dstToken)
            : (_dstToken, _srcToken);

        require(existsPairIds[token0][token1] == 0, "Exists pair");
        uint256 pairId = pairs.length + 1;
        existsPairIds[token0][token1] = pairId;
        existsPairIds[token1][token0] = pairId;

        pairs.push(
            BridgePair({
                srcToken: _srcToken,
                dstToken: _dstToken,
                min: _min,
                status: true
            })
        );
        dstTokens[_dstToken] = true;
        srcTokens[_srcToken] = true;

        emit CreatePair(_srcToken, _dstToken);
    }

    function updatePair(uint256 _pairId, bool _status) public onlyMasterOwner {
        require(_pairId < pairs.length, "Pair not found");
        BridgePair storage pair = pairs[_pairId];
        require(pair.status != _status, "Same status");
        pair.status = _status;
        if (_status) {
            dstTokens[pair.dstToken] = true;
            srcTokens[pair.srcToken] = true;
        } else {
            dstTokens[pair.dstToken] = false;
            srcTokens[pair.srcToken] = false;
        }

        emit UpdatePair(_pairId, _status);
    }

    function updateMinPair(uint256 _pairId, uint256 _min)
        public
        onlyMasterOwner
    {
        require(_pairId < pairs.length, "Pair not found");
        BridgePair storage pair = pairs[_pairId];
        require(pair.status, "Bridge is not active");
        pair.min = _min;

        emit UpdateMinPair(_pairId, _min);
    }

    function updateStatusOpenMPC(bool _status) public onlyMasterOwner {
        require(_status != isOpenMpc, "Same status");
        isOpenMpc = _status;

        emit UpdateOpenMpc(_status);
    }

    function updateSrcToken(address _token, bool _status)
        public
        onlyMasterOwner
    {
        require(_token != address(0), "ZERO_ADDRESS");

        require(_status != srcTokens[_token], "Same status");
        srcTokens[_token] = _status;
    }

    function updateDstToken(address _token, bool _status)
        public
        onlyMasterOwner
    {
        require(_token != address(0), "ZERO_ADDRESS");

        require(_status != dstTokens[_token], "Same status");
        srcTokens[_token] = _status;
    }

    function getPairId(address _srcToken, address _dstToken)
        public
        view
        returns (uint256)
    {
        return existsPairIds[_srcToken][_dstToken];
    }

    function isValidPair(address _srcToken, address _dstToken)
        public
        view
        returns (bool)
    {
        return existsPairIds[_srcToken][_dstToken] > 0;
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

    function mpcRelease(
        address _user,
        address _srcToken,
        address _dstToken,
        uint256 _id,
        bytes32 _convertedHash,
        uint256 _amount,
        bytes memory _signature
    ) external isMpcReleaser isSrcToken(_srcToken) isDstToken(_dstToken) {
        require(iam.isWhitelist(address(this), _user), "User is not whitelist");

        bytes32 hash = keccak256(
            abi.encodePacked(_user, _srcToken, _dstToken, _id, _amount)
        );
        require(hash == _convertedHash, "Invalid hash");

        require(!releasedHashs[hash], "Hash already released");
        releasedHashs[hash] = true;

        address signer = getSigner(hash, _signature);
        require(isOwner(signer), "Invalid MPC's signature");

        IERC20(_dstToken).transfer(_user, _amount);

        emit MPCRelease(_user, _amount, hash);
    }

    function burn(address _token, uint256 _amount)
        public
        onlyMasterOwner
        isSrcToken(_token)
        isDstToken(_token)
    {
        require(_token != address(0), "ZERO_ADDRESS");
        IBurnERC20 token = IBurnERC20(_token);
        require(
            _amount > 0 && _amount <= token.balanceOf(address(this)),
            "Invalid amount"
        );

        token.burn(_amount);
    }

    function safu(address _token, address _to) public onlyMasterOwner {
        require(_token != address(0), "ZERO_ADDRESS");
        require(_to != address(0), "ZERO_ADDRESS");
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _amount);

        emit Safu(_token, _to, _amount);
    }

    function safuNative(address _to) public onlyMasterOwner {
        require(_to != address(0), "ZERO_ADDRESS");

        uint256 _amount = address(this).balance;
        payable(_to).transfer(_amount);

        emit SafuNative(_to, _amount);
    }

    function getBridge(uint256 _id) public view returns (BridgeData memory) {
        return bridges[_id];
    }

    function isReleased(bytes32 _hash) public view returns (bool) {
        return releasedHashs[_hash];
    }

    function getSigner(bytes32 _signedMessageHash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(_signedMessageHash, v, r, s);
        }
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}