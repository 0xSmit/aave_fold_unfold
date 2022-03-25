import { ethers } from 'hardhat';

type Address = string;

const AAVE_LENDING_ADDRESSES: { [chainId: number]: Address } = {
    1: '0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5',
    42: '0x88757f2f99175387aB4C6a4b3067c77A695b0349',
    137: '0xd05e3E715d945B59290df0ae8eF85c1BdB684744',
};

const debtTokenABI = ['function approveDelegation(address delegatee, uint256 amount)'];

async function main() {
    const { chainId, name } = await ethers.provider.getNetwork();
    const lendingAddress = AAVE_LENDING_ADDRESSES[chainId];
    const [signer] = await ethers.getSigners();

    console.log(`Deploying from account address ${signer.address}`);

    if (!lendingAddress) throw Error('Unsupported chainId');

    console.log(`Deploying on ${name} chainId: ${chainId} with lending address ${lendingAddress}`);

    const AaveFold = await ethers.getContractFactory('AaveFold', signer);

    const foldContract = await AaveFold.deploy(lendingAddress, { gasPrice: ethers.utils.parseUnits('50', 'gwei') });
    console.log(`foldContract Contract deployed at : ${foldContract.address}`);

    const ERC20 = await ethers.getContractFactory('ERC20', signer);

    const DAIToken = ERC20.attach('0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063');
    await (
        await DAIToken.approve(foldContract.address, ethers.constants.MaxUint256, {
            gasPrice: ethers.utils.parseUnits('50', 'gwei'),
        })
    ).wait();
    console.log('Dai granted spending allowance to fold contract');

    const DAIDebtTokenVar = new ethers.Contract('0x75c4d1fb84429023170086f06e682dcbbf537b7d', debtTokenABI, signer);
    (
        await DAIDebtTokenVar.approveDelegation(foldContract.address, ethers.constants.MaxUint256, {
            gasPrice: ethers.utils.parseUnits('50', 'gwei'),
        })
    ).wait();
    console.log(`DAI DEBT Approved to ${foldContract.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
