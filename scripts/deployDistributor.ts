import { BigNumber, Contract, ContractFactory } from "ethers";
import {parseEther, parseUnits} from "ethers/lib/utils";
import { ethers, hardhatArguments, artifacts } from "hardhat";
import { Artifact } from "hardhat/src/types";
import {writeFileSync, readFileSync} from "fs";
import {resolve} from "path";
import {deploySneakerMain, deploySneakerFuji} from "./deploySneaker";

const sneakerArtifact: Artifact = artifacts.readArtifactSync("Sneaker_ERC721");
const hrxTokenArtifact: Artifact = artifacts.readArtifactSync("HRX_Token");
const distributorArtifact: Artifact = artifacts.readArtifactSync("Sneaker_ERC721_Distributor");
const sneakerProbsArtifact: Artifact = artifacts.readArtifactSync("SneakerProbabilities");
const uriDatabaseArtifact: Artifact = artifacts.readArtifactSync("URIDatabase");

const pathToDeployedAddress = resolve(__dirname, `${hardhatArguments.network}-contract-addresses.json`)
const buffer: Buffer = readFileSync(pathToDeployedAddress);
const contractAddresses = JSON.parse(buffer.toString());

export async function deployDistributor() {

  let tx;

  // Get accounts
  const accounts = await ethers.getSigners();
  const treasury = accounts[1].address;

  const hrxTokenContract: Contract = await ethers.getContractAt(hrxTokenArtifact.abi, contractAddresses.hrx);
  const sneakerProbsContract: Contract = await ethers.getContractAt(sneakerProbsArtifact.abi, contractAddresses.sneakerProbs);
  const uriDatabaseContract: Contract = await ethers.getContractAt(uriDatabaseArtifact.abi, contractAddresses.uriDatabase);
  const sneakerContract: Contract = await ethers.getContractAt(sneakerArtifact.abi, contractAddresses.sneaker);

  // Deploy ERC721 Distributor contract
  const DistributorFactory: ContractFactory = await ethers.getContractFactory("Sneaker_ERC721_Distributor");
  const DistributorContract: Contract = await DistributorFactory.deploy(
    sneakerContract.address,
    hrxTokenContract.address,
    treasury
  );

  // Wait for contract to be deployed
  await DistributorContract.deployed();
  console.log("Distributor Address:", DistributorContract.address);

  // Assign distributor minting and burning capabilities
  tx = await sneakerContract.grantRole(
    ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("MINTER_ROLE")
    ).toString(),
    DistributorContract.address
  );
  await tx.wait();
}

deployDistributor().then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
