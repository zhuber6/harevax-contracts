// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Sneaker_ERC721.sol";
import "./ISneaker_ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//should be given MINTER_ROLE on Sneaker_ERC721
contract Sneaker_ERC721_Distributor is Ownable {
    
    address public sneaker_erc721;              // set in constructor
    IERC20 public immutable HRX_Token;          // set in constructor
    address public immutable treasury;          // set in constructor
    uint256[15] public breedFee;                // set in constructor

    mapping(address => uint256) public tokensMinted;

    uint256 public MINT_PRICE = 150e18;

    error MintNotAllowed();
    error InvalidNumOfTokens();
    error BreedNotAllowed(uint256 errorCode);

    constructor(
        address _sneaker_erc721,
        IERC20 _HRX_Token,
        address _treasury
    ) {
        sneaker_erc721 = _sneaker_erc721;
        HRX_Token = _HRX_Token;
        treasury = _treasury;
        breedFee = [
            250e18, 301e18, 377e18, 491e18,
            664e18, 923e18, 1313e18, 1901e18,
            2785e18, 4115e18, 6118e18, 9133e18,
            13670e18, 20499e18, 30778e18
        ];
    }

    function canMint(address user) public view returns(uint256) {
        uint256 userHrxBalance = HRX_Token.balanceOf(user);
        //i.e. if user has more than 150 HRX tokens
        if (userHrxBalance > MINT_PRICE) {
            return 0;
        }
        return 1;
    }

    function mint() public {
        if (canMint(msg.sender) != 0) revert MintNotAllowed();
        HRX_Token.transferFrom(msg.sender, treasury, MINT_PRICE);
        tokensMinted[msg.sender] += 1;
        ISneaker_ERC721(sneaker_erc721).mint(msg.sender);
    }

    function canBreed( uint256[] calldata tokenIds, address user) public view returns(uint256) {
        if (IERC721(sneaker_erc721).balanceOf(user) < 2) {
            return 1;
        }

        if (
            IERC721(sneaker_erc721).ownerOf(tokenIds[0]) != user ||
            IERC721(sneaker_erc721).ownerOf(tokenIds[1]) != user
        ) {
            return 2;
        }

        ISneaker_ERC721.SneakerStats[] memory stats = new ISneaker_ERC721.SneakerStats[](2);
        stats[0] = ISneaker_ERC721(sneaker_erc721).getSneakerStats(tokenIds[0]);
        stats[1] = ISneaker_ERC721(sneaker_erc721).getSneakerStats(tokenIds[1]);

        if (HRX_Token.balanceOf(user) < _getBreedFee(tokenIds)) {
            return 3;
        }

        if (stats[0].factoryUsed + stats[1].factoryUsed == 14) {
            return 4;
        }

        return 0;
    }

    function getBreedFee(uint256[] calldata tokenIds) public view returns(uint256) {
        return _getBreedFee(tokenIds);
    }

    function _getBreedFee(uint256[] calldata tokenIds) internal view returns(uint256) {
        ISneaker_ERC721.SneakerStats[] memory stats = new ISneaker_ERC721.SneakerStats[](2);
        stats[0] = ISneaker_ERC721(sneaker_erc721).getSneakerStats(tokenIds[0]);
        stats[1] = ISneaker_ERC721(sneaker_erc721).getSneakerStats(tokenIds[1]);

        uint32 feeIndex = stats[0].factoryUsed + stats[1].factoryUsed;
        return breedFee[feeIndex];
    }
    
    function breed(uint256[] calldata tokenIds) public {
        if (tokenIds.length != 2) revert InvalidNumOfTokens();
        
        uint256 canBreedVal = canBreed(tokenIds, msg.sender);
        if (canBreedVal != 0) revert BreedNotAllowed(canBreedVal);

        HRX_Token.transferFrom(msg.sender, treasury, _getBreedFee(tokenIds));
        ISneaker_ERC721(sneaker_erc721).breed(tokenIds, msg.sender);
    }
}