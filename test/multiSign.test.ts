import chai, { expect } from "chai";
import chaiAsPromised from "chai-as-promised";
import { ethers } from "hardhat";
import { ExampleToken, ExampleToken__factory, MultiSigExecute, MultiSigExecute__factory } from "../typechain";

chai.use(chaiAsPromised);

describe("BAM MultiSign", async () => {
    let signers = await ethers.getSigners();
    let ExampleERC20: ExampleToken;
    let DAO: MultiSigExecute;

    const submitSendToken = async () => {
        const DaoOwner1 = await DAO.connect(signers[1]);
        await DaoOwner1.submitTransaction(ExampleERC20.address, ExampleERC20.interface.encodeFunctionData("transfer", [signers[6].address, ethers.utils.parseEther("1000")]));
        const id = await DAO.currentTransactionId();
        expect(await DAO.totalPendingTxs()).equal(1);

        await Promise.all(
            signers.slice(0, 5).map(async (signer) => {
                const DAOTemp = await DAO.connect(signer);
                await expect(DAOTemp.confirmTransaction(id)).to.be.fulfilled;
            })
        );

        return id
    };

    const submitAddOwner = async (address: string) => {
        await DAO.submitTransaction(DAO.address, DAO.interface.encodeFunctionData("addOwner", [address]));
        const currentID = await DAO.currentTransactionId();

        await Promise.all(
            signers.slice(0, 5).map(async (signer) => {
                const DAOTemp = await DAO.connect(signer);
                await expect(DAOTemp.confirmTransaction(+currentID)).to.be.fulfilled;
            })
        );
        return currentID;
    };

    const submitRemoveOwner = async (address: string) => {
        await DAO.submitTransaction(DAO.address, DAO.interface.encodeFunctionData("removeOwner", [address]));
        const currentID = await DAO.currentTransactionId();

        await Promise.all(
            signers.slice(0, 5).map(async (signer) => {
                const DAOTemp = await DAO.connect(signer);
                await expect(DAOTemp.confirmTransaction(+currentID)).to.be.fulfilled;
            })
        );
        return currentID;
    };

    beforeEach(async () => {
        signers = await ethers.getSigners();
        ExampleERC20 = await new ExampleToken__factory(signers[0]).deploy();
        await ExampleERC20.deployed();
        DAO = await new MultiSigExecute__factory(signers[0]).deploy(
            signers.slice(0, 5).map((signer) => signer.address),
            3
        );
        await DAO.deployed();
        await ExampleERC20.transfer(DAO.address, ethers.utils.parseEther("100000"));
    });

    describe("BAM MultiSign test", () => {
        it("submit transaction and vote", async () => {
            await submitSendToken();
            await expect(DAO.executeTransaction(1)).to.be.fulfilled;
            const balance = await ExampleERC20.balanceOf(signers[6].address);
            expect(balance).equal(ethers.utils.parseEther("1000"));
        });

        it("2. The number of owners is always greater than or equal to 3", async () => {
            await expect(
                new MultiSigExecute__factory(signers[0]).deploy(
                    signers.slice(0, 2).map((signer) => signer.address),
                    2
                )
            ).to.be.revertedWith("the number of owners must be greater than 2");

            await expect(
                new MultiSigExecute__factory(signers[0]).deploy(
                    signers.slice(0, 2).map((signer) => signer.address),
                    5
                )
            ).to.be.revertedWith("the number of owners must be greater than 2");
        });

        it("3. Weight of confirmations is always greater than or equal to 2", async () => {
            await expect(
                new MultiSigExecute__factory(signers[0]).deploy(
                    signers.slice(0, 5).map((signer) => signer.address),
                    1
                )
            ).to.be.revertedWith("invalid number of required confirmations");
        });

        it("4. Only owner can submit new transaction", async () => {
            const hacker = await MultiSigExecute__factory.connect(DAO.address, signers[6]);
            await expect(hacker.submitTransaction(ExampleERC20.address, ExampleERC20.interface.encodeFunctionData("transfer", [signers[6].address, ethers.utils.parseEther("1000")]))).to.be.revertedWith("not owner");
        });

        it("5. Anyone can execute a transaction after enough owners has approved it", async () => {
            await submitSendToken();
            const anyone = await DAO.connect(signers[6]);

            await expect(anyone.executeTransaction(1)).to.be.fulfilled;
        });

        it("6. Can approve and revoke approval of pending transactions", async () => {
            const anyone = await DAO.connect(signers[6]);
            await submitSendToken();
            await expect(DAO.revokeTransaction(1), "owner revoke").to.be.fulfilled;
            await expect(anyone.revokeTransaction(1), "other revoke").to.be.revertedWith("not owner");
        });

        it("7. Update: Add/Remove owner, change weight of confirmations", async () => {
            const id = await submitAddOwner(signers[6].address);
            await DAO.executeTransaction(+id);
            const isOwner = await DAO.isOwner(signers[6].address);
            expect(isOwner, "add owner").to.be.true;

            const id2 = await submitRemoveOwner(signers[6].address);

            await DAO.executeTransaction(+id2);
            const isOwner2 = await DAO.isOwner(signers[6].address);
            expect(isOwner2, "remove owner").to.be.false;

            await DAO.submitTransaction(DAO.address, DAO.interface.encodeFunctionData("updateWeight", [4]));

            const id3 = await DAO.currentTransactionId();
            await Promise.all(
                signers.slice(0, 5).map(async (signer) => {
                    const DAOTemp = await DAO.connect(signer);
                    await expect(DAOTemp.confirmTransaction(+id3)).to.be.fulfilled;
                })
            );
            await DAO.executeTransaction(+id3);
            const weight = await DAO.weight();
            expect(weight, "update weight owner").to.be.equal(4);
        });

        it("8. Only can execute transaction if submitter transaction is current owner", async () => {
            const idSendToken = await submitSendToken();
            const idRemoveOwner = await submitRemoveOwner(signers[1].address);
            await DAO.executeTransaction(+idRemoveOwner);
            await expect(DAO.executeTransaction(+idSendToken)).to.be.revertedWith("summiter is revoked owner");
        });
    });
});
