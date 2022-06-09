// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/token/ERC20MintableBurnableCapped.sol";
import "src/nft/Sneaker_ERC721.sol";
import "src/nft/ISneaker_ERC721.sol";
import "./mocks/LinkToken.sol";
import "./mocks/MockVRFCoordinatorV2.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ContractTest is ISneaker_ERC721, IERC721Receiver, Test {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    LinkToken public linkToken;
    MockVRFCoordinatorV2 public vrfCoordinator;
    // VRFConsumerV2 public vrfConsumer;

    uint96 constant FUND_AMOUNT = 1 * 10**18;

    // Initialized as blank, fine for testing
    uint64 subId;
    bytes32 keyHash; // gasLane

    ERC20MintableBurnableCapped public mockHrx;
    Sneaker_ERC721 public sneaker_erc721;
    SneakerStats public stats;

    function setUp() public {
        linkToken = new LinkToken();
        vrfCoordinator = new MockVRFCoordinatorV2();
        subId = vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(subId, FUND_AMOUNT);

        mockHrx = new ERC20MintableBurnableCapped("mockHrx", "mockHrx", 1e27);
        mockHrx.grantRole(MINTER_ROLE, address(this));
        mockHrx.mint(address(this), 1e24);

        sneaker_erc721 = new Sneaker_ERC721(
            "HRX Sneaker",
            "HRX Sneaker",
            "baseURI_test/",
            address(this),
            address(vrfCoordinator),
            keyHash,
            subId
        );

        // give *this contract* the MINTER_ROLE to on sneaker_erc721
        sneaker_erc721.grantRole(MINTER_ROLE, address(this));
    }

    function testExample() public {
        sneaker_erc721.batchMint(address(this), 100);
        vrfCoordinator.fulfillRandomWords(1, address(sneaker_erc721));

        SneakerStats memory stats1 = sneaker_erc721.getSneakerStats(34);
        SneakerStats memory stats2 = sneaker_erc721.getSneakerStats(75);
        console.log("balance",sneaker_erc721.balanceOf(address(this)));
        console.log("tokenURI",sneaker_erc721.tokenURI(75));
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
