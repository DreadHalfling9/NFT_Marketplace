// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MarketPlace is IERC721Receiver, ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) private listings;

    event ItemListed(address indexed nftAddress, uint256 indexed tokenId, address indexed seller, uint256 price);
    event ItemSold(address indexed nftAddress, uint256 indexed tokenId, address indexed buyer, uint256 price);
    event ItemDelisted(address indexed nftAddress, uint256 indexed tokenId, address indexed seller);

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function listItem(address nftAddress, uint256 tokenId, uint256 price) external nonReentrant {
        require(price > 0, "Price must be greater than zero");

        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");

        nft.safeTransferFrom(msg.sender, address(this), tokenId);

        listings[nftAddress][tokenId] = Listing(msg.sender, price);
        emit ItemListed(nftAddress, tokenId, msg.sender, price);
    }

    function buyItem(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing memory listing = listings[nftAddress][tokenId];
        require(listing.price > 0, "Item not listed");
        require(msg.value >= listing.price, "Insufficient payment");

        delete listings[nftAddress][tokenId];

        payable(listing.seller).transfer(listing.price);

        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);

        emit ItemSold(nftAddress, tokenId, msg.sender, listing.price);
    }

    function delistItem(address nftAddress, uint256 tokenId) external nonReentrant {
        Listing memory listing = listings[nftAddress][tokenId];
        require(listing.seller == msg.sender, "Not the seller");

        delete listings[nftAddress][tokenId];

        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);

        emit ItemDelisted(nftAddress, tokenId, msg.sender);
    }

    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        return listings[nftAddress][tokenId];
    }
}
