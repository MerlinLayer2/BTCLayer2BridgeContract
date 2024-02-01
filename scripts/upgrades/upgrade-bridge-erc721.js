const { ethers, upgrades } = require('hardhat');

const path = require('path');
const fs = require('fs');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const pathOutputJson = path.join(__dirname, '../../deploy_output.json');
let deployOutput = {};
if (fs.existsSync(pathOutputJson)) {
    deployOutput = require(pathOutputJson);
}
console.log(`Bridge ERC721 Contract Proxy Addr: ${deployOutput.bTCLayer2BridgeERC721DeployContract}`)

async function main() {
    let [owner] = await ethers.getSigners();
    console.log(`Using owner account: ${await owner.getAddress()}`)

    const btcLayer2BridgeERC721Factory = await ethers.getContractFactory("BTCLayer2BridgeERC721", owner);
    const btcLayer2BridgeERC721Contract = btcLayer2BridgeERC721Factory.attach(deployOutput.bTCLayer2BridgeERC721DeployContract);
    const upgraded = await upgrades.upgradeProxy(btcLayer2BridgeERC721Contract, btcLayer2BridgeERC721Factory);
    console.log('BTCLayer2BridgeERC721Contract upgrade to:', upgraded.target);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
