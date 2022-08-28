import { ethers, hardhatArguments, artifacts } from "hardhat";
import { Artifact } from "hardhat/src/types";
import {writeFileSync, readFileSync} from "fs";
import {resolve} from "path";
import { SneakerERC721 } from "../typechain";

const pathToDeployedAddress = resolve(__dirname, `${hardhatArguments.network}-contract-addresses.json`)
const buffer: Buffer = readFileSync(pathToDeployedAddress);
const contractAddresses = JSON.parse(buffer.toString());

export async function getMetaDataToPin(tokenID: number): Promise<string> {

  let tx;

  const ClassDict: string[] = [
    "Common",
    "Uncommon",
    "Rare",
    "Epic",
    "Legendary",
    "Mythic",
  ]

  const sneakerArtifact: Artifact = await artifacts.readArtifact("Sneaker_ERC721");
  const sneakerContract: SneakerERC721 = await ethers.getContractAt(sneakerArtifact.abi, contractAddresses.sneaker) as SneakerERC721;

  const sneakerStats = await sneakerContract.getSneakerStats(tokenID);
  const jsonMetadata = JSON.stringify({
    "pinataMetadata": {
      "name": tokenID.toString()
    },
    "pinataContent": {
      "name": "Sneaker #" + tokenID.toString(),
      "description": "Komodo Sneakers",
      "image": "https://ipfs.io/ipfs/QmTiEvedx4NbZmPFnshKuvSv5VVc9CjCYYfYwxpwWcYmDx/" + tokenID % 12,
      "attributes": [
        {
          "trait_type": "Class",
          "value": ClassDict[sneakerStats.class],
        },
        {
          "trait_type": "Generation",
          "value": sneakerStats.generation,
        },
        {
          "trait_type": "Globalpoints",
          "value": sneakerStats.globalPoints,
        },
        {
          "trait_type": "Running",
          "value": sneakerStats.running,
        },
        {
          "trait_type": "Walking",
          "value": sneakerStats.walking,
        },
        {
          "trait_type": "Biking",
          "value": sneakerStats.biking,
        },
        {
          "trait_type": "Factoryused",
          "value": sneakerStats.factoryUsed,
        },
        {
          "trait_type": "Energy",
          "value": sneakerStats.energy,
        },
      ]
    }
  });

  writeFileSync(resolve(__dirname, `./metadata/${tokenID}`), jsonMetadata);
  return jsonMetadata;
}