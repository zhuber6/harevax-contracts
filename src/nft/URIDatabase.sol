// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IURIDatabase.sol";

contract URIDatabase is Ownable, IURIDatabase {
    using Strings for uint256;
    string public baseURI;
    mapping (uint256 => string) public storedTokenUri;

    error UriAlreadySet();
    
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
    function setTokenURI(uint256 tokenId, string calldata _tokenURI) public {
        if (bytes(storedTokenUri[tokenId]).length != 0) revert UriAlreadySet();
        storedTokenUri[tokenId] = _tokenURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return storedTokenUri[tokenId];
    }
}