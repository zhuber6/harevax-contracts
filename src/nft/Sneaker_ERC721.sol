// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Complete.sol";
import "./ISneaker_ERC721.sol";
import "./IURIDatabase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Sneaker_ERC721 is 
    ISneaker_ERC721,
    ERC721Complete,
    VRFConsumerBaseV2
{
    using Counters for Counters.Counter;

    // Errors
    error InvalidAmountToMint();
    error invalidTokenID();
    error zeroAddress();
    error maxTokens();
    
    uint32 constant public MAX_TOKENS = 10000;
    
    //For chainlink VRF v2
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    address vrfCoordinator;
    bytes32 keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas.
    uint32 callbackGasLimit = 10000000;

    // The default is 3.
    uint16 requestConfirmations = 3;

    // URI Database
    IURIDatabase public uriDatabase;

    // NFT Housekeeping and probability arrays set during deployment
    uint256 public currentGen;
    uint256[5] public mintProbabilities;
    uint256[5][5][5][2] public breedProbs;
    uint256[5][2] public normalParams;  // mu and sigma

    // Mappings
    mapping(uint256 => address) private requestIdToSender;
    mapping(uint256 => uint256) private requestIdToNumMint;
    mapping(uint256 => SneakerStats) public tokenIdToSneakerStats;
    mapping(uint256 => uint256[5]) public requestIdToNumProbs;

    constructor(
        string memory _name,
        string memory _symbol,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        address _uriDatabase
    )
    VRFConsumerBaseV2(_vrfCoordinator)
    ERC721Complete(_name, _symbol, "")
    {
        // Chainlink VRF Coordinator
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        vrfCoordinator = _vrfCoordinator;

        // Key Hash corresponding to Chainlink VRF gas lane
        keyHash = _keyHash;

        // Subscription ID required for Chainlink VRF V2
        s_subscriptionId = _subscriptionId;
        
        // Set sender as default admin for now
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        
        // Set URI Database used for
        if(_uriDatabase == address(0)) revert zeroAddress();
        uriDatabase = IURIDatabase(_uriDatabase);
        
        // Setup storage arrays for probabilities
        mintProbabilities = [500, 800, 900, 975, 1000];
        normalParams[0] = [18, 31, 43, 64, 84];
        normalParams[1] = [3, 1, 3, 5, 3];
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

    function mint(address to) public virtual override onlyRole(MINTER_ROLE) {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        if(_tokenIdTracker.current() >= MAX_TOKENS) revert maxTokens();

        // Generate new random number to assign to stats, finish mint in callback function.
        // Will revert if subscription is not set and funded.
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1
        );

        requestIdToSender[requestId] = to;
        requestIdToNumMint[requestId] = 1;
        requestIdToNumProbs[requestId] = mintProbabilities;
    }

    function batchMint(address to, uint32 amountToMint) public virtual onlyRole(MINTER_ROLE) {
        if (amountToMint == 0) revert InvalidAmountToMint();
        uint256 currentTokenId = _tokenIdTracker.current();
        if (currentTokenId + amountToMint > MAX_TOKENS) revert InvalidAmountToMint();
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            21*10**4 * amountToMint + 21*10**4,
            amountToMint
        );
        requestIdToSender[requestId] = to;
        requestIdToNumMint[requestId] = amountToMint;
        requestIdToNumProbs[requestId] = mintProbabilities;
    }

    function breed(uint256[] calldata tokenIds, address owner) public onlyRole(MINTER_ROLE) {
        _breed(tokenIds[0], tokenIds[1], owner);
    }

    function _breed(uint256 tokenId1, uint256 tokenId2, address owner) internal {
        SneakerStats[] memory stats = new SneakerStats[](2);
        stats[0] = tokenIdToSneakerStats[tokenId1];
        stats[1] = tokenIdToSneakerStats[tokenId2];

        // Generate new random number to assign to stats, finish mint in callback function.
        // Will revert if subscription is not set and funded.
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1
        );

        requestIdToSender[requestId] = owner;
        requestIdToNumMint[requestId] = 1;
        requestIdToNumProbs[requestId] = breedProbs[currentGen == 0 ? 0 : 1][stats[0].class][stats[1].class];

        tokenIdToSneakerStats[tokenId1].factoryUsed = stats[0].factoryUsed + 1;
        tokenIdToSneakerStats[tokenId2].factoryUsed = stats[1].factoryUsed + 1;
    }

    function getSneakerStats(uint256 tokenId) public view returns(SneakerStats memory) {
        return tokenIdToSneakerStats[tokenId];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if( !_exists(tokenId)) revert invalidTokenID();
        return uriDatabase.tokenURI(tokenId);
    }

    function setUriDatabase(IURIDatabase _uriDatabase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(_uriDatabase) == address(0)) revert zeroAddress();
        uriDatabase = _uriDatabase;
    }

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */
    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {

        SneakerStats memory newStats;
        address nftOwner = requestIdToSender[requestId];
        uint256 amountToMint = requestIdToNumMint[requestId];
        uint256[5] memory probs = requestIdToNumProbs[requestId];
        uint16 randClass;
        int[] memory randomNorm = new int[](3);

        for (uint256 i = 1; i <= amountToMint; i++) {
            // Determine class using previous random number
            randClass = uint16(randomWords[i-1] % 1001);

            // Set sneaker gen
            newStats.generation = uint32(currentGen);

            if ( randClass <= probs[0] ) newStats.class = 0;
            else if ( randClass > probs[0] && randClass <= probs[1] ) newStats.class = 1;
            else if ( randClass > probs[1] && randClass <= probs[2] ) newStats.class = 2;
            else if ( randClass > probs[2] && randClass <= probs[3] ) newStats.class = 3;
            else if ( randClass > probs[3] ) newStats.class = 4;

            randomNorm = NormalRNG(
                randomWords[i-1],
                normalParams[0][newStats.class],
                normalParams[1][newStats.class],
                3
            );

            newStats.running = uint32(uint256(randomNorm[0] / 3));
            newStats.walking = uint32(uint256(randomNorm[1] / 3));
            newStats.biking = uint32(uint256(randomNorm[2] / 3));
            newStats.globalPoints = newStats.running + newStats.walking + newStats.biking;

            _tokenIdTracker.increment();
            uint256 tokenId = _tokenIdTracker.current();
            tokenIdToSneakerStats[tokenId] = newStats;
            _safeMint(nftOwner, tokenId);
        }
    }


    function NormalRNG(
        uint256 random_number,
        uint256 _mu,
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