import * as dotenv from 'dotenv';

import { HardhatUserConfig, task } from 'hardhat/config';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import 'hardhat-gas-reporter';
import 'solidity-coverage';

dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
const config: HardhatUserConfig = {
    solidity: '0.6.12',
    networks: {
        mainnet: {
            url: process.env.MAINNET_URL,
            accounts: {
                mnemonic: process.env.MNEMONIC,
            },
        },
        ropsten: {
            url: process.env.ROPSTEN_URL,
            accounts: {
                mnemonic: process.env.MNEMONIC,
            },
        },
        kovan: {
            url: process.env.KOVAN_URL,
            accounts: {
                mnemonic: process.env.MNEMONIC,
            },
        },
        polygon: {
            url: process.env.POLYGON_URL,
            accounts: {
                mnemonic: process.env.MNEMONIC,
            },
        },
        local_fork: {
            url: `http://127.0.0.1:8545/`,
            accounts: {
                mnemonic: process.env.MNEMONIC,
            },
        },
        hardhat: {
            forking: {
                url: 'https://speedy-nodes-nyc.moralis.io/a81efb041b7293507d672e8b/polygon/mainnet/archive',
            },
            accounts: {
                mnemonic: process.env.MNEMONIC,
            },
            chainId: 137,
        },
    },
    gasReporter: {
        enabled: process.env.REPORT_GAS !== undefined,
        currency: 'USD',
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY,
    },
};

export default config;
