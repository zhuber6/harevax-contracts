# Harevax Contracts

These contracts are an idea of a [STEPn](https://whitepaper.stepn.com/game-fi-elements/sneakers) fork for AVAX where you mint sneakers with traits of random values. There are different classes of sneakers just like STEPn which are: Common, Uncommon, Rare, Epic, and Lengendary. Depending on the class of the sneaker minted, the sneaker will have a random value for each attribute, given a range defined by the class. The randomness in these contracts are handled by Chainlink VRFv2 and all of the probabilities have been calculated and stored in arrays on-chain. This may be expensive but I wrote these contracts as if I could get almost everything on-chain, not necessarily intending to have the project operate in this way.

## WIP

Things that I planned on adding were:

1. Full breeding capabilities.
2. Native token HRX and contracts handling staking of veHRX.
3. Dispersement of HRX funds to active users.

There are Forge unit tests and Hardhat scripts for deployment. 
