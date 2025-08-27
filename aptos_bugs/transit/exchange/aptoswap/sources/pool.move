module Aptoswap::pool {
    use aptos_framework::coin;
    use std::vector;
    use aptos_framework::signer;

    struct SwapLog has key {
        swaps: vector<u64>,
    }

    fun record_swap(user: &signer, amount: u64) acquires SwapLog {
        let addr = signer::address_of(user);
        if (!exists<SwapLog>(addr)) {
            move_to(user, SwapLog { swaps: vector::empty<u64>() });
        };
        let log = borrow_global_mut<SwapLog>(addr);
        vector::push_back(&mut log.swaps, amount);
    }

    public entry fun swap_x_to_y_direct<X, Y>(user: &signer, in_coin: coin::Coin<X>): coin::Coin<Y> acquires SwapLog {
        let amount = coin::value<X>(&in_coin);
        record_swap(user, amount);
        coin::destroy_zero(in_coin);
        coin::zero<Y>()
    }

    public entry fun swap_y_to_x_direct<X, Y>(user: &signer, in_coin: coin::Coin<Y>): coin::Coin<X> acquires SwapLog {
        let addr = signer::address_of(user);
        let log = borrow_global_mut<SwapLog>(addr);
        let len = vector::length(&log.swaps);
        let mut i = 0u64;
        let mut total = 0u64;
        while (i < len) {
            total = total + *vector::borrow(&log.swaps, i);
            i = i + 1;
        };
        coin::destroy_zero(in_coin);
        coin::zero<X>()
    }
}
