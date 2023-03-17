// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

contract Auction is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    address auctionManager;

    struct winnerDetails {
        address winnerAddress;
        uint winnerBid;
    }

    address[] public bidders;
    mapping(address => uint) public bidderAmount;
    mapping(address => bool) public bidStatus;
    uint public minBid;

    winnerDetails[] public pastWinners;

    constructor() ERC721("Aitch", "H") {
        auctionManager = msg.sender;
        minBid = 0.01 ether;
    }

    modifier auctionManagerOnly() {
        require(msg.sender == auctionManager, "Unauthorized Operation");
        _;
    }

    function enterBid() public payable {
        require(msg.value >= minBid, "Insuficient ether to bid");
        require(msg.sender != address(0), "address zero not eligible to bid");
        require(bidStatus[msg.sender] == false, "You can only bid once");
        require(msg.sender != auctionManager, "Auction manager not eligible");
        bidders.push(msg.sender);
        bidderAmount[msg.sender] = msg.value;
        bidStatus[msg.sender] = true;
    }

    function declareWinner(
        string memory _uri
    ) public payable auctionManagerOnly {
        require(bidders.length > 0, "No bid recorded");

        address winningAddress;
        uint winningBid = 0;
        for (uint i = 0; i < (bidders.length); i++) {
            if (bidderAmount[bidders[i]] > winningBid) {
                winningBid = bidderAmount[bidders[i]];
                winningAddress = bidders[i];
            }
        }
        winnerDetails memory winner = winnerDetails(winningAddress, winningBid);
        pastWinners.push(winner);

        // send ether back to losing bidders.

        for (uint i = 0; i < (bidders.length); i++) {
            if (bidders[i] != winningAddress) {
                uint amount = bidderAmount[bidders[i]];
                (bool sent, bytes memory data) = bidders[i].call{value: amount}(
                    ""
                );
                require(sent, "failed to send ether");
            }
        }

        // mint nft to winner
        safeMint(winningAddress, _uri);

        // clear bidders array..
        delete bidders;
    }

    function safeMint(address to, string memory uri) public auctionManagerOnly {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function getWinner() public view returns (winnerDetails[] memory) {
        return (pastWinners);
    }
}
