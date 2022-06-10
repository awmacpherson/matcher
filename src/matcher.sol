// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import './interfaces/IERC20.sol';

struct Order {
	uint buy_amount;
	uint sell_amount;
	address owner;
	address buy_tok;
	address sell_tok; // 3 addresses pack into 2 slots
}

contract Matcher {
	mapping (bytes32 => Order) order_book; // key is keccak256 hash

	function create_order(Order calldata order) public returns (bytes32) {
		// require order.owner = msg.sender? 
		bytes32 order_id = keccak256(abi.encodePacked(
			msg.sender, // or use msg.sender and DELEGATECALL?
			order.buy_tok, 
			order.sell_tok, 
			order.buy_amount, 
			order.sell_amount
		));
		order_book[order_id] = order;
		// and actually transfer the tokens
		IERC20(order.sell_tok).transfer(address(this), order.sell_amount);
		return order_id;
	}

	function partial_fill_order(
		bytes32 order_id, 
		uint bid, 
		uint ask
	) public {
		// we should have the relation
		//
		// bid_amt    buy_amt
		// ------- > --------
		// ask_amt   sell_amt
		//
		// as well as bid_amt <= buy_amt, ask_amt <= sell_amt

		// only read from storage once
		// the solc optimiser may do this automatically
		Order order = order_book[order_id];
		// some gas is wasted reading addresses in the case the
		// transaction reverts without doing the transfers.
		// On the other hand, reading packed addresses one by one
		// may waste SLOADs.

		// check invariants are preserved
		require(ask * order.buy_amount <= bid * order.sell_amount);
		require(bid <= order.buy_amount);
		require(ask <= order.sell_amount); // redundant unless bid == buy == 0
		// in this case order is giving stuff away for free
		// optimisation: add a separate branch for this case?

		// design choice: allow bid > buy but have the fill_order
		// partially execute?

		// update storage
		order_book[order_id].sell_amount = sell - ask;
		order_book[order_id].buy_amount = buy - bid;

		// and now actually do the transfers
		IERC20(order_book[order_id].sell_tok).transfer(msg.sender, ask);
		IERC20(order_book[order_id].buy_tok)
			.transferFrom(msg.sender, order.owner, bid);
	}

	function cancel_order(bytes32 order_id) public {
		// cache sell order for refund (or do this before require())
		address refund_tok = order_book[order_id].sell_tok;
		uint refund_amt = order_book[order_id].sell_amount;

		// check tx.origin is owner of this order
		require(order_id == keccak256(abi.encodePacked(
			msg.sender, // or tx.origin
			order_book[order_id].buy_tok, 
			refund_tok, 
			order_book[order_id].buy_amount, 
			refund_amt
		)));
		
		// first two zeros are not needed for functionality
		// but do it anyway to clear storage and get gas refund
		order_book[order_id].buy_tok = address(0); 
		order_book[order_id].sell_tok = address(0);
		order_book[order_id].buy_amount = 0;
		order_book[order_id].sell_amount = 0;

		// and return the tokens
		// questions: 
		// 1. What context is this called in? Does it use DELEGATECALL?
		// 2. Do we need to set allowance?
		IERC20(refund_tok).transferFrom(address(this), msg.sender, refund_amt);
	}
}
