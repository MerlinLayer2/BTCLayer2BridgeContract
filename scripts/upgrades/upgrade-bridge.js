const { ethers, upgrades } = require('hardhat');

const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const pathOutputJson = path.join(__dirname, '../../deploy_output.json');
let deployOutput = {};
if (fs.existsSync(pathOutputJson)) {
    deployOutput = require(pathOutputJson);
}
console.log(`Bridge Contract Proxy Addr: ${deployOutput.bTCLayer2BridgeDeployContract}`)

async function main() {
    let [owner] = await ethers.getSigners();
    console.log(`Using owner account: ${await owner.getAddress()}`)

    const btcLayer2BridgeFactory = await ethers.getContractFactory("BTCLayer2Bridge", owner);
    const btcLayer2BridgeContract = btcLayer2BridgeFactory.attach(deployOutput.bTCLayer2BridgeDeployContract);
    const upgraded = await upgrades.upgradeProxy(btcLayer2BridgeContract, btcLayer2BridgeFactory);
    console.log('BTCLayer2BridgeContract upgrade to:', upgraded.target);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
