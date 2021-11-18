// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; //contract communication security
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFTMarket is ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsSold; //simple math counting. this will b represented in links of arrays

  address payable owner;  //creating variable for the owner of the contract. the owner can get a commission on every item sold. maybe owner can get paid as listing fee. 
  uint256 listingPrice = 0.025 ether; //this is same as MATIC sine we are using same API

  constructor() {
    owner = payable(msg.sender);  //just setting owner of the contract
  }

  struct MarketItem { //defininf struct/object/map (key value pair) for each indiviual market item
    uint itemId;      //being used in the mappging
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable owner;
    uint256 price;
    bool sold;   //boolean for wether sold or not
  }
                                                           //uint256 will b the item ID
  mapping(uint256 => MarketItem) private idToMarketItem;  //mapping for our MarketItem (above). keeping track of all the items that have been created
                                                          //lsitening for events for our 
  event MarketItemCreated (                               //events get created for when a MarketItem is created fro aove struct
    uint indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price,
    bool sold
  );

  
  function getListingPrice() public view returns (uint256) {  /* Returns the listing price of the contract */
    return listingPrice;                                      //for front end purposes. this is interacting w contract
  }
                                 //a new market item, crates itself a new token/contract/NFT
  function createMarketItem(   /* Places an item for sale on the marketplace. this is interacting w contract   this is contract for NFT. This is our contract NFT/Token generator*/
    address nftContract,       //arg this will be the contract address of whwerever(polygon) we deploy NFT.sol
    uint256 tokenId,            //arg this tokenId wll b passed in from contract (NFT.sol)
    uint256 price               //arg token price for sale. user defines price via front end
  ) public payable nonReentrant {  //safety feature. thhs is a non reantrant modifier
        require(price > 0, "Price must be at least 1 wei");   //users cannot list something at 0 price
        require(msg.value == listingPrice, "Price must be equal to listing price"); //usr sending in this transaction must pay a listing price. so once user sells the NFT/token/contract, the new contract onwner will now own that value (msg.value)

        _itemIds.increment();      //just incrementing our item ids
        uint256 itemId = _itemIds.current();   //creating var named itemId for the sale that will go on sale now
      
        idToMarketItem[itemId] =  MarketItem(     //crating mapping for market item above. "MarketItem" is from struct. setting all values inside here
          itemId,           //itemId is coming from line 57. for example idToMarketItem 00, 01, 02 etc
          nftContract,     //coming from the arg from line 50
          tokenId,         //tokenId is coming from arg line 51
          payable(msg.sender),   //person sellig this token whcih is available in the transaction
          payable(address(0)),   //since we have no owenr yet because we are only focusing on selling first market item and no owner yet since no one has bought. 
          price,          //settin price
          false    //setting sold bollean to false from line 29 struct
        );
                   //more funcs can totally be added here, for example a cancellation func that allows buyers to cancel orders. 
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId); //the ownership will be first transferred here to the contract from the person selling the NFT (first step). contract will then transfer the ownership to the next buyer
            //above line passing in the 'nftContract', 'address(this)' is the contract itself
        emit MarketItemCreated(   //we r just emitting an event we created earlier.  we passing in everythihng we have set on line 61
          itemId,
          nftContract,
          tokenId,
          msg.sender,
          address(0),
          price,
          false
        );
  }

  function createMarketSale(  /* Creates the sale of a marketplace item *//* Transfers ownership of the item, as well as funds between parties */
    address nftContract,  //using same contract as before in createMarketItem func
    uint256 itemId         //using same itemId as before in createMarketItem func. we are not PASSING in price becuase price is already in the contract
    ) public payable nonReentrant {   //nonReentrant modifier
    uint price = idToMarketItem[itemId].price; //creating var here based on our args above lines 85 by using mapping
    uint tokenId = idToMarketItem[itemId].tokenId; //creating var here based on our args above lines 84 85 by using mapping. its important we alwasy get tokenId because it will not always match the itemId
    require(msg.value == price, "Please submit the asking price in order to complete the purchase"); //requirign the person/buyer whom sent in the transaction sent in the correct value. //value= money/cost of the NFT.

    idToMarketItem[itemId].seller.transfer(msg.value); //value= money/cost of the NFT. seller gets paid first here.
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId); //this NFT Marketplace/Contract is     tokenId/NFT is the digital good/NFT buyer is receiving here
    idToMarketItem[itemId].owner = payable(msg.sender); //updating mapping of idToMarketItem but also settin local value of owner to msg.sender
    idToMarketItem[itemId].sold = true; // setting value of itemId as sold by updating mapping
    _itemsSold.increment(); //keeping up with the items sold
    payable(owner).transfer(listingPrice); // commissio fee paying owner of NFT Marketplace. owner gets commission or residuals. 
  }

  function fetchMarketItems() public view returns (MarketItem[] memory) { /* Returns all UNSOLD market items */
    uint itemCount = _itemIds.current(); // creating var that keeps trak of al items created
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current(); //math for unsold item count
    uint currentIndex = 0; // this will populate an array with unsold items and then return those array items. so the index here will b used to keep track in loop below.
                           // we will loop over items created, so currentIndex will be incrememnted if we have an empty address
    MarketItem[] memory items = new MarketItem[](unsoldItemCount); //if itemIds dobt have an address that means it is UNSOLD, then fill up that array 
    for (uint i = 0; i < itemCount; i++) {
      if (idToMarketItem[i + 1].owner == address(0)) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  function fetchMyNFTs() public view returns (MarketItem[] memory) {/* Returns onlyl items that a user has purchased */
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns only items a user has created */
  function fetchItemsCreated() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }
}