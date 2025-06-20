// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Project is ERC721, Ownable {
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;
    
    // Mapping to store customer purchase amounts
    mapping(address => uint256) public customerPurchases;
    
    // Mapping to store NFT tier levels
    mapping(uint256 => uint8) public nftTiers;
    
    // Events
    event PurchaseRecorded(address indexed customer, uint256 amount);
    event LoyaltyNFTMinted(address indexed customer, uint256 tokenId, uint8 tier);
    event RewardClaimed(address indexed customer, uint256 tokenId);
    
    // NFT tier thresholds (in wei for simplicity)
    uint256 public constant BRONZE_THRESHOLD = 1 ether;
    uint256 public constant SILVER_THRESHOLD = 5 ether;
    uint256 public constant GOLD_THRESHOLD = 10 ether;
    
    constructor() ERC721("LoyaltyNFT", "LNFT") Ownable(msg.sender) {}
    
    /**
     * @dev Core Function 1: Record customer purchase and mint NFT if eligible
     * @param customer The customer's address
     * @param purchaseAmount The amount of the purchase
     */
    function recordPurchaseAndMintNFT(address customer, uint256 purchaseAmount) 
        external 
        onlyOwner 
    {
        require(customer != address(0), "Invalid customer address");
        require(purchaseAmount > 0, "Purchase amount must be greater than 0");
        
        // Update customer's total purchases
        customerPurchases[customer] += purchaseAmount;
        
        emit PurchaseRecorded(customer, purchaseAmount);
        
        // Check if customer is eligible for NFT
        uint8 eligibleTier = getEligibleTier(customer);
        
        if (eligibleTier > 0 && balanceOf(customer) == 0) {
            // Mint NFT if customer doesn't already have one
            _mintLoyaltyNFT(customer, eligibleTier);
        }
    }
    
    /**
     * @dev Core Function 2: Claim loyalty rewards based on NFT ownership
     * @param tokenId The NFT token ID
     */
    function claimLoyaltyReward(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "You don't own this NFT");
        require(nftTiers[tokenId] > 0, "Invalid NFT tier");
        
        uint8 tier = nftTiers[tokenId];
        uint256 rewardAmount = calculateReward(tier);
        
        // In a real implementation, this would transfer tokens or provide discounts
        // For now, we'll just emit an event
        emit RewardClaimed(msg.sender, tokenId);
        
        // Reset customer purchases after reward claim
        customerPurchases[msg.sender] = 0;
    }
    
    /**
     * @dev Core Function 3: Get customer loyalty status and NFT information
     * @param customer The customer's address
     * @return totalPurchases The total purchase amount
     * @return eligibleTier The tier the customer is eligible for
     * @return hasNFT Whether the customer owns a loyalty NFT
     */
    function getCustomerLoyaltyStatus(address customer) 
        external 
        view 
        returns (uint256 totalPurchases, uint8 eligibleTier, bool hasNFT) 
    {
        totalPurchases = customerPurchases[customer];
        eligibleTier = getEligibleTier(customer);
        hasNFT = balanceOf(customer) > 0;
        
        return (totalPurchases, eligibleTier, hasNFT);
    }
    
    // Internal helper functions
    function _mintLoyaltyNFT(address customer, uint8 tier) internal {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        
        _safeMint(customer, newTokenId);
        nftTiers[newTokenId] = tier;
        
        emit LoyaltyNFTMinted(customer, newTokenId, tier);
    }
    
    function getEligibleTier(address customer) internal view returns (uint8) {
        uint256 totalPurchases = customerPurchases[customer];
        
        if (totalPurchases >= GOLD_THRESHOLD) {
            return 3; // Gold
        } else if (totalPurchases >= SILVER_THRESHOLD) {
            return 2; // Silver
        } else if (totalPurchases >= BRONZE_THRESHOLD) {
            return 1; // Bronze
        }
        
        return 0; // Not eligible
    }
    
    function calculateReward(uint8 tier) internal pure returns (uint256) {
        if (tier == 3) return 1000; // Gold tier reward
        if (tier == 2) return 500;  // Silver tier reward
        if (tier == 1) return 100;  // Bronze tier reward
        return 0;
    }
    
    // View function to get total number of minted NFTs
    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }
}
