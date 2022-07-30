import { Contract } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { ethers, hardhatArguments, userConfig } from "hardhat";

export async function deploySneakerMain(
    uriDatabaseAddress: string,
    sneakerProbsAddress: string
): Promise<Contract> {
  // Avalanche Mainnet Chainlink VRF Coordinator
  const vrfCoordMain = "0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634";
  
  // Avalanche Mainnet Chainlink Key Hash
  const keyHashMain = "0x06eb0e2ea7cca202fc7c8258397a36f33d88568d2522b37aaa3b14ff6ee1b696";

  // Avalanche Mainnet Chainlink key ID
  const subIdMain = 0;

  // Deploy Sneaker contract to Mainnet
  const Sneaker_ERC721 = await ethers.getContractFactory("Sneaker_ERC721");
  const SneakerContract: Contract = await Sneaker_ERC721.deploy(
    "HRX Sneaker",
    "HRX Sneaker",
    vrfCoordMain,
    keyHashMain,
    subIdMain,
    uriDatabaseAddress,
    sneakerProbsAddress
  );

  // Wait for contract to be deployed
  await SneakerContract.deployed();

  // Add the sneaker contract as the consumer
  const VRFCoordinatorV2Contract: Contract = await ethers.getContractAt(
    "VRFCoordinatorV2Interface",
    vrfCoordMain
  );
  
  const tx = await VRFCoordinatorV2Contract.addConsumer(subIdMain , SneakerContract.address);
  await tx.wait();

  return SneakerContract;
}

export async function deploySneakerFuji(
  uriDatabaseAddress: string,
  sneakerProbsAddress: string
): Promise<Contract> {
  let tx;

  // Avalanche Fuji Testnet Chainlink VRF Coordinator
  let vrfCoordFuji = "0x2eD832Ba664535e5886b75D64C46EB9a228C2610";

  // Avalanche Fuji Testnet Chainlink Key Hash
  let keyHashFuji = "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61";

  // Avalanche Fuji Testnet Chainlink key ID
  let subIdFuji = 134;

  // Add the sneaker contract as the consumer
  let VRFCoordinatorV2Contract: Contract = await ethers.getContractAt(
    "VRFCoordinatorV2Interface",
    vrfCoordFuji
  );

  if (hardhatArguments.network == "local" && !userConfig.networks?.hardhat?.forking?.enabled) {
    // local testnet subID is 1 since we are the only sub on the mock contract
    subIdFuji = 1;

    // Get mock contract and deploy
    const MockVRFCoordinatorV2Factory = await ethers.getContractFactory("MockVRFCoordinatorV2");
    const MockVRFCoordinatorV2Contract: Contract = await MockVRFCoordinatorV2Factory.deploy();

    // Create a subscription to mock
    tx = await MockVRFCoordinatorV2Contract.createSubscription();
    await tx.wait();

    // Fund subscription
    tx = await MockVRFCoordinatorV2Contract.fundSubscription(subIdFuji, parseEther("10"));
    await tx.wait();
    
    // Use mock contract when deploying sneaker contract
    vrfCoordFuji = MockVRFCoordinatorV2Contract.address;
    VRFCoordinatorV2Contract = MockVRFCoordinatorV2Contract;

    console.log(vrfCoordFuji);
  }

  // Deploy Sneaker contract to Fuji Testnet
  const Sneaker_ERC721 = await ethers.getContractFactory("Sneaker_ERC721");
  const SneakerContract: Contract = await Sneaker_ERC721.deploy(
    "HRX Sneaker",
    "HRX Sneaker",
    vrfCoordFuji,
    keyHashFuji,
    subIdFuji,
    uriDatabaseAddress,
    sneakerProbsAddress
  );

  // Wait for contract to be deployed
  await SneakerContract.deployed();

  if (hardhatArguments.network !== "local") {
    tx = await VRFCoordinatorV2Contract.addConsumer(subIdFuji , SneakerContract.address);
    await tx.wait();
  }

  return SneakerContract;
}