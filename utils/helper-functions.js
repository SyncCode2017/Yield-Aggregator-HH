// import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
// import { BigNumber, Contract, ContractTransaction, Transaction } from "ethers";
// import { getContractAddress, Interface, Result } from "ethers/lib/utils";
// import { run, ethers } from "hardhat";
// import { HardhatRuntimeEnvironment, Network } from "hardhat/types";
// import {
//   NftPerks as NftPerksType,
//   FundABusiness as FundABusinessType,
// } from "../types";

// import {
//   TIERS,
//   VERIFICATION_BLOCK_CONFIRMATIONS,
//   VERIFICATION_BLOCK_CONFIRMATIONS_DEV,
// } from "./constants";
// import { ContractType } from "hardhat/internal/hardhat-network/stack-traces/model";

// export const getCurrentTimestamp = () => {
//   return Math.round(new Date().getTime() / 1000);
// };

// export const unlockAddress = async (
//   hre,
//   address
// ) => {
//   await hre.network.provider.request({
//     method: "hardhat_impersonateAccount",
//     params: [address],
//   });
//   return await ethers.getSigner(address);
// };

// export const setupUsers = async <
//   ContractTypeArray extends { [Contract] }
// >(
//   addresses,
//   contracts
// ) => {
//   const users = [];
//   for (const address of addresses) {
//     users.push(await setupUser(address, contracts));
//   }
//   return users;
// };

const setupUser = async (address, contracts) => {
    const user = {
        address: address,
        signer: await ethers.getSigner(address),
    };
    for (const key of Object.keys(contracts)) {
        user[key] = contracts[key].connect(await ethers.getSigner(address));
    }
    return user;
};

// export const mineBlocks = async (s
//   hre,
//   blocksToMine,
//   blockTime = 13
// ) => {
//   await hre.network.provider.send("hardhat_mine", [
//     "0x" + blocksToMine.toString(16),
//     "0x" + blockTime.toString(16),
//   ]);
// };

// export const setNetworkTime = async (
//   hre: HardhatRuntimeEnvironment,
//   secondsToForward: number
// ) => {
//   await hre.network.provider.send("evm_setNextBlockTimestamp", [
//     secondsToForward,
//   ]);
//   await hre.network.provider.send("evm_mine");
// };

// export const getFutureContractAddress = async (
//   signer: SignerWithAddress,
//   skipCount?: number
// ): Promise<string> => {
//   const txCount = await signer.getTransactionCount();

//   const futureAddress = getContractAddress({
//     from: await signer.getAddress(),
//     nonce: skipCount ? txCount + skipCount : txCount,
//   });
//   return futureAddress;
// };

// export const sumOfElementsInArray = (elements: number[]): number => {
//   let sum: number = 0;
//   for (let index in elements) {
//     sum += elements[index];
//   }
//   return sum;
// };

// export const getEventEmitted = async (
//   tx: ContractTransaction,
//   contractInterface: Interface,
//   eventString: string
// ): Promise<{ eventFound: boolean; args: Result }> => {
//   const receipt = await ethers.provider.getTransactionReceipt(tx.hash);

//   const arr = receipt.logs
//     .map((log) => {
//       const data = log.data;
//       const topics = log.topics;
//       const temp = contractInterface.parseLog({ data, topics });
//       return temp;
//     })
//     .filter((log) => {
//       return eventString === log.name;
//     });

//   if (arr.length === 1) {
//     return { eventFound: true, args: arr[0].args };
//   } else if (arr.length === 0) {
//     return { eventFound: false, args: [] };
//   }

//   const args = arr.map((elem) => {
//     return elem.args;
//   });

//   return { eventFound: true, args: args };
// };

const verify = async (contractAddress, args) => {
    console.log("Verifying contract...");
    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArguments: args,
        });
    } catch (e) {
        if (e.message.toLowerCase().includes("already verified")) {
            console.log("Already verified!");
        } else {
            console.log(e);
        }
    }
};

// // eslint-disable-next-line  @typescript-eslint/no-explicit-any
// export const deployContract = async <ContractType extends Contract>(
//   contractName: string,
//   args?: any[]
// ): Promise<ContractType> => {
//   const contractFactory = await ethers.getContractFactory(contractName);

//   let contract;
//   if (args === undefined) {
//     contract = (await contractFactory.deploy()) as ContractType;
//   } else {
//     contract = (await contractFactory.deploy(...args)) as ContractType;
//   }

//   await contract.deployed();
//   return contract;
// };

// type txObject = {
//   // eslint-disable-next-line @typescript-eslint/no-explicit-any
//   [key: string]: any;
// };

// export const sendETHTransaction = async (
//   signer: SignerWithAddress,
//   txData: txObject
// ): Promise<Transaction> => {
//   const tx = await signer.sendTransaction(txData);
//   return tx;
// };

// export const sleep = (timeInMs: number) => {
//   console.log(`Sleeping for ${timeInMs}`);
//   return new Promise((resolve) => setTimeout(resolve, timeInMs));
// };

// export const getInterfaceID = (contractInterface: Interface) => {
//   let interfaceID: BigNumber = ethers.constants.Zero;
//   const functions: string[] = Object.keys(contractInterface.functions);
//   for (let i = 0; i < functions.length; i++) {
//     interfaceID = interfaceID.xor(contractInterface.getSighash(functions[i]));
//   }

//   return interfaceID;
// };

// export const getInterfaceIDArray = (contractInterface: Array<string>) => {
//   let interfaceID: BigNumber = ethers.constants.Zero;
//   for (let i = 0; i < contractInterface.length; i++) {
//     interfaceID = interfaceID.xor(
//       ethers.utils.keccak256(Buffer.from(contractInterface[i])).substring(0, 10)
//     );
//   }

//   return interfaceID;
// };

// export const getBlockConfirmations = (
//   developmentChains: Array<string>,
//   network: Network
// ): number => {
//   return developmentChains.includes(network.name)
//     ? VERIFICATION_BLOCK_CONFIRMATIONS_DEV
//     : VERIFICATION_BLOCK_CONFIRMATIONS;
// };

// async function getAccountBalances(accounts, contract) {
//   let accountsBalances = [];
//   // const provider = ethers.getDefaultProvider();

//   for (let i = 0; i < accounts.length; i++) {
//     const balanceWei = (
//       await contract.provider.getBalance(accounts[i])
//     ).toString();
//     const balanceEth = ethers.utils.formatEther(balanceWei);
//     accountsBalances.push(Number(balanceEth));
//   }
//   return accountsBalances;
// }

module.exports = { verify, setupUser };
  // export type TestAccount = {
  //   address: string;
  //   signer: SignerWithAddress;
  // } & {
  //   fundABiz: FundABusinessType;
  //   nftTier1Contract: NftPerksType;
  //   nftTier2Contract: NftPerksType;
  //   nftTier3Contract: NftPerksType;
  // };