// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Complete.sol";
import "./ISneaker_ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Sneaker_ERC721 is 
    ISneaker_ERC721,
    ERC721Complete,
    IERC2981,
    VRFConsumerBaseV2
{
    using Counters for Counters.Counter;

    error InvalidAmountToMint();

    // Royalty
    uint256 constant public ROYALTY_PERCENT = 5;
    address public royaltiesReceiver;
    
    uint32 constant public MAX_TOKENS = 10000;
    
    //For chainlink VRF
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    
    // Avalanche feed
    // address vrfCoordinator = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;
    address vrfCoordinator;

    // Use highest gas lane
    // bytes32 keyHash = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
    bytes32 keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas.
    uint32 callbackGasLimit = 10000000;

    // The default is 3.
    uint16 requestConfirmations = 3;

    // Mappings
    mapping(uint256 => address) public requestIdToSender;
    mapping(uint256 => uint256) public requestIdToNumMint;
    mapping(uint256 => SneakerStats) public tokenIdToSneakerStats;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address _royaltiesReceiver,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    )
    VRFConsumerBaseV2(_vrfCoordinator)
    ERC721Complete(_name, _symbol, _baseTokenURI)
    {
        require(_royaltiesReceiver != address(0));
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;
        s_subscriptionId = _subscriptionId;
        royaltiesReceiver = _royaltiesReceiver;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _registerInterface(type(IERC2981).interfaceId);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address, uint256) {
        return(royaltiesReceiver, (salePrice * ROYALTY_PERCENT) / 100);
    }

    function mint(address to) public virtual override onlyRole(MINTER_ROLE) {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        uint256 currentTokenId = _tokenIdTracker.current();
        require(currentTokenId < MAX_TOKENS, "Sneaker_ERC721: all tokens have been minted");

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
    }

    function batchMint(address to, uint32 amountToMint) public virtual onlyRole(MINTER_ROLE) {
        if (amountToMint == 0) revert InvalidAmountToMint();
        uint256 currentTokenId = _tokenIdTracker.current();
        // require(currentTokenId + amountToMint <= MAX_TOKENS, "Sneaker_ERC721: mint would exceed max number of tokens");
        if (currentTokenId + amountToMint > MAX_TOKENS) revert InvalidAmountToMint();
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            20*10**4 * amountToMint + 20*10**4,
            amountToMint
        );
        requestIdToSender[requestId] = to;
        requestIdToNumMint[requestId] = amountToMint;
    }

    function setRoyaltiesReceiver(address _royaltiesReceiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_royaltiesReceiver != address(0), "zero bad");
        royaltiesReceiver = _royaltiesReceiver;
    }

    function getSneakerStats(uint256 tokenId) public view returns(SneakerStats memory) {
        return tokenIdToSneakerStats[tokenId];
    }

    function addConsumer(address consumer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        COORDINATOR.addConsumer(s_subscriptionId, consumer);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        SneakerStats memory newStats;
        uint8 randClass;
        int256 mu;
        uint256 sigma;
        int[] memory randomNorm = new int[](3);
        
        address nftOwner = requestIdToSender[requestId];
        uint256 amountToMint = requestIdToNumMint[requestId];

        for (uint256 i = 1; i <= amountToMint; i++) {
            _tokenIdTracker.increment();
            _safeMint(nftOwner, _tokenIdTracker.current());

            // Determine class using previous random number
            randClass = uint8(randomWords[i-1] % 101);

            // Set sneaker gen
            newStats.generation = 0;

            if ( randClass <= 50 ) {
                newStats.class = 0; mu = 18; sigma = 3; }
            else if ( randClass > 50 && randClass <= 80 ) {
                newStats.class = 1; mu = 31; sigma = 1; }
            else if ( randClass > 80 && randClass <= 90 ) {
                newStats.class = 2; mu = 43; sigma = 3; }
            else if ( randClass > 90 && randClass <= 97 ) {
                newStats.class = 3; mu = 64; sigma = 5; }
            else if ( randClass > 97 ) {
                newStats.class = 4; mu = 84; sigma = 3; }

            randomNorm = NormalRNG(
                randomWords[i-1],
                mu,
                sigma,
                3
            );

            newStats.running = uint32(uint256(randomNorm[0] / 3));
            newStats.walking = uint32(uint256(randomNorm[1] / 3));
            newStats.biking = uint32(uint256(randomNorm[2] / 3));
            newStats.globalPoints = newStats.running + newStats.walking + newStats.biking;

            tokenIdToSneakerStats[_tokenIdTracker.current()] = newStats;
        }
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
}