import { BigNumber, Contract, ContractFactory } from "ethers";
import {parseEther, parseUnits} from "ethers/lib/utils";
import { ethers, hardhatArguments, artifacts } from "hardhat";
import {writeFileSync} from "fs";
import {resolve} from "path";
import {deploySneakerMain, deploySneakerFuji} from "./deploySneaker";

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
  await hrxTokenContract.grantRole(
    ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("MINTER_ROLE")
    ).toString(),
    accounts[0].address
  );

  // Mint some tokens for deployer
  await hrxTokenContract.mint(accounts[0].address, parseEther('1000000'));

  // Deploy URI database
  const URIDatabaseFactory: ContractFactory = await ethers.getContractFactory("URIDatabase");
  const uriDatabaseContract: Contract = await URIDatabaseFactory.deploy();

  // Deploy Sneaker contract
  const sneakerContract: Contract = await deploySneakerFuji(
    uriDatabaseContract.address
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
    uirDatabase: uriDatabaseContract.address,
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
