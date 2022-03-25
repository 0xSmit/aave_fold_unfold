import { ethers } from 'hardhat';

type Address = string;

const AAVE_LENDING_ADDRESSES: { [chainId: number]: Address } = {
    1: '0x24a42fD28C976A61Df5D00D0599C34c4f90748c8',
    3: '0x1c8756FD2B28e9426CDBDcC7E3c4d64fa9A54728',
    42: '0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5',
};

async function main() {
    const { chainId, name } = await ethers.provider.getNetwork();
    const lendingAddress = AAVE_LENDING_ADDRESSES[chainId];
    const [signer] = await ethers.getSigners();

    console.log(`Deploying from account address ${signer.address}`);

    if (!lendingAddress) throw Error('Unsupported chainId');

    console.log(`Deploying on ${name} chainId: ${chainId} with lending address ${lendingAddress}`);

    const FlashLoanWindFactory = await ethers.getContractFactory('AaveFold', signer);
    const FlashLoanUnwindFactory = await ethers.getContractFactory('FlashloanUnwind', signer);

    const Wind = await FlashLoanWindFactory.deploy(lendingAddress);
    console.log(`Wind Contract deployed at : ${Wind.address}`);

    const Unwind = await FlashLoanUnwindFactory.deploy(lendingAddress);
    console.log(`Unwind Contract deployed at : ${Unwind.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
