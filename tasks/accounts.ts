import {task} from "hardhat/config";

export function accountsTask() {
    return task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
        const accounts = await hre.ethers.getSigners();
        for (const [index, account] of accounts.entries()) {
            console.log(`${index} - ${account.address}`);
        }
    });
}
