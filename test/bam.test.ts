import { ethers, network } from "hardhat";
import chai, { assert, expect } from "chai";
import chaiAsPromised from "chai-as-promised";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber, utils } from "ethers";
import { advanceBlock, advanceBlockTo, advanceTime, latest } from "./utils/time";
import { BAMtoken__factory } from "../typechain";

chai.use(chaiAsPromised);

function getRandomInt(max: number) {
    return Math.floor(Math.random() * max);
}


describe("BAM Project", () => {
    let bamTokenContract: BAMtoken__factory
    let signers: SignerWithAddress[];
    const BigDecimals = BigNumber.from(10).pow(18);

    beforeEach(async () => {
        console.log("generate contract");

        signers = await ethers.getSigners();

    });


    describe("BAM token test", () => {

        it('should', async () => {
            const [owner, user1, user2, user3] = await ethers.getSigners()
        })



        it('should', async () => {
            const [owner, user1, user2, user3] = await ethers.getSigners()

        })

    })
});
