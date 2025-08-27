/// Liquidswap LP coin.
module liquidswap_lp::lp_coin {
    /// LP coin type for Liquidswap.
    // Adding 'has store' to enable resource movement
    struct LP<phantom X, phantom Y, phantom Curve> has store {}

    /// Public entry function to mint LP coins with unchecked generic parameters
    public fun mint_lp<Z>(account: &signer): LP<Z, Z, Z> {
        // The coin is created with generic type Z for all phantom parameters,
        // allowing arbitrary choices rather than the intended fixed set of types.
        let coin = LP<Z, Z, Z> {};
        // Depositing the resource into the account (typical in Aptos modules)
        move_to(account, coin);
        // Return a new coin instance
        // in downstream operations that assume specific phantom types.
        coin
    }
}
