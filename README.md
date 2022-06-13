# matcher
An order book DEX powered by MEV bots.

Design comments:
- The main functions of this DEX are `create_order`, which creates a limit order (but more on this below) and `partial_fill_order` which selects an order on the book and (perhaps only partially) fills it. 
- In order to explain the idea of this interface, I will divide market participants into two classes:
  - *End-users*, whose main use for the protocol is the basic function of swapping token A for token B (either for utility or for a medium+ term investment). End-users are not assumed to possess sophisticated network or blockchain infrastructure, or be able to write bots. They interact with the DEX through a CLI or GUI frontend.
  - *Searchers*, who do possess sophisticated infrastructure and bot capability, and whose main use for the protocol is to make pure-profit transactions. 
  
  The basic division of labour is that end users will only directly call `create_order` (or call `partial_fill_order` through a sophisticated frontend). Searchers find opposing buy and sell orders and fill them, pocketing the difference (a.k.a. "slippage"). Searchers may also fill unopposed orders in order to arbitrage with external markets.
  
  Incentives for searchers dictate that all orders fill at exactly their limit price (or not at all), leading to a highly predictable (and un-frontrunnable) UX for users who call only `create_order` (although somewhat different from the UX of a traditional CEX LOB, a fact that documentation will have to make very clear to users). Successful searchers will backrun `create_order` transactions; they are assumed sophisticated enough to deal with the ensuing priority race.
- The order book is implemented as a mapping
  ```
  (address creator, address in_tok, address out_tok) => (uint in_amount, uint out_amount).
  ```
  I chose this design because it is light on storage and hence delivers low gas costs to users (less than 100K gas for a `create_order` TX).
  
  This design has an unusual side effect that each address can only have one trade open for each ordered pair of assets. Additional orders on the same pair are automatically "merged," possibly adjusting the unit price. Although it would be easy to adjust the design to track multiple orders with the same signature, I suspect that the fact that orders are always filled at their limit price means that there is little incentive to do this &mdash; if multiple orders for the same pair are open, the one with the "worst" price will always be filled first.
  
- `create_order` emits an event which indexes the addresses of the sender, the buy token, and the sell token. Aggregators will have to query the Ethereum logs and the current network state to build up a local picture of the order book. Optionally, a timeout could be added to orders so that aggregators only have to trawl logs back a fixed number of blocks.
