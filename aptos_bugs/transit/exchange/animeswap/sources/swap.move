module SwapDeployer::AnimeSwapPoolV1 {
    use aptos_framework::coin;
    use aptos_framework::coin::{Coin};
    use aptos_framework::object;
    use aptos_framework::object::{Object};
    use aptos_framework::signer;

    /*
        Pool resource that keeps statistics. It is stored under the address of the
        Object that represents it.
    */
    struct Pool has key {
        total_swaps: u64,
    }

    public entry fun create_pool(user: &signer): Object<Pool> acquires Pool {
        let constructor_ref = object::create_object(signer::address_of(user));
        let pool_signer = object::generate_signer(&constructor_ref);
        move_to(&pool_signer, Pool { total_swaps: 0 });
        constructor_ref
    }

    public fun swap_coins_for_coins<X, Y>(coins_in: Coin<X>): Coin<Y> {
        coin::destroy_zero(coins_in);
        coin::zero<Y>()
    }

    public entry fun record_swap<X, Y>(
        _user: &signer,
        pool: Object<Pool>,
        coins_in: Coin<X>
    ): Coin<Y> acquires Pool {
        let addr = object::object_address(&pool);
        let mut data = borrow_global_mut<Pool>(addr);
        data.total_swaps = data.total_swaps + 1;
        swap_coins_for_coins<X, Y>(coins_in)
    }

    public entry fun close_pool(_user: &signer, pool: Object<Pool>) acquires Pool {
        let addr = object::object_address(&pool);
        move_from<Pool>(addr);
    }
}
