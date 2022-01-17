pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {

  YourToken yourToken;
  uint256 public constant tokensPerEth = 100;

  event BuyTokens(address _sender, uint256 _ethSent, uint256 _amountToBuy);
  event SellTokens(address _sender, uint256 _amountToSell, uint256 _ethReceived);

  constructor(address tokenAddress) public {
    yourToken = YourToken(tokenAddress);
  }

  /**
  * @notice Allow users to buy token for ETH
  */
  function buyTokens() public payable returns (uint256 tokenAmount) {
    require(msg.value > 0, "Send ETH to buy some tokens");

    uint256 amountToBuy = msg.value * tokensPerEth;

    // check if the Vendor Contract has enough amount of tokens for the transaction
    uint256 vendorBalance = yourToken.balanceOf(address(this));
    require(vendorBalance >= amountToBuy, "Vendor contract has not enough tokens in its balance");

    // Transfer token to the msg.sender
    (bool sent) = yourToken.transfer(msg.sender, amountToBuy);
    require(sent, "Failed to transfer token to user"); 

    emit BuyTokens(msg.sender, msg.value, amountToBuy);

    return amountToBuy;
  }

  /**
  * @notice Allow the owner of the contract to withdraw ETH
  */
  function withdraw() public onlyOwner {
    uint256 ownerBalance = address(this).balance;
    require(ownerBalance > 0, "Owner has no balance to withdraw");    

    (bool sent, bytes memory data) = msg.sender.call{value: ownerBalance}("");
    require(sent, "Failed to send user balance back to the owner");

  }


  /**
  * @notice Allow users to sell tokens for ETH
  */
  function sellTokens(uint256 tokenAmountToSell) public {
    require(tokenAmountToSell > 0, "Specify an amount of token greater than zero");

    // check that that the user's token balance is enough to do the swap 
    uint256 userBalance = yourToken.balanceOf(msg.sender);
    console.log('userBalance ', userBalance, ' tokenAmountToSell ', tokenAmountToSell);
    require(userBalance >= tokenAmountToSell, "Your balance is lower than the amount of tokens you want to sell");

    // check that the Vendor's balance is enough to do the swap 
    uint256 amountOfETHToTransfer = tokenAmountToSell / tokensPerEth;
    uint256 vendorEthBalance = address(this).balance;
    require(vendorEthBalance >= amountOfETHToTransfer, "Vendor does not have enough funds to accept the sell request");

    // transfer tokens from user to vendor, and check that transfer completed
    (bool sent) = yourToken.transferFrom(msg.sender, address(this), tokenAmountToSell);
    require(sent, "Failed to send ETH to the user");

    // transfer eth from vendor to user, check that transfer completed
    (sent,) = msg.sender.call{value: amountOfETHToTransfer}("");
    require(sent, "Failed to send ETH to the user");

    emit SellTokens(msg.sender, tokenAmountToSell, amountOfETHToTransfer);
  }
}
