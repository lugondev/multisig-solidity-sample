// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMasterOwners {
    enum TxStatus {
        PENDING,
        SUCCESS,
        CANCEL
    }

    struct Transaction {
        address submitter;
        address target;
        bytes data;
        string note;
        uint256 deadline;
        TxStatus status;
    }

    function initialize() external;

    function transactions(uint256 _index)
        external
        view
        returns (Transaction memory);

    function masterOwner() external view returns (address);

    function ownerByIndex(uint256 index) external view returns (address);

    function isOwner(address _user) external view returns (bool);

    function totalOwner() external view returns (uint256);

    function defaultDeadline() external view returns (uint256);

    function renounceOwnership() external;

    function renounceMasterOwnership() external;

    function changeDefaultDeadline(uint256 _newDefaultDeadline) external;

    function transferMasterOwnership(address newOwner) external;

    function removeOwner(address owner) external;

    function addOwner(address newOwner) external;

    function totalPendingTxs() external view returns (uint256);

    function getPendingTxByIndex(uint256 _index)
        external
        view
        returns (uint256 txId, Transaction memory);

    function totalExecutedTxs() external view returns (uint256);

    function getExecutedTxByIndex(uint256 _index)
        external
        view
        returns (uint256 txId, Transaction memory);

    function totalCancelTxs() external view returns (uint256);

    function getCancelTxByIndex(uint256 _index)
        external
        view
        returns (uint256 txId, Transaction memory);

    function currentTransactionId() external view returns (uint256);

    function submitTransaction(
        address _target,
        bytes memory _data,
        uint256 _deadline,
        string memory _note
    ) external;

    function cancelTransaction(uint256 _id) external;

    function executeTransaction(uint256 _id) external;
}
