const { ethers, upgrades } = require('hardhat');

const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const pathOutputJson = path.join(__dirname, '../../deploy_output.json');
let deployOutput = {};
if (fs.existsSync(pathOutputJson)) {
    deployOutput = require(pathOutputJson);
}
console.log(`Bridge ERC20 Contract Proxy Addr: ${deployOutput.bTCLayer2BridgeERC20DeployContract}`)

async function main() {
    let [owner] = await ethers.getSigners();
    console.log(`Using owner account: ${await owner.getAddress()}`)

    const btcLayer2BridgeERC20Factory = await ethers.getContractFactory("BTCLayer2BridgeERC20", owner);
    const btcLayer2BridgeERC20Contract = btcLayer2BridgeERC20Factory.attach(deployOutput.bTCLayer2BridgeERC20DeployContract);
    const upgraded = await upgrades.upgradeProxy(btcLayer2BridgeERC20Contract, btcLayer2BridgeERC20Factory);
    console.log('BTCLayer2BridgeERC20Contract upgrade to:', upgraded.target);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
