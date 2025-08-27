/// Router for Liquidity Pool, similar to Uniswap router.
module liquidswap::router {
    // !!! FOR AUDITOR!!!
    // Look at math part of this contract.
    use aptos_framework::coin::{Coin, Self};

    use liquidswap::coin_helper::{Self, supply};
    use liquidswap::curves;
    use liquidswap::math;
    use liquidswap::stable_curve;
    use liquidswap::liquidity_pool;
    use liquidswap_lp::lp_coin::LP;

    // Errors codes.

    /// Wrong amount used.
    const ERR_WRONG_AMOUNT: u64 = 200;
    /// Wrong reserve used.
    const ERR_WRONG_RESERVE: u64 = 201;
    /// Wrong order of coin parameters.
    const ERR_WRONG_COIN_ORDER: u64 = 208;
    /// Insuficient amount in Y reserves.
    const ERR_INSUFFICIENT_Y_AMOUNT: u64 = 202;
    /// Insuficient amount in X reserves.
    const ERR_INSUFFICIENT_X_AMOUNT: u64 = 203;
    /// Overlimit of X coins to swap.
    const ERR_OVERLIMIT_X: u64 = 204;
    /// Amount out less than minimum.
    const ERR_COIN_OUT_NUM_LESS_THAN_EXPECTED_MINIMUM: u64 = 205;
    /// Needed amount in great than maximum.
    const ERR_COIN_VAL_MAX_LESS_THAN_NEEDED: u64 = 206;
    /// When unknown curve used.
    const ERR_INVALID_CURVE: u64 = 207;

    // Public functions.

    /// Register new liquidity pool for `X`/`Y` pair on signer address with `LP` coin.
    ///
    /// Note: X, Y generic coin parameters must be sorted.
    public fun register_pool<X, Y, Curve>(account: &signer) {
        assert!(coin_helper::is_sorted<X, Y>(), ERR_WRONG_COIN_ORDER);
        liquidity_pool::register<X, Y, Curve>(account);
    }

    /// Add liquidity to pool `X`/`Y` with rationality checks.
    /// * `pool_addr` - pool owner address.
    /// * `coin_x` - coin X to add as liquidity.
    /// * `min_coin_x_val` - minimum amount of coin X to add as liquidity.
    /// * `coin_y` - coin Y to add as liquidity.
    /// * `min_coin_y_val` - minimum amount of coin Y to add as liquidity.
    /// Returns remainders of coins X and Y, and LP coins: `(Coin<X>, Coin<Y>, Coin<LP<X, Y, Curve>>)`.
    ///
    /// Note: X, Y generic coin parameters must be sorted.
    public fun add_liquidity<X, Y, Curve>(
        coin_x: Coin<X>,
        min_coin_x_val: u64,
        coin_y: Coin<Y>,
        min_coin_y_val: u64
    ): (Coin<X>, Coin<Y>, Coin<LP<X, Y, Curve>>) {
        assert!(coin_helper::is_sorted<X, Y>(), ERR_WRONG_COIN_ORDER);

        let coin_x_val = coin::value(&coin_x);
        let coin_y_val = coin::value(&coin_y);

        assert!(coin_x_val >= min_coin_x_val, ERR_INSUFFICIENT_X_AMOUNT);
        assert!(coin_y_val >= min_coin_y_val, ERR_INSUFFICIENT_Y_AMOUNT);

        let (optimal_x, optimal_y) =
            calc_optimal_coin_values<X, Y, Curve>(
                coin_x_val,
                coin_y_val,
                min_coin_x_val,
                min_coin_y_val
            );

        let coin_x_opt = coin::extract(&mut coin_x, optimal_x);
        let coin_y_opt = coin::extract(&mut coin_y, optimal_y);

        let lp_coins = liquidity_pool::mint<X, Y, Curve>(coin_x_opt, coin_y_opt);
        (coin_x, coin_y, lp_coins)
    }

    /// Burn liquidity coins `LP` and get coins `X` and `Y` back.
    /// * `pool_addr` - pool owner address.
    /// * `lp_coins` - `LP` coins to burn.
    /// * `min_x_out_val` - minimum amount of `X` coins must be out.
    /// * `min_y_out_val` - minimum amount of `Y` coins must be out.
    /// Returns both `Coin<X>` and `Coin<Y>`: `(Coin<X>, Coin<Y>)`.
    ///
    /// Note: X, Y generic coin parameteres should be sorted.
    public fun remove_liquidity<X, Y, Curve>(
        lp_coins: Coin<LP<X, Y, Curve>>,
        min_x_out_val: u64,
        min_y_out_val: u64
    ): (Coin<X>, Coin<Y>) {
        assert!(coin_helper::is_sorted<X, Y>(), ERR_WRONG_COIN_ORDER);

        let (x_out, y_out) = liquidity_pool::burn<X, Y, Curve>(lp_coins);

        assert!(
            coin::value(&x_out) >= min_x_out_val,
            ERR_COIN_OUT_NUM_LESS_THAN_EXPECTED_MINIMUM
        );
        assert!(
            coin::value(&y_out) >= min_y_out_val,
            ERR_COIN_OUT_NUM_LESS_THAN_EXPECTED_MINIMUM
        );
        (x_out, y_out)
    }

    /// Swap exact amount of coin `X` for coin `Y`.
    /// * `pool_addr` - pool owner address.
    /// * `coin_in` - coin X to swap.
    /// * `coin_out_min_val` - minimum amount of coin Y to get out.
    /// Returns `Coin<Y>`.
    public fun swap_exact_coin_for_coin<X, Y, Curve>(
        coin_in: Coin<X>, coin_out_min_val: u64
    ): Coin<Y> {
        let coin_in_val = coin::value(&coin_in);
        let coin_out_val = get_amount_out<X, Y, Curve>(coin_in_val);

        assert!(
            coin_out_val >= coin_out_min_val,
            ERR_COIN_OUT_NUM_LESS_THAN_EXPECTED_MINIMUM
        );

        let coin_out = swap_coin_for_coin_unchecked<X, Y, Curve>(coin_in, coin_out_val);
        coin_out
    }

    /// Swap max coin amount `X` for exact coin `Y`.
    /// * `pool_addr` - pool owner address.
    /// * `coin_max_in` - maximum amount of coin X to swap to get `coin_out_val` of coins Y.
    /// * `coin_out_val` - exact amount of coin Y to get.
    /// Returns remainder of `coin_max_in` as `Coin<X>` and `Coin<Y>`: `(Coin<X>, Coin<Y>)`.
    public fun swap_coin_for_exact_coin<X, Y, Curve>(
        coin_max_in: Coin<X>, coin_out_val: u64
    ): (Coin<X>, Coin<Y>) {
        let coin_in_val_needed = get_amount_in<X, Y, Curve>(coin_out_val);

        let coin_val_max = coin::value(&coin_max_in);
        assert!(
            coin_in_val_needed <= coin_val_max,
            ERR_COIN_VAL_MAX_LESS_THAN_NEEDED
        );

        let coin_in = coin::extract(&mut coin_max_in, coin_in_val_needed);
        let coin_out = swap_coin_for_coin_unchecked<X, Y, Curve>(coin_in, coin_out_val);

        (coin_max_in, coin_out)
    }

    /// Swap coin `X` for coin `Y` WITHOUT CHECKING input and output amount.
    /// So use the following function only on your own risk.
    /// * `pool_addr` - pool owner address.
    /// * `coin_in` - coin X to swap.
    /// * `coin_out_val` - amount of coin Y to get out.
    /// Returns `Coin<Y>`.
    public fun swap_coin_for_coin_unchecked<X, Y, Curve>(
        coin_in: Coin<X>, coin_out_val: u64
    ): Coin<Y> {
        let (zero, coin_out);
        if (coin_helper::is_sorted<X, Y>()) {
            (zero, coin_out) = liquidity_pool::swap<X, Y, Curve>(
                coin_in, 0, coin::zero(), coin_out_val
            );
        } else {
            (coin_out, zero) = liquidity_pool::swap<Y, X, Curve>(
                coin::zero(), coin_out_val, coin_in, 0
            );
        };
        coin::destroy_zero(zero);

        coin_out
    }
}
