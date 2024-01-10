const { ethers } = require('hardhat');
const { expect } = require('chai');

const RewardDistributionAddr = '0x90DE61B6F65a29d510f56b6A31A18d9D7cc838EC';
let deployer;
describe('Staking static data', () => {
    beforeEach(async () => {
        [deployer] = await ethers.getSigners();
    });
    // npx hardhat test test/claim.test.js --network lumozL1Devnet --grep "1.Claim"
    it('1.Claim', async () => {
        const rewardDistributionV2Contract = await ethers.getContractAt('RewardDistribution', RewardDistributionAddr, deployer);
        console.log(await rewardDistributionV2Contract.basicSettlementInterval());
        let amount = ethers.parseEther('5751927');
        console.log(amount);
        const tx = await rewardDistributionV2Contract.claim(4, amount, ["0x2b665c23457d0c5bd4fb764c1bc831c848342a4692fb65d745b0bbf1d1901096", "0x88b7f46f4db66a862a24c27a80ca1f7be628d6aa841356c504a81a225819b22a", "0xb9bbce523b7e89d25c58950a0cbf089d22f7cb0ef343e3c93143617d1829096e"]);
        console.log(`https://sepolia.etherscan.io/tx/${tx.hash}`);
        await tx.wait(1);
    }).timeout(1000000);
});