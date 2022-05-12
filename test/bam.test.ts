import { ethers, network } from "hardhat";
import chai, { assert, expect, should } from "chai";
import chaiAsPromised from "chai-as-promised";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber, utils } from "ethers";
import { advanceBlock, advanceBlockTo, advanceTime, latest } from "./utils/time";
import { AccountManagement, AccountManagement__factory, BAMPublicMERC20, BAMPublicMERC20__factory, BAMtoken, BAMtoken__factory } from "../typechain";

chai.use(chaiAsPromised);

describe("BAM Project", () => {
    let IAM: AccountManagement
    let bamPrivateContract: BAMtoken
    let bamPublicContract: BAMPublicMERC20
    let signers: SignerWithAddress[];

    beforeEach(async () => {
        signers = await ethers.getSigners();
        const [owner, user1, user2, user3, user4] = await ethers.getSigners()

        bamPrivateContract = await new BAMtoken__factory(owner).deploy()
        await bamPrivateContract.deployed()

        IAM = await new AccountManagement__factory(owner).deploy()
        await IAM.deployed()
        await IAM.init()

        bamPublicContract = await new BAMPublicMERC20__factory(owner).deploy()
        await bamPublicContract.deployed()

        await bamPrivateContract.initialize("BAM Token", "BAM", IAM.address)
        await bamPublicContract.initialize("BAM Token", "BAM", IAM.address, bamPrivateContract.address)

        await IAM.updateWhitelists(bamPrivateContract.address, signers.splice(0, 2).map(s => s.address), true)
        await IAM.updateBlacklists(bamPublicContract.address, [user3.address], true)


        await bamPrivateContract.mint(owner.address, 1000)
        await bamPrivateContract.mint(user1.address, 1000)
        await bamPrivateContract.mint(user2.address, 1000)
        await bamPrivateContract.mint(user3.address, 1000)
        await bamPrivateContract.mint(user4.address, 1000)
    });


    describe("BAM token test", () => {

        it('should transfer', async () => {
            const [owner, user1, user2, user3, user4] = await ethers.getSigners()
            //fail whitelist
            try {
                await bamPrivateContract.connect(user4).transfer(user1.address, 20)
            } catch (error: any) {
                expect(error.message).to.have.string("only accept whitelist")
            }
            try {
                await bamPrivateContract.connect(user3).transfer(user3.address, 20)
            } catch (error: any) {
                expect(error.message).to.have.string("only accept whitelist")
            }
        })

        it('should bridge', async () => {
            const [owner, user1, user2, user3] = await ethers.getSigners()
            
        })

        // it('should', async () => {
        //     const [owner, user1, user2, user3] = await ethers.getSigners()

        // })

    })
});
