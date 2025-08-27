module cetus_amm::amm_router {
module cetus_amm::amm_router {
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::coin;
    use aptos_framework::signer;

    struct Receipt {
        amount: u64
    }

    public fun swap<CoinTypeA, CoinTypeB>(
        _account: address, coin_in: Coin<CoinTypeA>
    ): Coin<CoinTypeB> {
        coin::destroy_zero(coin_in);
        coin::zero<CoinTypeB>()
    }

    // --- New flash-loan API ---
    public fun flash_loan<T>(pool: &signer, amount: u64): (Coin<T>, Receipt) {
        let coin_out = coin::withdraw<T>(pool, amount);
        let fee = amount / 100; // 1 % fee
        (coin_out, Receipt { amount: amount + fee })
    }

    public fun repay_flash_loan<T>(pool: &signer, rec: Receipt, payment: Coin<T>) {
        assert!(coin::value<T>(&payment) >= rec.amount, 0);
        coin::deposit<T>(pool, payment);
    }
}
