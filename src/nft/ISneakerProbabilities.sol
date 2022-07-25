// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISneakerProbabilities {
    function getBreedProbs(uint256[] calldata index) external view returns (uint256[5] memory);
    function getMintProbs() external view returns (uint256[5] memory);
    function NormalRNG(
        uint256 random_number,
        uint256 _mu,
        uint256 _sigma,
        uint256 _n
    ) external pure returns (int256[] memory);
    function expand(uint256 randomValue, uint256 n) external pure returns (uint256[] memory);
}