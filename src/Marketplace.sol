// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract Marketplace {
    //Errors
    error Marketplace__InsufficientBalance();
    error Marketplace__ListingDoesNotExist();

    //State variables
    IERC20 public s_runBroToken; // RunBroToken contract address
    AggregatorV3Interface internal s_priceFeed; // Chainlink price feed contract address

    //Array to store shoe listings by ID
    struct ShoeListing {
        address owner;
        string name;
        uint256 price;
        string imageUrl;
    }
    ShoeListing[] public shoeListings;

    // Event definitions
    event ShoeListed(
        uint256 indexed _listingId,
        string indexed _name,
        uint256 _priceInWei,
        string _imageUrl
    );
    event ShoeBought(
        uint256 indexed _listingId,
        address indexed _buyer,
        uint256 _amountPaid
    );

    /**@dev be sure to add the actual address of
     * @param  _priceFeedAddress: chainlink pricefeed
     */
    constructor(address _runBroTokenAddress, address _priceFeedAddress) {
        s_runBroToken = IERC20(_runBroTokenAddress);
        s_priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    // Get the current price from chainlink
    function getLatestPrice() public view returns (int) {
        (, int price, , , ) = s_priceFeed.latestRoundData();
        return price;
    }

    /**
     * List shoe price and image
     * @param _name: name of the shoe
     * @param _priceInWei: list the price in wei
     * @param _imageUrl: to list the image of the shoe
     */
    function listShoe(
        string memory _name,
        uint256 _priceInWei,
        string memory _imageUrl
    ) public {
        //revert if balance is too low
        if (s_runBroToken.balanceOf(msg.sender) < _priceInWei) {
            revert Marketplace__InsufficientBalance();
        }

        // Create a new ShoeListing
        ShoeListing memory newListing = ShoeListing({
            owner: msg.sender, // Set the owner to the caller of the function
            name: _name,
            price: _priceInWei,
            imageUrl: _imageUrl
        });

        // Add the new listing to the shoeListings array
        // Transfer the price amount from the sender to the contract
        shoeListings.push(newListing);
        s_runBroToken.transferFrom(msg.sender, address(this), _priceInWei);
        emit ShoeListed(shoeListings.length, _name, _priceInWei, _imageUrl);
    }

    function buyShoe(uint256 _listingId) public payable {
        ShoeListing storage listing = shoeListings[_listingId];

        // Check if the listing exists
        if (_listingId >= shoeListings.length) {
            revert Marketplace__ListingDoesNotExist();
        }

        // Calculate the amount to send
        // Transfer the purchased amount from the buyer to the seller
        // Update the listing status
        uint256 amountToSend = msg.value;
        s_runBroToken.transfer(listing.owner, amountToSend);
        delete shoeListings[_listingId];
        emit ShoeBought(_listingId, msg.sender, amountToSend);
    }

    /** Getter Functions */
    // Function to get the total number of listings
    function getTotalListingsCount() public view returns (uint256) {
        return shoeListings.length;
    }

    // Function to get the details of a specific shoe listing by ID
    function getShoeListingDetails(
        uint256 _listingId
    )
        public
        view
        returns (
            address owner,
            string memory name,
            uint256 price,
            string memory imageUrl
        )
    {
        ShoeListing storage listing = shoeListings[_listingId];
        return (listing.owner, listing.name, listing.price, listing.imageUrl);
    }
}
