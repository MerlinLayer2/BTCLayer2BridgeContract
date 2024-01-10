const { ethers, upgrades} = require('hardhat');

const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const pathOutputJson = path.join(__dirname, '../deploy_output.json');
let deployOutput = {};
if (fs.existsSync(pathOutputJson)) {
  deployOutput = require(pathOutputJson);
}
async function main() {
  let deployer = new ethers.Wallet(process.env.PRIVATE_KEY, ethers.provider);
  console.log(await deployer.getAddress())
  const rewardDistributionFactory = await ethers.getContractFactory("BTCLayer2Bridge", deployer);

  let deployContract;
  if (deployOutput.deployContract === undefined || deployOutput.deployContract === '') {
      deployContract = await upgrades.deployProxy(
        rewardDistributionFactory,
        [
          process.env.INITIAL_OWNER,
          process.env.SUPER_ADMIN_ADDRESS,
          process.env.NORMAL_ADMIN_ADDRESS,
          process.env.BRIDGE_FEE,
          process.env.BRIDGE_FEE_ADDRESS,
        ],
        {
          constructorArgs: [
          ],
          unsafeAllow: ['constructor', 'state-variable-immutable'],
        });
    console.log('tx hash:', deployContract.deploymentTransaction().hash);
  } else {
      deployContract = rewardDistributionFactory.attach(deployOutput.deployContract);
  }

  deployOutput.deployContract = deployContract.target;
  fs.writeFileSync(pathOutputJson, JSON.stringify(deployOutput, null, 1));
  console.log('#######################\n');
  console.log('Contract deployed to:', deployContract.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
