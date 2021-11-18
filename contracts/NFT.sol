// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds; //var _tokenIds, Counter for incrementing token IDs: 0,1, 2 etc
    address contractAddress;   //var for NFT marketplace address. addrss of NFT Marketplace

    constructor(address marketplaceAddress) ERC721("Metaverse", "METT") {   //first we deploy the market then this contract
        contractAddress = marketplaceAddress;  //NFT market will allow to change ownership of these tokens
    }

    function createToken(string memory tokenURI) public returns (uint) {  //this mints new tokens. passing in tokenURI
        _tokenIds.increment();    // 0, 1, etc
        uint256 newItemId = _tokenIds.current(); //creatin var newItemId and this will get the value of _tokendIds

        _mint(msg.sender, newItemId);      //creating the token, msg.sender is the creator, passing in newITemID
        _setTokenURI(newItemId, tokenURI);  // func _setTokeURI is being imported from ERC721Storage, passing in newItemId and tokenURI
        setApprovalForAll(contractAddress, true);  //thsi gives marketplace approval to transact token between users from within another contract
        return newItemId;  //this is for the purpose of the front end , first we mint token then set it for sale . so to put it for sale we need to know the id of the token
    }
}

