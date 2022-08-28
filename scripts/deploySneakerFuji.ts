import { Contract} from "ethers";
import { parseEther } from "ethers/lib/utils";
import { ethers, hardhatArguments, userConfig, artifacts} from "hardhat";
import { Artifact } from "hardhat/types";
import {writeFileSync, readFileSync} from "fs";
import {resolve} from "path";

const sneakerProbsArtifact: Artifact = artifacts.readArtifactSync("SneakerProbabilities");
const uriDatabaseArtifact: Artifact = artifacts.readArtifactSync("URIDatabase");

const pathToDeployedAddress = resolve(__dirname, `${hardhatArguments.network}-contract-addresses.json`)
const buffer: Buffer = readFileSync(pathToDeployedAddress);
const contractAddresses = JSON.parse(buffer.toString());

export async function deploySneakerFuji() {
  let tx;

  // Avalanche Fuji Testnet Chainlink VRF Coordinator
  const vrfCoordFuji = "0x2eD832Ba664535e5886b75D64C46EB9a228C2610";

  // Avalanche Fuji Testnet Chainlink Key Hash
  const keyHashFuji = "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61";

  // Avalanche Fuji Testnet Chainlink key ID
  const subIdFuji = 338;

  // Add the sneaker contract as the consumer
  const VRFCoordinatorV2Contract: Contract = await ethers.getContractAt(
    "VRFCoordinatorV2Interface",
    vrfCoordFuji
  );

  const sneakerProbsContract: Contract = await ethers.getContractAt(sneakerProbsArtifact.abi, contractAddresses.sneakerProbs);
  const uriDatabaseContract: Contract = await ethers.getContractAt(uriDatabaseArtifact.abi, contractAddresses.uriDatabase);

  // Deploy Sneaker contract to Fuji Testnet
  const Sneaker_ERC721 = await ethers.getContractFactory("Sneaker_ERC721");
  const SneakerContract: Contract = await Sneaker_ERC721.deploy(
    "HRX Sneaker",
    "HRX Sneaker",
    vrfCoordFuji,
    keyHashFuji,
    subIdFuji,
    uriDatabaseContract.address,
    sneakerProbsContract.address
  );

  // Wait for contract to be deployed
  await SneakerContract.deployed();
  console.log(SneakerContract.address);

  if (hardhatArguments.network !== "local") {
    tx = await VRFCoordinatorV2Contract.addConsumer(subIdFuji , SneakerContract.address);
    await tx.wait();
  }
}

deploySneakerFuji().then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });