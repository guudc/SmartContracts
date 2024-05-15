// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
    This acts as an escrow contract to hold NFTS and Amount transactions
*/
contract Escrow is ERC1155Holder {
    
    IERC1155 nft; //NFT contract address
    IERC20 erc;
    uint256 tokenId; //NFT token id being locked in this escrow contract

    constructor (address _nftContractAddress, address _erc, uint256 _tokenId) {
        nft = IERC1155(_nftContractAddress);
        erc = IERC20(_erc);
        tokenId = _tokenId;
        require(nft.balanceOf(address(this), tokenId) == 0, "Invalid NFT Contract");
        require(erc.balanceOf(address(this)) == 0, "Invalid ERC Token");
        //give the creator of this contract the approval to transfer NFT and erc
        nft.setApprovalForAll(msg.sender, true);
        erc.approve(msg.sender, 9999999999999999999999999999999999999);
    }
    //This function transfers Nft from escrow back to buyer
    function transferNftFromEscrowtoBidder(address BuyerAddress) public returns (bool) {
        nft.safeTransferFrom(address(this), BuyerAddress,  tokenId, 1, "");
        return true;
    }
    //This function transfers the amount in the escrow to the seller
    function transferAmounFromEscrowtoSeller(uint256 amount, address sellerAddress) public returns (bool){
        require(erc.balanceOf(address(this)) >= amount, "Amount exceeds available funds");
        erc.transfer(sellerAddress, amount);
        return true;
    }
    //This functions revert any wrong transfer back to specified address
    function revertAmount(address receiver, uint256 amount) public returns (bool){
        require(erc.balanceOf(address(this)) >= amount, "Amount exceeds available funds");
        erc.transfer(receiver, amount);
        return true;
    }
    //This functions revert any wrong tokenId transferred back to specified address
    function revertNft(address receiver) public returns (bool) {
        //check if the Escrow has this nft
        if(nft.balanceOf(address(this), tokenId) >= 0) {
         nft.safeTransferFrom(address(this), receiver, tokenId, 1, "");
        }
        return true;
    }
     
}
contract Auction {
    //Global variables
    bool isTimeout = false;  //Monitoring Timeout events
    address public NFT; //Contains the nft contract address
    IERC20 public ERC; //Contains address of ERC20 token being used
    struct auction {
        address escrow;
        uint256 tokenId;
        uint256 duration;
        address seller;
        bool claim;
        uint256 bidder;
    }
    struct Bid {
        uint256 amount;
        uint256 duration;
        address bidder;
    }
    uint256 day = 86400; 
    mapping(uint256 => auction) auctionData; //Contains bid data
    Bid bidData; //Contains an array of bid data
    constructor (address nft, address erc20) {
        NFT = nft;
        ERC = IERC20(erc20);
        require(IERC1155(nft).balanceOf(address(this), 0) == 0, "Invalid NFT Contract");
        require(IERC20(erc20).balanceOf(address(this)) == 0, "Invalid ERC20 Token");
    }

    function transferNftFromSellertoEscrow(address sellerAddress, address escrowAddress, uint256 tokenId) internal returns(bool){
        IERC1155(NFT).safeTransferFrom(sellerAddress, escrowAddress, tokenId, 1, "");
        return true;
    }
    function transferAmounFromBiddertoEscrow(address escrowAddress, uint256 amount) internal returns (bool){
        require(ERC.balanceOf(msg.sender) >= amount, "Insufficient funds to allow for transfer");
        ERC.transferFrom(msg.sender, escrowAddress, amount);
        return true;
    }
    //This function creates new escrow contract address
    function escrowTransaction(address sellerAddress, uint256 tokenId) internal returns(bool, address){
        Escrow escrow = new Escrow(NFT, address(ERC), tokenId);
        transferNftFromSellertoEscrow(sellerAddress, address(escrow), tokenId);//Here NFT go from seller to escrow
        return (true, address(escrow));
    }
    /*  
        This function starts a new auction
        Sellers would have to provide apprval for this contract to transfer tokens.
        Duration is specified in days
    */
    function aution(uint256 tokenId, uint256 duration) external returns (bool) {
        require(auctionData[tokenId].escrow == address(0), "Has been placed on auction");
        (bool isFlag, address escrow) = escrowTransaction(msg.sender, tokenId);
        require(isFlag, "Unable to transfer NFT to escrow");
        //create auction data
        auctionData[tokenId] = auction(
            escrow, tokenId, ((duration * day) + block.timestamp), msg.sender, false, 0
        );
        return true;
    }
    /*
        This function gives bidders the ability to place bids for auctions
        Bidders need to place bid during the specified auction duration
    */
    function bid(uint256 tokenId, uint256 amount) external returns(bool) {
        //check if this auction is still going on
        require(auctionData[tokenId].duration >= block.timestamp, "Auction ended");
        require(amount > 0, "Amount to small");
        //check if its the current bidder
        if(bidData.bidder == msg.sender) {
            bidData.amount += amount;
        }
        else {
            //different bidder, check if bidding amount is greater than previous bid
            require(amount > bidData.amount, "Current bid greater than submitted bid");
            //revert amount to previous bidder
            if(bidData.bidder != address(0)) {
                Escrow(auctionData[tokenId].escrow).revertAmount(bidData.bidder, bidData.amount);
            }
            //store current bid data
            bidData.amount = amount;
            bidData.bidder = msg.sender;
            bidData.duration = auctionData[tokenId].duration;
            
        }
        //transfer amount to escrow
        transferAmounFromBiddertoEscrow(auctionData[tokenId].escrow, amount);
        return true;
    }
    /*
        This functions allows the seller to claim bid made by the highest bidder
        Note this action ends the bid as well
    */
    function claimBid(uint256 tokenId) external returns (bool) {
        require(auctionData[tokenId].seller == msg.sender, "Only owner of the auction can end it");
        //send NFT to highest bidder
        Escrow escrow = Escrow(auctionData[tokenId].escrow);
        escrow.transferNftFromEscrowtoBidder(bidData.bidder);
        //send amount to seller
        escrow.transferAmounFromEscrowtoSeller(bidData.amount, auctionData[tokenId].seller);
        //delete everthing
        auctionData[tokenId] = auction(
            address(0), 0, 0, address(0), false, 0
        );
        return true;
    }
    /*
        This function removes an NFT from auction
    */
    function removeNftAuction(uint256 tokenId) external returns (bool) {
        require(auctionData[tokenId].seller == msg.sender, "Only owner of the auction can end it");
        //send NFT to back to seller
        Escrow escrow = Escrow(auctionData[tokenId].escrow);
        escrow.revertNft(msg.sender);
        //revert amounts to all bidders
        escrow.revertAmount(bidData.bidder, bidData.amount);
        //delete everthing
        auctionData[tokenId] = auction(
            address(0), 0, 0, address(0), false, 0
        );
        bidData = Bid(0,0,address(0));
        return true;
    }
    /*
        This function reverts NFT and Bids if the Auction duration has expired
    */
    function revertAuction(uint256 tokenId) external returns (bool) {
        require(auctionData[tokenId].duration < block.timestamp, "Auction duration has not yet expired");
        //send NFT to back to seller
        Escrow escrow = Escrow(auctionData[tokenId].escrow);
        escrow.revertNft(msg.sender);
        //revert amounts to all bidders
        escrow.revertAmount(bidData.bidder, bidData.amount);
        //delete everthing
        auctionData[tokenId] = auction(
            address(0), 0, 0, address(0), false, 0
        );
        bidData = Bid(0,0,address(0));
        return true;
    }
    /*
        This are getter functions
    */
    //gets the auction data
    function getAuctionData(uint256 tokenId) external view returns (auction memory) {
        return auctionData[tokenId];
    }
    //get bid data
    function getBid() external view returns (Bid memory) {
        return bidData;
    }
     
}















