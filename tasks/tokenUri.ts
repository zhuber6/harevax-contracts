import {task} from "hardhat/config";
import { Artifact } from "hardhat/types";
import { Contract } from "ethers";
import {readFileSync} from "fs";
import {resolve} from "path";

export function tokenUriTask() {
    
    return task("tokenUri", "Prints the list of accounts")
    .addParam("tokenId")
    .setAction(async (taskArgs, hre) => {
        var pathToDeployedAddress;
        if (hre.hardhatArguments.network == "local") {
            pathToDeployedAddress = resolve("./scripts/", `local-contract-addresses.json`)
        }
        else {
            pathToDeployedAddress = resolve("./scripts/", `fuji-contract-addresses.json`)
        }
        const buffer: Buffer = readFileSync(pathToDeployedAddress);
        const contractAddresses = JSON.parse(buffer.toString());

        const sneakerArtifact: Artifact = await hre.artifacts.readArtifact("Sneaker_ERC721");
        const sneakerContract: Contract = await hre.ethers.getContractAt(sneakerArtifact.abi, contractAddresses.sneaker);
        // console.log(taskArgs);
        console.log( await sneakerContract.tokenURI(taskArgs.tokenId));
    });
}
