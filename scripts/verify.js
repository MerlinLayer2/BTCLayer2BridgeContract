require('dotenv').config();
const path = require('path');
const hre = require('hardhat');
const { expect } = require('chai');

const pathDeployOutputParameters = path.join(__dirname, '../deploy_output.json');
const deployOutputParameters = require(pathDeployOutputParameters);

async function main() {
    // verify bridge ERC20
    try {
        await hre.run(
            'verify:verify',
            {
                address: deployOutputParameters.bTCLayer2BridgeERC20DeployContract,
                constructorArguments: [],
            },
        );
    } catch (error) {
        expect(error.message.toLowerCase().includes('unknown action')).to.be.equal(true);
    }

    //verify bridge ERC721
    try {
        await hre.run(
            'verify:verify',
            {
                address: deployOutputParameters.bTCLayer2BridgeERC721DeployContract,
                constructorArguments: [],
            },
        );
    } catch (error) {
        expect(error.message.toLowerCase().includes('unknown action')).to.be.equal(true);
    }

    // verify bridge
    try {
        await hre.run(
            'verify:verify',
            {
                address: deployOutputParameters.bTCLayer2BridgeDeployContract,
                constructorArguments: [],
            },
        );
    } catch (error) {
        expect(error.message.toLowerCase().includes('unknown action')).to.be.equal(true);
    }
}

main().then(() => process.exit(0)).catch((error) => {
    console.error(error);
    process.exit(1);
});
