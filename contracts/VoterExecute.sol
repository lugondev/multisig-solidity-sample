// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VoterExecute is Initializable, AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;

    event ExecuteRequest(uint256 indexed _id);
    event NewRequest(uint256 indexed _id, address _target, bytes _data);
    event CancelRequest(uint256 indexed _id);
    event UpdateVoter(address indexed _account, bool _status);
    event UpdateWeight(uint256 _newWeight);

    EnumerableSet.AddressSet voters;
    Counters.Counter private _requestId;
    uint256 public weight;

    enum RequestStatus {
        PENDING,
        DONE,
        CANCEL
    }

    struct RequestData {
        address requester;
        address target;
        bytes data;
        RequestStatus status;
    }

    mapping(uint256 => RequestData) public requestDatas;

    bytes32 public constant ADMIN = keccak256("ADMIN");

    function _initialize() internal  {
        __AccessControl_init();

        _setRoleAdmin(ADMIN, ADMIN);
        _setupRole(ADMIN, _msgSender());
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN, _msgSender()), "Only admin can do action");
        _;
    }

    modifier onlyVoter() {
        require(isVoter(_msgSender()), "Only voter can do action");
        _;
    }

    function addVoter(address _account) external onlyAdmin {
        require(!isVoter(_account), "Voter is exists.");
        voters.add(_account);

        emit UpdateVoter(_account, true);
    }

    function removeVoter(address _account) external onlyAdmin {
        require(isVoter(_account), "Voter is not exists.");
        voters.remove(_account);

        emit UpdateVoter(_account, false);
    }

    function isVoter(address _account) public view returns (bool) {
        return voters.contains(_account);
    }

    function totalVoter() public view returns (uint256) {
        return voters.length();
    }

    function getVoterByIndex(uint256 _index) public view returns (address) {
        return voters.at(_index);
    }

    function getCurrentRequestId() public view returns (uint256) {
        return _requestId.current();
    }

    function _createRequest(address _target, bytes memory _data) internal {
        _requestId.increment();
        requestDatas[_requestId.current()] = RequestData({
            requester: _msgSender(),
            target: _target,
            data: _data,
            status: RequestStatus.PENDING
        });

        emit NewRequest(_requestId.current(), _target, _data);
    }

    function cancelRequest(uint256 _id) public {
        require(_id > 0 && _id <= _requestId.current(), "invalid request id");

        RequestData storage requestData = requestDatas[_requestId.current()];
        require(requestData.requester == _msgSender(), "invalid requester");
        require(
            requestData.status == RequestStatus.PENDING,
            "invalid request status"
        );
        requestData.status = RequestStatus.CANCEL;

        emit CancelRequest(_id);
    }

    function _beforeAcceptRequest(uint256 _id)
        internal
        returns (RequestData memory)
    {
        require(_id > 0 && _id <= _requestId.current(), "invalid request id");
        RequestData storage requestData = requestDatas[_requestId.current()];
        require(
            requestData.status == RequestStatus.PENDING,
            "invalid request status"
        );
        requestData.status = RequestStatus.DONE;

        return requestData;
    }
}
