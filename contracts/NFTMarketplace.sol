// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMaketPlace is ERC721URIStorage {
    address payable owner;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    uint256 listPrice = 0.01 ether;

    constructor() ERC721("NFTMaketPlace", "NFTM") {
        owner = payable(msg.sender);
    }

    struct ListedToken {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool currentlyListed;
    }
    mapping(uint256 => ListedToken) private idToListedToken;

    function updateListprice(uint256 _listPrice) public payable {
        require(owner == msg.sender, "Only owner can update the listing price");
        listPrice = _listPrice;
    }

    function getListprice() public view returns (uint256) {
        return listPrice;
    }

    function getLatestToListedToken() public view returns (ListedToken memory) {
        uint256 currentTokenid = _tokenIds.current();
        return idToListedToken[currentTokenid];
    }

    function getListedTokenId(uint256 tokenId)
        public
        view
        returns (ListedToken memory)
    {
        return idToListedToken[tokenId];
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }

    //The ERC721URIStorage contract provides a function called tokenURI(uint256 tokenId) that returns the complete URI for a given token by concatenating the base URI with the token ID and returning the resulting string. The _setTokenURI() function in your example code is used to set the base URI that will be used to construct the complete URI for each new token that is created in the contract.
    function createToken(string memory tokenURI, uint256 price)
        public
        payable
        returns (uint256)
    {
        require(msg.value == listPrice, "Send enough ether to list");
        require(price > 0, "Make sure the price isin't negative");
        _tokenIds.increment();
        uint256 currentTokenId = _tokenIds.current();
        _safeMint(msg.sender, currentTokenId);
        _setTokenURI(currentTokenId, tokenURI);
        createListedToken(currentTokenId, price);
        return currentTokenId;
    }

    function createListedToken(uint256 tokenId, uint256 price) private {
        idToListedToken[tokenId] = ListedToken(
            tokenId,
            payable(address(this)),
            payable(msg.sender),
            price,
            true
        );
        _transfer(msg.sender, address(this), tokenId);
    }

    function getAllNFTs() public view returns (ListedToken[] memory) {
        uint256 nftCount = _tokenIds.current();
        //This creates a new dynamic array of ListedToken structs with a length equal to nftCount. The memory keyword indicates that the array is stored in memory rather than storage.
        ListedToken[] memory tokens = new ListedToken[](nftCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < nftCount; i++) {
            uint256 currentId = i + 1;
            //This retrieves the ListedToken struct with the given currentId from the idToListedToken mapping and stores it in memory.
            ListedToken storage currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }
        return tokens;
    }

    //Returns all the NFTs that the current user is owner or seller in
    function getMyNFTs() public view returns (ListedToken[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        uint256 currentId;
        //Important to get a count of all the NFTs that belong to the user before we can make an array for them
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                idToListedToken[i + 1].owner == msg.sender ||
                idToListedToken[i + 1].seller == msg.sender
            ) {
                itemCount += 1;
            }
        }

        //Once you have the count of relevant NFTs, create an array then store all the NFTs in it
        ListedToken[] memory items = new ListedToken[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (
                idToListedToken[i + 1].owner == msg.sender ||
                idToListedToken[i + 1].seller == msg.sender
            ) {
                currentId = i + 1;
                ListedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function executeSale(uint256 tokenId) public payable {
        uint256 price = idToListedToken[tokenId].price;
        require(
            msg.value == price,
            "Please submit the asking price for the NFT in order to buy the NFT"
        );
        address seller = idToListedToken[tokenId].seller;
        idToListedToken[tokenId].currentlyListed = true;
        idToListedToken[tokenId].seller = payable(msg.sender);
        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);
        approve(address(this), tokenId);
        payable(owner).transfer(listPrice);
        payable(seller).transfer(msg.value);
    }
}
