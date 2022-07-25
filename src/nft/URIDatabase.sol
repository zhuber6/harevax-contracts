// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IURIDatabase.sol";

contract URIDatabase is Ownable, IURIDatabase {
    using Strings for uint256;
    string public baseURI;
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), "json")) : "";
    }
}