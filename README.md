# dullfair-truffle
DullFair, the boring casino. This is the smart contracts part

In my head this is a one-game casino. The game is a game of chance (or at least it'll look that way, I have no interest in the game mechanics at this time) played initially against a server, the house.

* First you'll have some DULL tokens in the ERC20 Smart Contract.
* A new smart contract will be created as a state channel for the game between a user and the house. I guess the house will build the contract and pay the gas. 
* The house will deposit some DULL in the state channel contract.
* The user will deposit some DULL in the state channel contract.
* The game will ensue (this will be a separate project) and the number of wins and losses for the user will be maintained. 
* For the sake if getting v1 done we'll keep the process of signing a cash-out transaction simple and probably not at all secure!

So we need:

1. An ERC20 Token smart contract. See https://medium.com/bitfwd/how-to-issue-your-own-token-on-ethereum-in-less-than-20-minutes-ac1f8f022793 to make it easy on myself.

2. A Channel smart contract. To get this going I'm going to base it on https://github.com/alex-miller-0/eth-dev-101/blob/master/truffle/contracts/TwoWayChannel.sol with some amendments because both parties need to deposit to start the game.
