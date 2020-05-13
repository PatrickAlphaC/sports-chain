# sports-chain

Right now I have a CL node that is serving all the data, EXCEPT fantasy points. You'll see that `get_points_nba_players` right now only returns 1. It's already really expensive to run a game, let alone start to calculat the amount of points each one gets.

If you deploy the contract, you can run the "start game" and it will give you a game that starts in two days or greater from the Pandascores API. 

It will then prompt a Chainlink Alarm to close the game, as well as send payouts to winners. Right now everyone/no one wins since collecting points is such a nightmare.
```
Node address(Ropsten):
0x810B278a74d5eE00357420Fd1abF4bdFF55918D1

Oracle contract address (ropsten):
0x241F77325C073a3815985691f76B58dff17F685B
```
