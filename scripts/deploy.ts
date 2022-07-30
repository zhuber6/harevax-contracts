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

export async function deployContracts() {

  let tx;

  // Get accounts
  const accounts = await ethers.getSigners();
  const treasury = accounts[1].address;
  
  // Deploy HRX token
  const HRXTokenFactory: ContractFactory = await ethers.getContractFactory("HRX_Token");
  const hrxTokenContract: Contract = await HRXTokenFactory.deploy(
    "HRX Token",
    "Harevax Token",
    BigInt(1e27)
  );

  // Wait for contract to be deployed
  await hrxTokenContract.deployed();

  // Assign deployer minting capabilities
  tx = await hrxTokenContract.grantRole(
    ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("MINTER_ROLE")
    ).toString(),
    accounts[0].address
  );
  await tx.wait();

  // Mint some tokens for deployer
  tx = await hrxTokenContract.mint(accounts[0].address, parseEther('1000000'));
  await tx.wait();

  // Deploy URI database
  const URIDatabaseFactory: ContractFactory = await ethers.getContractFactory("URIDatabase");
  const uriDatabaseContract: Contract = await URIDatabaseFactory.deploy();

  // Wait for contract to be deployed
  await uriDatabaseContract.deployed();
  
  // Deploy Sneaker Probabilities contract
  const SneakerProbsFactory: ContractFactory = await ethers.getContractFactory("SneakerProbabilities");
  const sneakerProbsContract: Contract = await SneakerProbsFactory.deploy();

  // Wait for contract to be deployed
  await sneakerProbsContract.deployed();

  // const hrxTokenContract: Contract = await ethers.getContractAt(hrxTokenArtifact.abi, contractAddresses.hrx);
  // const sneakerProbsContract: Contract = await ethers.getContractAt(sneakerProbsArtifact.abi, contractAddresses.sneakerProbs);
  // const uriDatabaseContract: Contract = await ethers.getContractAt(uriDatabaseArtifact.abi, contractAddresses.uriDatabase);

  // Deploy Sneaker contract
  const sneakerContract: Contract = await deploySneakerFuji(
    uriDatabaseContract.address,
    sneakerProbsContract.address
  );

  // Deploy ERC721 Distributor contract
  const DistributorFactory: ContractFactory = await ethers.getContractFactory("Sneaker_ERC721_Distributor");
  const DistributorContract: Contract = await DistributorFactory.deploy(
    sneakerContract.address,
    hrxTokenContract.address,
    treasury
  );

  // Wait for contract to be deployed
  await DistributorContract.deployed();

  // Assign distributor minting and burning capabilities
  tx = await sneakerContract.grantRole(
    ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("MINTER_ROLE")
    ).toString(),
    DistributorContract.address
  );
  await tx.wait();

  // Save address data
  const addressesData = {
    hrx: hrxTokenContract.address,
    uriDatabase: uriDatabaseContract.address,
    sneakerProbs: sneakerProbsContract.address,
    sneaker: sneakerContract.address,
    distributor: DistributorContract.address,
  };

  console.log('\nSuccessfully deployed Contracts\n');
  writeFileSync(resolve(__dirname, `${hardhatArguments.network}-contract-addresses.json`), JSON.stringify(addressesData));
}

deployContracts().then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
