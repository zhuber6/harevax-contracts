// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Sneaker_ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//should be given MINTER_ROLE on Sneaker_ERC721
contract Sneaker_ERC721_Distributor is Ownable {
    
    Sneaker_ERC721 public sneaker_erc721;       // set in constructor
    IERC20 public immutable HRX_Token;          // set in constructor
    address public immutable treasury;          // set in constructor

    mapping(address => uint256) public tokensMinted;

    uint256 public MINT_PRICE = 150e18;

    error MintNotAllowed();

    constructor(
        Sneaker_ERC721 _sneaker_erc721,
        IERC20 _HRX_Token,
        address _treasury
    ) {
        sneaker_erc721 = _sneaker_erc721;
        HRX_Token = _HRX_Token;
        treasury = _treasury;
    }

    function canMint(address user) public view returns(uint256) {
        uint256 userHrxBalance = HRX_Token.balanceOf(user);
        //i.e. if user has more than 150 HRX tokens
        if (userHrxBalance > MINT_PRICE) {
            return (1 - tokensMinted[user]);
        }
        return 0;
    }

    function mint() public {
        if (canMint(msg.sender) == 0) revert MintNotAllowed();
        HRX_Token.transferFrom(msg.sender, treasury, MINT_PRICE);
        tokensMinted[msg.sender] += 1;
        sneaker_erc721.mint(msg.sender);
    }
}