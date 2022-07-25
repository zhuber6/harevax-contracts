// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ISneakerProbabilities.sol";

contract SneakerProbabilities is ISneakerProbabilities {

    error invalidIndexLen();

    // Define probabilities
    uint256[5] public mintProbabilities;
    uint256[5][5][5][2] public breedProbs;

    constructor(

    ) {
        // Setup storage arrays for probabilities
        mintProbabilities = [500, 800, 900, 975, 1000];
        setBreedArrays();
    }

    function setBreedArrays() internal {
        breedProbs[0][0][0] = [ 500, 1000, 1000, 1000, 1000 ];
        breedProbs[0][0][1] = [ 500, 950, 1000, 1000, 1000 ];
        breedProbs[0][0][2] = [ 500, 850, 1000, 1000, 1000 ];
        breedProbs[0][0][3] = [ 500, 800, 950, 1000, 1000 ];
        breedProbs[0][0][4] = [ 500, 750, 900, 990, 1000 ];

        breedProbs[0][1][0] = [ 500, 950, 1000, 1000, 1000 ];
        breedProbs[0][1][1] = [ 150, 750, 1000, 1000, 1000 ];
        breedProbs[0][1][2] = [ 150, 550, 800, 1000, 1000 ];
        breedProbs[0][1][3] = [ 150, 550, 840, 990, 1000 ];
        breedProbs[0][1][4] = [ 150, 450, 750, 950, 1000 ];

        breedProbs[0][2][0] = [ 500, 850, 1000, 1000, 1000 ];
        breedProbs[0][2][1] = [ 150, 550, 800, 1000, 1000 ];
        breedProbs[0][2][2] = [ 0, 200, 850, 1000, 1000 ];
        breedProbs[0][2][3] = [ 0, 200, 780, 980, 1000 ];
        breedProbs[0][2][4] = [ 0, 200, 600, 900, 1000 ];

        breedProbs[0][3][0] = [ 500, 800, 950, 1000, 1000 ];
        breedProbs[0][3][1] = [ 150, 550, 840, 990, 1000 ];
        breedProbs[0][3][2] = [ 0, 200, 780, 980, 1000 ];
        breedProbs[0][3][3] = [ 0, 0, 250, 900, 1000 ];
        breedProbs[0][3][4] = [ 0, 0, 250, 800, 1000 ];

        breedProbs[0][4][0] = [ 500, 750, 900, 990, 1000 ];
        breedProbs[0][4][1] = [ 150, 450, 750, 950, 1000 ];
        breedProbs[0][4][2] = [ 0, 200, 600, 900, 1000 ];
        breedProbs[0][4][3] = [ 0, 0, 250, 800, 1000 ];
        breedProbs[0][4][4] = [ 0, 0, 0, 300, 1000 ];

        breedProbs[1][0][0] = [ 700, 1000, 1000, 1000, 1000 ];
        breedProbs[1][0][1] = [ 700, 950, 1000, 1000, 1000 ];
        breedProbs[1][0][2] = [ 700, 900, 1000, 1000, 1000 ];
        breedProbs[1][0][3] = [ 700, 900, 980, 1000, 1000 ];
        breedProbs[1][0][4] = [ 700, 850, 950, 990, 1000 ];

        breedProbs[1][1][0] = [ 700, 950, 1000, 1000, 1000 ];
        breedProbs[1][1][1] = [ 300, 800, 1000, 1000, 1000 ];
        breedProbs[1][1][2] = [ 300, 700, 900, 1000, 1000 ];
        breedProbs[1][1][3] = [ 300, 700, 850, 900, 910 ];
        breedProbs[1][1][4] = [ 300, 600, 850, 980, 1000 ];

        breedProbs[1][2][0] = [ 700, 900, 1000, 1000, 1000 ];
        breedProbs[1][2][1] = [ 300, 700, 900, 1000, 1000 ];
        breedProbs[1][2][2] = [ 0, 350, 850, 1000, 1000 ];
        breedProbs[1][2][3] = [ 0, 350, 850, 980, 1000 ];
        breedProbs[1][2][4] = [ 0, 350, 750, 950, 1000 ];

        breedProbs[1][3][0] = [ 700, 900, 980, 1000, 1000 ];
        breedProbs[1][3][1] = [ 300, 700, 850, 900, 910 ];
        breedProbs[1][3][2] = [ 0, 350, 850, 980, 1000 ];
        breedProbs[1][3][3] = [ 0, 0, 400, 900, 1000 ];
        breedProbs[1][3][4] = [ 0, 0, 400, 800, 1000 ];

        breedProbs[1][4][0] = [ 700, 850, 950, 990, 1000 ];
        breedProbs[1][4][1] = [ 300, 600, 850, 980, 1000 ];
        breedProbs[1][4][2] = [ 0, 350, 750, 950, 1000 ];
        breedProbs[1][4][3] = [ 0, 0, 400, 800, 1000 ];
        breedProbs[1][4][4] = [ 0, 0, 0, 500, 1000 ];
    }

    function getBreedProbs(uint256[] calldata index) public view returns (uint256[5] memory) {
        if (index.length != 3) revert invalidIndexLen();
        return breedProbs[index[0]][index[1]][index[2]];
    }

    function getMintProbs() public view returns (uint256[5] memory) {
        return mintProbabilities;
    }


    function NormalRNG(
        uint256 random_number,
        uint256 _mu,
        uint256 _sigma,
        uint256 _n
    ) public pure returns (int256[] memory) {
        //generate n random integers normally distributed of mean x0 and standard deviation std
        uint256[] memory random_array = expand(random_number, _n);
        int256[] memory final_array = new int256[](_n);

        for (uint256 i = 0; i < _n; i++) {
            //by Centrali Limit Thoerem, the count of 1’s, after proper transformation
            //is approximately normally distributed, in our case of mean 256/2 = 128 and std = 8
            uint256 result = _countOnes(random_array[i]); 
            //transforming the result to match x0 and std
            final_array[i] = int256(int(result) * int(_sigma)/8) - 128*int(_sigma)/8 + int(_mu);
        }

        return final_array;
    }

    function _countOnes(uint256 n) internal pure returns (uint256 count) {
        // Count the number of ones in the binary representation
        // internal function in assembly to count number of 1's
        // https://www.geeksforgeeks.org/count-set-bits-in-an-integer/
        assembly {
            for { } gt(n, 0) { } {
                n := and(n, sub(n, 1))
                count := add(count, 1)
            }
        }
    }

    function expand(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
        //generate n pseudorandom numbers from a single one
        //https://docs.chain.link/docs/chainlink-vrf-best-practices/#getting-multiple-random-numbers
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

}