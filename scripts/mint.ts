import { BigNumber, Contract, ContractFactory } from "ethers";
import {parseEther, parseUnits} from "ethers/lib/utils";
import { ethers, userConfig, artifacts, hardhatArguments } from "hardhat";
import { Artifact, NetworksUserConfig } from "hardhat/types";
import {readFileSync, PathLike} from "fs";
import {resolve} from "path";

const sneakerArtifact: Artifact = artifacts.readArtifactSync("Sneaker_ERC721");
const hrxTokenArtifact: Artifact = artifacts.readArtifactSync("HRX_Token");
const distributorArtifact: Artifact = artifacts.readArtifactSync("Sneaker_ERC721_Distributor");
const sneakerProbsArtifact: Artifact = artifacts.readArtifactSync("SneakerProbabilities");
const uriDatabaseArtifact: Artifact = artifacts.readArtifactSync("URIDatabase");
const vrfCoordArtifact: Artifact = artifacts.readArtifactSync("MockVRFCoordinatorV2");

const pathToDeployedAddress = resolve(__dirname, `${hardhatArguments.network}-contract-addresses.json`)
const buffer: Buffer = readFileSync(pathToDeployedAddress);
const contractAddresses = JSON.parse(buffer.toString());

export async function mint() {
  let tx;
  
  // Get accounts
  const accounts = await ethers.getSigners();
  const ownerAddress = accounts[0].address;

  const sneakerContract: Contract = await ethers.getContractAt(sneakerArtifact.abi, contractAddresses.sneaker);
  // const sneakerContract: Contract = await ethers.getContractAt(sneakerArtifact.abi, "0x5FbDB2315678afecb367f032d93F642f64180aa3");  // local
  const hrxTokenContract: Contract = await ethers.getContractAt(hrxTokenArtifact.abi, contractAddresses.hrx);
  const sneakerProbsContract: Contract = await ethers.getContractAt(sneakerProbsArtifact.abi, contractAddresses.sneakerProbs);
  const distributorContract: Contract = await ethers.getContractAt(distributorArtifact.abi, contractAddresses.distributor);
  const uriDatabaseContract: Contract = await ethers.getContractAt(uriDatabaseArtifact.abi, contractAddresses.uriDatabase);
  const vrfCoordContract: Contract = await ethers.getContractAt(vrfCoordArtifact.abi, "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707");  // local
  // const vrfCoordContract: Contract = await ethers.getContractAt(pathToAbi, "0x2eD832Ba664535e5886b75D64C46EB9a228C2610");  // avax fuji

  // if (userConfig.networks?.hardhat?.forking?.enabled) {
  //   tx = await hrxTokenContract.mint(ownerAddress, parseEther('5000000'));
  //   await tx.wait();
  // }

  const canmint = await distributorContract.canMint(ownerAddress);
  const mintPrice = await distributorContract.MINT_PRICE();
  
  if (canmint.isZero()) {
    tx = await hrxTokenContract.approve(distributorContract.address, mintPrice);
    await tx.wait();
    tx = await distributorContract.mint();
    tx = await sneakerContract.mint(ownerAddress);
    await tx.wait();

    const totalSupply = await sneakerContract.totalSupply();
    console.log(totalSupply.toNumber() + 1);

    if (hardhatArguments.network == "local" && !userConfig.networks?.hardhat?.forking?.enabled) {
      await vrfCoordContract.fulfillRandomWords(totalSupply.toNumber() + 1, sneakerContract.address)
    }
  }

  const Erc721Balance = await sneakerContract.balanceOf(ownerAddress);
  console.log(Erc721Balance);
  
  console.log(await sneakerContract.getSneakerStats(Erc721Balance));
}

mint().then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
