import { network, ethers, artifacts, hardhatArguments } from "hardhat";
import { Artifact } from "hardhat/types";
import {readFileSync} from "fs";
import {resolve} from "path";

import { SneakerERC721 } from "../typechain";

const pathToDeployedAddress = resolve(__dirname, `${hardhatArguments.network}-contract-addresses.json`)
const buffer: Buffer = readFileSync(pathToDeployedAddress);
const contractAddresses = JSON.parse(buffer.toString());

export async function watchEvents() {
  let tx;
  
  const sneakerArtifact: Artifact = await artifacts.readArtifact("Sneaker_ERC721");
  const sneakerContract: SneakerERC721 = await ethers.getContractAt(sneakerArtifact.abi, contractAddresses.sneaker) as SneakerERC721;

  sneakerContract.on("Mint", async ( owner, tokenId ) => {
    console.log(" ------------  Mint:  ------------");
    console.log("Owner:      ", owner );
    console.log("Token ID:   ", tokenId.toString() );
  });
}

watchEvents();