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
    const bTCLayer2BridgeFactory = await ethers.getContractFactory("BTCLayer2Bridge", deployer);
    const bTCLayer2BridgeERC20Factory = await ethers.getContractFactory("BTCLayer2BridgeERC20", deployer);
    const bTCLayer2BridgeERC721Factory = await ethers.getContractFactory("BTCLayer2BridgeERC721", deployer);
    let bTCLayer2BridgeDeployContract;
    if (deployOutput.bTCLayer2BridgeDeployContract === undefined || deployOutput.bTCLayer2BridgeDeployContract === '') {
      bTCLayer2BridgeDeployContract = await upgrades.deployProxy(
          bTCLayer2BridgeFactory,
        [],
        {
            initializer: false,
            constructorArgs: [],
            unsafeAllow: ['constructor', 'state-variable-immutable'],
        });
    console.log('tx hash:', bTCLayer2BridgeDeployContract.deploymentTransaction().hash);
    } else {
      bTCLayer2BridgeDeployContract = bTCLayer2BridgeFactory.attach(deployOutput.bTCLayer2BridgeDeployContract);
    }

    console.log('bTCLayer2BridgeDeployContract deployed to:', bTCLayer2BridgeDeployContract.target);

    let bTCLayer2BridgeERC20DeployContract;
    if (deployOutput.bTCLayer2BridgeERC20DeployContract === undefined || deployOutput.bTCLayer2BridgeERC20DeployContract === '') {
        bTCLayer2BridgeERC20DeployContract = await upgrades.deployProxy(
            bTCLayer2BridgeERC20Factory,
            [
                process.env.INITIAL_OWNER,
                bTCLayer2BridgeDeployContract.target
            ],
            {
                constructorArgs: [],
                unsafeAllow: ['constructor', 'state-variable-immutable'],
            });
        console.log('tx hash:', bTCLayer2BridgeERC20DeployContract.deploymentTransaction().hash);
    } else {
        bTCLayer2BridgeERC20DeployContract = bTCLayer2BridgeERC20Factory.attach(deployOutput.bTCLayer2BridgeERC20DeployContract);
    }

    console.log('bTCLayer2BridgeERC20DeployContract deployed to:', bTCLayer2BridgeERC20DeployContract.target);

    let bTCLayer2BridgeERC721DeployContract;
    if (deployOutput.bTCLayer2BridgeERC721DeployContract === undefined || deployOutput.bTCLayer2BridgeERC721DeployContract === '') {
        bTCLayer2BridgeERC721DeployContract = await upgrades.deployProxy(
            bTCLayer2BridgeERC721Factory,
            [
                process.env.INITIAL_OWNER,
                bTCLayer2BridgeDeployContract.target
            ],
            {
                constructorArgs: [],
                unsafeAllow: ['constructor', 'state-variable-immutable'],
            });
        console.log('tx hash:', bTCLayer2BridgeERC721DeployContract.deploymentTransaction().hash);
    } else {
        bTCLayer2BridgeERC721DeployContract = bTCLayer2BridgeERC721Factory.attach(deployOutput.bTCLayer2BridgeERC721DeployContract);
    }

    console.log('bTCLayer2BridgeERC721DeployContract deployed to:', bTCLayer2BridgeERC721DeployContract.target);

    const tx = await bTCLayer2BridgeDeployContract.initialize(process.env.INITIAL_OWNER,
        process.env.SUPER_ADMIN_ADDRESS,
        bTCLayer2BridgeERC20DeployContract.target,
        bTCLayer2BridgeERC721DeployContract.target,
        process.env.BRIDGE_FEE_ADDRESS);
    await tx.wait(1);

    console.log(await bTCLayer2BridgeDeployContract.bridgeERC20Address());
    console.log(await bTCLayer2BridgeDeployContract.bridgeERC721Address());

    deployOutput.bTCLayer2BridgeDeployContract = bTCLayer2BridgeDeployContract.target;
    deployOutput.bTCLayer2BridgeERC20DeployContract = bTCLayer2BridgeERC20DeployContract.target;
    deployOutput.bTCLayer2BridgeERC721DeployContract = bTCLayer2BridgeERC721DeployContract.target;
    fs.writeFileSync(pathOutputJson, JSON.stringify(deployOutput, null, 1));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
