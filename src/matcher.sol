// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;


import {IERC20} from './interfaces/IERC20.sol';

struct Order {
	uint256 buy_amount;
	uint256 sell_amount;
	address buy_tok;
	address sell_tok; // 3 addresses pack into 2 slots
}

struct OrderWithSender {
	uint256 buy_amount;
	uint256 sell_amount;
	address buy_tok;
	address sell_tok; // 3 addresses pack into 2 slots
	address sender;
}

struct OrderState {
	uint256 buy_amt;
	uint256 sell_amt;
}

contract Matcher {
	mapping (address => 
		 mapping(address => 
			 mapping(address => OrderState))) public order_book;

	event CreateOrder(
		uint256 buy_amt,
		uint256 sell_amt,
		address indexed sender,
		address indexed buy_tok,
		address indexed sell_tok
	); // how many topics are actually logged?

	function create_order(Order calldata order) public {
		// insert into order book
		// design choice: merge orders with same signature
		// If two orders have exactly the same price, it makes no difference to merge
		// If they have different prices, I think it actually benefits
		// the user to merge (by default the one with the "worse" price would
		// be filled first).
		order_book[msg.sender]
			[order.buy_tok]
				[order.sell_tok].buy_amt += order.buy_amount;
		order_book[msg.sender]
			[order.buy_tok]
				[order.sell_tok].sell_amt += order.sell_amount;
		
		// and actually transfer the tokens
		IERC20(order.sell_tok).transferFrom(
			msg.sender, 
			address(this), 
			order.sell_amount
		);

		emit CreateOrder(
			order.buy_amount, 
			order.sell_amount,
			msg.sender,
			order.buy_tok,
			order.sell_tok
		);
		
	}

	function partial_fill_order(
		address owner,
		address buy_tok,
		address sell_tok,
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
		OrderState memory order = order_book[owner][buy_tok][sell_tok];
		// some gas is wasted reading addresses in the case the
		// transaction reverts without doing the transfers.
		// On the other hand, reading packed addresses one by one
		// may waste SLOADs.

		// check invariants are preserved
		require(ask * order.buy_amt <= bid * order.sell_amt); // overflow?

		// if bid/ask exceeds total order amount, simply fill entire order
		uint put;
		uint get;

		if (bid <= order.buy_amt)
			put = bid;
		else
			put = order.buy_amt;

		if (ask <= order.sell_amt)
			get = ask;
		else
			get = order.sell_amt;

		// update storage
		order_book[owner][buy_tok][sell_tok].sell_amt = order.sell_amt - get;
		order_book[owner][buy_tok][sell_tok].buy_amt = order.buy_amt - put;

		// and now actually do the transfers
		IERC20(sell_tok).transfer(msg.sender, get);
		IERC20(buy_tok).transferFrom(msg.sender, owner, put);
	}

	function cancel_order(address buy_tok, address sell_tok) public {
		// cache sell order for refund (or do this before require())
		uint refund = order_book[msg.sender][buy_tok][sell_tok].sell_amt;

		order_book[msg.sender][buy_tok][sell_tok].buy_amt = 0;
		order_book[msg.sender][buy_tok][sell_tok].sell_amt = 0;

		// and return the tokens
		// questions: 
		// 1. What context is this called in? Does it use DELEGATECALL?
		IERC20(sell_tok).transfer(msg.sender, refund);
	}

	function adjust_order(
		address buy_tok, address sell_tok, 
		int buy_adj, int sell_adj
	) public {
		// change order by adding or retrieving tokens
		// adjustment may be positive or negative in either variable
		// adjustment does not emit an event

	/*	order_book[msg.sender][order.buy_tok][order.sell_tok] 
			= OrderState(order.buy_amount, order.sell_amount);
		
		// and actually transfer the tokens
		IERC20(order.sell_tok).transferFrom(
			msg.sender, 
			address(this), 
			order.sell_amount
		);
	*/
	}

}
