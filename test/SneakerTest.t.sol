// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "src/token/ERC20MintableBurnableCapped.sol";
import "src/nft/Sneaker_ERC721.sol";
import "src/nft/ISneaker_ERC721.sol";
import "src/nft/Sneaker_ERC721_Distributor.sol";
import "src/nft/URIDatabase.sol";
import "./mocks/LinkToken.sol";
import "./mocks/MockVRFCoordinatorV2.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract SneakerTest is ISneaker_ERC721, IERC721Receiver, Test {
    using Strings for uint256;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    address treasury = address(bytes20(keccak256("treasury")));

    LinkToken public linkToken;
    MockVRFCoordinatorV2 public vrfCoordinator;
    // VRFConsumerV2 public vrfConsumer;

    uint96 constant public FUND_AMOUNT = 10 * 10**18;

    // Initialized as blank, fine for testing
    uint64 public subId;
    bytes32 public keyHash; // gasLane

    URIDatabase public uriDatabase_721;
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

        uriDatabase_721 = new URIDatabase();
        uriDatabase_721.setBaseURI("testURI/");

        sneaker_erc721 = new Sneaker_ERC721(
            "HRX Sneaker",
            "HRX Sneaker",
            // address(this),
            address(vrfCoordinator),
            keyHash,
            subId,
            address(uriDatabase_721)
        );

        // give *this contract* the MINTER_ROLE to on sneaker_erc721
        sneaker_erc721.grantRole(MINTER_ROLE, address(this));
    }

    function testDistributor() public {

        uint256 counter = 0;

        // Create distributor contract
        Sneaker_ERC721_Distributor distributor = new Sneaker_ERC721_Distributor(sneaker_erc721, mockHrx, treasury);

        // give the distributor contract the MINTER_ROLE to on sneaker_erc721
        sneaker_erc721.grantRole(MINTER_ROLE, address(distributor));

        // Revert because this contract doesn't have enough HRX
        vm.expectRevert(abi.encodeWithSignature("MintNotAllowed()"));
        distributor.mint();

        // Mint HRX to this address and approve mint price amount
        mockHrx.mint(address(this), 1e24);
        mockHrx.approve(address(distributor), distributor.MINT_PRICE());

        // Try to mint again with necessary HRX tokens
        distributor.mint();
        vrfCoordinator.fulfillRandomWords(++counter, address(sneaker_erc721));

        // Try to mint again with necessary HRX tokens
        mockHrx.approve(address(distributor), distributor.MINT_PRICE());
        distributor.mint();
        vrfCoordinator.fulfillRandomWords(++counter, address(sneaker_erc721));

        // Verify mint went through
        assertEq(distributor.tokensMinted(address(this)), counter);
        assertEq(sneaker_erc721.balanceOf(address(this)), counter);
        assertEq(mockHrx.balanceOf(address(this)), 1e24 - distributor.MINT_PRICE() * counter);
        assertEq(mockHrx.allowance(address(this), address(distributor)), 0);
        assertEq(mockHrx.balanceOf(treasury), distributor.MINT_PRICE() * counter);
    }

    function testMint() public {
        sneaker_erc721.mint(address(this));
        vrfCoordinator.fulfillRandomWords(1, address(sneaker_erc721));
        assertEq(sneaker_erc721.balanceOf(address(this)), 1);
    }

    function testBreed() public {
        uint256 counter = 0;
        uint32 numOfMintedErc721 = 5;

        // Create distributor contract
        Sneaker_ERC721_Distributor distributor = new Sneaker_ERC721_Distributor(sneaker_erc721, mockHrx, treasury);

        // give the distributor contract the MINTER_ROLE to on sneaker_erc721
        sneaker_erc721.grantRole(MINTER_ROLE, address(distributor));

        sneaker_erc721.batchMint(address(this), numOfMintedErc721);
        vrfCoordinator.fulfillRandomWords(++counter, address(sneaker_erc721));
        assertEq(sneaker_erc721.balanceOf(address(this)), numOfMintedErc721);

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 3;

        // Mint HRX to this address and approve mint price amount
        mockHrx.mint(address(this), 1e24);
        assertEq(distributor.canBreed(tokenIds, address(this)), 0);
        uint256 breedCost = distributor.getBreedFee(tokenIds);
        mockHrx.approve(address(distributor), breedCost);

        distributor.breed(tokenIds);
        vrfCoordinator.fulfillRandomWords(++counter, address(sneaker_erc721));
        assertEq(sneaker_erc721.balanceOf(address(this)), numOfMintedErc721 + 1);
        assertEq(mockHrx.balanceOf(address(this)), 1e24 - breedCost);
        assertEq(mockHrx.balanceOf(address(treasury)), breedCost);

        SneakerStats memory stats;
        for (uint256 i = 1; i <= 6; i++) {
            tokenIds[0] = 1;
            tokenIds[1] = 3;

            assertEq(distributor.canBreed(tokenIds, address(this)), 0);
            breedCost = distributor.getBreedFee(tokenIds);
            mockHrx.approve(address(distributor), breedCost);

            distributor.breed(tokenIds);
            vrfCoordinator.fulfillRandomWords(++counter, address(sneaker_erc721));
            
            stats = sneaker_erc721.getSneakerStats(i);
        }

        // Try to mint pair that cannot mint anymore
        assertEq(distributor.canBreed(tokenIds, address(this)), 4);

    }

    function testBatchMintFuzz(uint32 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 10000);
        sneaker_erc721.batchMint(address(this), amount);
        vrfCoordinator.fulfillRandomWords(1, address(sneaker_erc721));
        assertEq(sneaker_erc721.balanceOf(address(this)), amount);
    }

    function testBatchMint() public {
        uint32 maxErc721Tokens = sneaker_erc721.MAX_TOKENS();
        uint256 sum = 0;
        vm.expectRevert(abi.encodeWithSignature("InvalidAmountToMint()"));
        sneaker_erc721.batchMint(address(this), 0);
        
        vm.expectRevert(abi.encodeWithSignature("InvalidAmountToMint()"));
        sneaker_erc721.batchMint(address(this), maxErc721Tokens + 1);

        // Mint max and verify every outcome matches statistical models defined in Gitbook
        sneaker_erc721.batchMint(address(this), maxErc721Tokens);
        vrfCoordinator.fulfillRandomWords(1, address(sneaker_erc721));

        for (uint256 i = 1; i <= maxErc721Tokens; i++) {
            SneakerStats memory stats = sneaker_erc721.getSneakerStats(i);
            sum += stats.globalPoints;
            
            if ( stats.class == 0 ) {
                assertGe(stats.globalPoints, 8);
                assertLe(stats.globalPoints, 25);
            }
            else if ( stats.class == 1 ) {
                assertGe(stats.globalPoints, 25);
                assertLe(stats.globalPoints, 33);
            }
            else if ( stats.class == 2 ) {
                assertGe(stats.globalPoints, 33);
                assertLe(stats.globalPoints, 50);
            }
            else if ( stats.class == 3 ) {
                assertGe(stats.globalPoints, 50);
                assertLe(stats.globalPoints, 75);
            }
            else if ( stats.class == 4 ) {
                assertGe(stats.globalPoints, 75);
                assertLe(stats.globalPoints, 90);
            }
        }
    }

    function testRandomStats() public {
        uint256 iter = 5000;
        uint256 word;
        SneakerStats memory stats;

        for (uint256 i = 1; i <= iter; i++) {
            word = uint256(keccak256(abi.encode(1, i)));
            stats = genRandomStats(18, 3, word);

            assertGe(stats.globalPoints, 8);
            assertLe(stats.globalPoints, 25);
        }

        for (uint256 i = 1; i <= iter; i++) {
            word = uint256(keccak256(abi.encode(1, i)));
            stats = genRandomStats(31, 1, word);

            assertGe(stats.globalPoints, 25);
            assertLe(stats.globalPoints, 33);
        }

        for (uint256 i = 1; i <= iter; i++) {
            word = uint256(keccak256(abi.encode(1, i)));
            stats = genRandomStats(43, 3, word);

            assertGe(stats.globalPoints, 33);
            assertLe(stats.globalPoints, 50);
        }

        for (uint256 i = 1; i <= iter; i++) {
            word = uint256(keccak256(abi.encode(1, i)));
            stats = genRandomStats(64, 5, word);

            assertGe(stats.globalPoints, 50);
            assertLe(stats.globalPoints, 75);
        }

        for (uint256 i = 1; i <= iter; i++) {
            word = uint256(keccak256(abi.encode(1, i)));
            stats = genRandomStats(84, 3, word);

            assertGe(stats.globalPoints, 75);
            assertLe(stats.globalPoints, 90);
        }
    }

    function genRandomStats(
        int256 mu,
        uint256 sigma,
        uint256 randWord
    ) public pure returns (SneakerStats memory) {
        // Determine class using previous random number
        SneakerStats memory stats;
        int[] memory randomNorm = new int[](3);

        randomNorm = NormalRNG(
            randWord,
            mu,
            sigma,
            3
        );

        stats.running = uint32(uint256(randomNorm[0] / 3));
        stats.walking = uint32(uint256(randomNorm[1] / 3));
        stats.biking = uint32(uint256(randomNorm[2] / 3));
        stats.globalPoints = stats.running + stats.walking + stats.biking;

        return stats;
    }

    function NormalRNG(
        uint256 random_number,
        int256 _mu,
        uint256 _sigma,
        uint256 _n
    ) internal pure returns (int256[] memory) {
        //generate n random integers normally distributed of mean x0 and standard deviation std
        uint256[] memory random_array = expand(random_number, _n);
        int256[] memory final_array = new int256[](_n);

        for (uint256 i = 0; i < _n; i++) {
            //by Centrali Limit Thoerem, the count of 1’s, after proper transformation
            //is approximately normally distributed, in our case of mean 256/2 = 128 and std = 8
            uint256 result = _countOnes(random_array[i]); 
            //transforming the result to match x0 and std
            final_array[i] = int256(int(result) * int(_sigma)/8) - 128*int(_sigma)/8 + _mu;
        }

        return final_array;
    }

    function _countOnes(uint256 n) internal pure returns (uint256 count) {
        //Count the number of ones in the binary representation
        /// internal function in assembly to count number of 1's
        /// https://www.geeksforgeeks.org/count-set-bits-in-an-integer/
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

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
