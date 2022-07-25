import {Contract} from "ethers";
import {ethers} from "hardhat";

export async function deploySneakerMain(
    uriDatabaseAddress: string,
    sneakerProbsAddress: string
): Promise<Contract> {
  // Avalanche Mainnet Chainlink VRF Coordinator
  const vrfCordMain = "0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634";
  
  // Avalanche Mainnet Chainlink Key Hash
  const keyHashMain = "0x06eb0e2ea7cca202fc7c8258397a36f33d88568d2522b37aaa3b14ff6ee1b696";

  // Avalanche Mainnet Chainlink key ID
  const subIdMain = 0;

  // Deploy Sneaker contract to Mainnet
  const Sneaker_ERC721 = await ethers.getContractFactory("Sneaker_ERC721");
  const SneakerContract: Contract = await Sneaker_ERC721.deploy(
    "HRX Sneaker",
    "HRX Sneaker",
    vrfCordMain,
    keyHashMain,
    subIdMain,
    uriDatabaseAddress,
    sneakerProbsAddress
  );

  // Add the sneaker contract as the consumer
  const VRFCoordinatorV2Contract: Contract = await ethers.getContractAt(
    "VRFCoordinatorV2Interface",
    vrfCordMain
  );
  await VRFCoordinatorV2Contract.addConsumer(subIdMain , SneakerContract.address)

  return SneakerContract;
}

export async function deploySneakerFuji(
  uriDatabaseAddress: string,
  sneakerProbsAddress: string
): Promise<Contract> {
  // Avalanche Fuji Testnet Chainlink VRF Coordinator
  const vrfCordFuji = "0x2eD832Ba664535e5886b75D64C46EB9a228C2610";

  // Avalanche Fuji Testnet Chainlink Key Hash
  const keyHashFuji = "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61";

  // Avalanche Fuji Testnet Chainlink key ID
  const subIdFuji = 134;

  // Deploy Sneaker contract to Fuji Testnet
  const Sneaker_ERC721 = await ethers.getContractFactory("Sneaker_ERC721");
  const SneakerContract: Contract = await Sneaker_ERC721.deploy(
    "HRX Sneaker",
    "HRX Sneaker",
    vrfCordFuji,
    keyHashFuji,
    subIdFuji,
    uriDatabaseAddress,
    sneakerProbsAddress
  );

  // Add the sneaker contract as the consumer
  const VRFCoordinatorV2Contract: Contract = await ethers.getContractAt(
    "VRFCoordinatorV2Interface",
    vrfCordFuji
  );
  await VRFCoordinatorV2Contract.addConsumer(subIdFuji , SneakerContract.address)

  return SneakerContract;
}