// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Sneaker_ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

//should be given MINTER_ROLE on Sneaker_ERC721
contract Sneaker_ERC721_Merkle_Distributor is Ownable {
    Sneaker_ERC721 public sneaker_erc721;
    bytes32 private _presaleMerkleRoot;

    mapping(address => uint256) public tokensMinted;

    constructor(
        Sneaker_ERC721 _sneaker_erc721, 
        bytes32 presaleMerkleRoot
    ) {
    sneaker_erc721 = _sneaker_erc721;
        _presaleMerkleRoot = presaleMerkleRoot;
    }

    function setPresaleMerkleRoot(bytes32 root) external onlyOwner {
        _presaleMerkleRoot = root;
    }

    function verifyPresale(bytes32[] calldata _merkleProof, address addr) public view returns(bool) {
        return (MerkleProof.verify(_merkleProof, _presaleMerkleRoot, keccak256(abi.encodePacked(addr))) == true);
    }

    function mint(bytes32[] calldata _merkleProof) public {
        require(tokensMinted[msg.sender] < 1, "Token Already Claimed");
        require(verifyPresale(_merkleProof, msg.sender), "PRESALE_NOT_VERIFIED");
        tokensMinted[msg.sender] += 1;
        sneaker_erc721.mint(msg.sender);
    }
}
