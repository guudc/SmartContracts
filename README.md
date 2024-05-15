

# Auction Escrow Smart Contract

## Overview

This smart contract implements an auction system with escrow functionality on the Ethereum blockchain. It allows users to create auctions for Non-Fungible Tokens (NFTs) and receive bids from other users. The highest bidder can claim the NFT by fulfilling the bid amount.

## Contract Structure

The contract consists of two main contracts: `Escrow` and `Auction`.

### Escrow Contract

The `Escrow` contract acts as an escrow service, holding NFTs and ERC20 tokens during auctions. It ensures secure and fair transactions between sellers and buyers.

#### Features:
- **Initialization**: Initializes the escrow contract with the NFT contract address, ERC20 token address, and the token ID.
- **Functions**:
  - `transferNftFromEscrowtoBidder`: Transfers the NFT from escrow back to the bidder.
  - `transferAmounFromEscrowtoSeller`: Transfers the bid amount from escrow to the seller.
  - `revertAmount`: Reverts the bid amount to a specified address in case of an error.
  - `revertNft`: Reverts the NFT to a specified address in case of an error.

### Auction Contract

The `Auction` contract manages the auction process, allowing users to create auctions, place bids, and claim the NFTs.

#### Features:
- **Initialization**: Initializes the auction contract with the NFT contract address and the ERC20 token address.
- **Functions**:
  - `auction`: Starts a new auction for a specified token ID and duration.
  - `bid`: Allows bidders to place bids during the auction period.
  - `claimBid`: Allows the seller to claim the highest bid and transfer the NFT to the bidder.
  - `removeNftAuction`: Allows the seller to remove an NFT from the auction.
  - `revertAuction`: Reverts the auction and returns the NFT and bids if the auction duration has expired.
  - `getAuctionData`: Retrieves auction data for a specified token ID.
  - `getBid`: Retrieves bid data.

## Usage

1. Deploy the `Auction` contract on the Ethereum blockchain.
2. Initialize the contract with the NFT contract address and ERC20 token address.
3. Sellers can create auctions using the `auction` function, specifying the token ID and duration.
4. Bidders can place bids using the `bid` function during the auction period.
5. Once the auction ends, the seller can claim the highest bid using the `claimBid` function.
6. In case of errors or expired auctions, the `revertAuction` function can be used to revert transactions.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


