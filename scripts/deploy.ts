import { BigNumber, Contract, ContractFactory } from "ethers";
import {parseEther, parseUnits} from "ethers/lib/utils";
import { ethers, hardhatArguments, artifacts } from "hardhat";
import { Artifact } from "hardhat/src/types";
import {writeFileSync} from "fs";
import {resolve} from "path";
import {deploySneakerMain, deploySneakerFuji} from "./deploySneaker";

const sneakerArtifact: Artifact = artifacts.readArtifactSync("Sneaker_ERC721");
const hrxTokenArtifact: Artifact = artifacts.readArtifactSync("HRX_Token");
const distributorArtifact: Artifact = artifacts.readArtifactSync("Sneaker_ERC721_Distributor");
const uriDatabaseArtifact: Artifact = artifacts.readArtifactSync("URIDatabase");

export async function deployContracts() {

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

  // Assign deployer minting capabilities
  let tx = await hrxTokenContract.grantRole(
    ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("MINTER_ROLE")
    ).toString(),
    accounts[0].address
  );
  tx.wait();

  // Mint some tokens for deployer
  tx = await hrxTokenContract.mint(accounts[0].address, parseEther('1000000'));
  tx.wait();

  // Deploy URI database
  const URIDatabaseFactory: ContractFactory = await ethers.getContractFactory("URIDatabase");
  const uriDatabaseContract: Contract = await URIDatabaseFactory.deploy();
  
  // Deploy URI database
  const SneakerProbsFactory: ContractFactory = await ethers.getContractFactory("SneakerProbabilities");
  const sneakerProbsContract: Contract = await SneakerProbsFactory.deploy();

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
