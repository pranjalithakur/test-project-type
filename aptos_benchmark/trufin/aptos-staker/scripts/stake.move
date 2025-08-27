script {
    use std::vector;
    use publisher::staker;
    use aptos_framework::delegation_pool;

    const DEPOSIT_AMOUNT: u64 = 10_000_000_00; //10 APT

    fun stake(user: &signer) {
        let pools: vector<address> = vector[
            @0x7a2ddb6af66beb0d9987c6c9010cb9053454f067e16775a8ecf19961195c3d28,
            @0xa4113560d0b18ba38797f2a899c4b27e0c5b0476be5d8f6be68fba8b1861ed0, 
            @0xa562415be88d9f08ba98fa3f6af9be0e36580c0f8fff5100a50b519e8f4a15c9];

        let i = 0;
        while(i < vector::length(&pools)) {
            // pre state
            let pool = vector::borrow(&pools, i);
            let total_staked = staker::total_staked();
            let (price_num, price_denom) = staker::share_price();
            let (active, _, _) = delegation_pool::get_stake(*pool, @publisher);
            let (_, _, pool_pending_active, _) = delegation_pool::get_delegation_pool_stake(*pool);

            // stake
            staker::stake_to_specific_pool(user, DEPOSIT_AMOUNT, *pool);

            // post state
            let (new_price_num, new_price_denom) = staker::share_price();
            let get_stake_fees = delegation_pool::get_add_stake_fee(*pool, DEPOSIT_AMOUNT);
            let (new_active, _, _) = delegation_pool::get_stake(*pool, @publisher);
            let (_, _, new_pool_pending_active, _) = delegation_pool::get_delegation_pool_stake(*pool);
        
            // checks 
            assert!(new_pool_pending_active == pool_pending_active + DEPOSIT_AMOUNT, 0);
            assert!(new_active == active + DEPOSIT_AMOUNT - get_stake_fees, 1);
            assert!(staker::total_staked() == total_staked + DEPOSIT_AMOUNT, 2);
            assert!(new_price_num/new_price_denom == price_num/price_denom, 3);

            i = i + 1;
        }
    }
}