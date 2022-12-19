// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC20.sol";
import "./IVerifier.sol";

contract ZkERC20 is ERC20 {
    mapping(address => uint256) public balanceHashes;

    IVerifier public verifierReceiver;
    IVerifier public verifierSender;

    // constructor(address _receiver, address _sender) ERC20("ZkERC20", "ZKT") {
    //     verifierReceiver = IVerifier(_receiver);
    //     verifierSender = IVerifier(_sender);
    // }

    constructor() ERC20("ZkERC20", "ZKT") {
        verifierReceiver = IVerifier(
            0xCFaEB1D4769A469F64f042AfD3A4263ba054637c
        );
        verifierSender = IVerifier(0x8085c02665f2BC0975Bd69C747D1918c3154e5c0);
    }

    receive() external payable {}

    function deposit() public payable {}

    function mint(
        address _to,
        IVerifier.Proof memory proofReceiver,
        uint256 hashReceiverBalanceAfter
    ) public {
        // require(msg.value > 0, "ZkERC20: deposit amount must be greater than 0");

        uint256 hashReceiverBalanceBefore = balanceHashes[_to];
        uint256[4] memory inputReceiver = [
            0,
            hashReceiverBalanceBefore,
            hashReceiverBalanceAfter,
            1
        ];

        bool receiverProofIsCorrect = verifierReceiver.verifyTx(
            proofReceiver,
            inputReceiver
        );
        require(receiverProofIsCorrect, "Receiver proof is not correct");
        balanceHashes[_to] = hashReceiverBalanceAfter;
    }

    function withdraw(
        uint256 _amount,
        IVerifier.Proof memory proofWithdrawal,
        uint256 hashBalanceAfter
    ) public {
        uint256 hashBalance = balanceHashes[msg.sender];
        uint256[4] memory input = [_amount, hashBalance, hashBalanceAfter, 1];
        bool senderProofIsCorrect = verifierSender.verifyTx(
            proofWithdrawal,
            input
        );

        require(senderProofIsCorrect, "Sender proof is not correct");
        payable(msg.sender).transfer(_amount);
    }

    function transferPrivacy(
        address _to,
        IVerifier.Proof memory proofSender,
        uint256 hashSenderBalanceAfter,
        IVerifier.Proof memory proofReceiver,
        uint256 hashReceiverBalanceAfter
    ) public {
        uint256 hashSenderBalanceBefore = balanceHashes[msg.sender];
        uint256 hashReceiverBalanceBefore = balanceHashes[_to];

        uint256[4] memory inputSender = [
            0,
            hashSenderBalanceBefore,
            hashSenderBalanceAfter,
            1
        ];
        uint256[4] memory inputReceiver = [
            0,
            hashReceiverBalanceBefore,
            hashReceiverBalanceAfter,
            1
        ];

        bool senderProofIsCorrect = verifierSender.verifyTx(
            proofSender,
            inputSender
        );
        bool receiverProofIsCorrect = verifierReceiver.verifyTx(
            proofReceiver,
            inputReceiver
        );

        require(senderProofIsCorrect, "Sender's proofs are not correct");
        require(receiverProofIsCorrect, "Receiver's proofs are not correct");

        balanceHashes[msg.sender] = hashSenderBalanceAfter;
        balanceHashes[_to] = hashReceiverBalanceAfter;
    }

    function verifySenderTx(
        address _user,
        IVerifier.Proof memory proofSender,
        uint256 hashBalanceAfter
    ) public view returns (bool) {
        uint256 hashBalanceBefore = balanceHashes[_user];

        uint256[4] memory input = [0, hashBalanceBefore, hashBalanceAfter, 1];

        return verifierSender.verifyTx(proofSender, input);
    }

    function verifyReceiverTx(
        address _user,
        IVerifier.Proof memory proofReceiver,
        uint256 hashBalanceAfter
    ) public view returns (bool) {
        uint256 hashBalanceBefore = balanceHashes[_user];

        uint256[4] memory input = [0, hashBalanceBefore, hashBalanceAfter, 1];

        return verifierReceiver.verifyTx(proofReceiver, input);
    }
}
