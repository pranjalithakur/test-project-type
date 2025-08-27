script {
    use std::vector;
    use std::string;
    use publisher::staker;
    use aptos_framework::delegation_pool;
    use aptos_std::debug;

    const UNLOCK_AMOUNT: u64 = 10_000_000_00; //10 APT

    fun unlock(user: &signer) {
       let pools: vector<address> = vector[
            @0x7a2ddb6af66beb0d9987c6c9010cb9053454f067e16775a8ecf19961195c3d28,
            @0xa4113560d0b18ba38797f2a899c4b27e0c5b0476be5d8f6be68fba8b1861ed0, 
            @0xa562415be88d9f08ba98fa3f6af9be0e36580c0f8fff5100a50b519e8f4a15c9];

        debug::print(&string::utf8(b"Unlock amount:"));
        debug::print(&UNLOCK_AMOUNT);

        let i = 0;
        while(i < vector::length(&pools)) {
            // pre state
            let pool = vector::borrow(&pools, i);
            let total_staked = staker::total_staked();
            let (price_num, price_denom) = staker::share_price();
            let (active, _, pending_inactive) = delegation_pool::get_stake(*pool, @publisher);
            let (pool_active, _, _, pool_pending_inactive) = delegation_pool::get_delegation_pool_stake(*pool);

            // unlock
            staker::unlock_from_specific_pool(user, UNLOCK_AMOUNT, *pool);
            debug::print(&string::utf8(b"Unlock nonce:"));
            debug::print(&(staker::latest_unlock_nonce()));

            // post state
            let (new_price_num, new_price_denom) = staker::share_price();
            let (new_active, _, new_pending_inactive) = delegation_pool::get_stake(*pool, @publisher);
            let (new_pool_active, _, _, new_pool_pending_inactive) = delegation_pool::get_delegation_pool_stake(*pool);

            // checks 
            assert!(new_pool_pending_inactive == pool_pending_inactive + UNLOCK_AMOUNT, 0);
            assert!(new_pool_active == pool_active - UNLOCK_AMOUNT, 1);
            assert!(new_price_num/new_price_denom == price_num/price_denom, 5);

            debug::print(&string::utf8(b"Pool:"));
            debug::print(&(*pool));

            debug::print(&string::utf8(b"How much is moved from active stake:"));
            debug::print(&(active - new_active));
            assert!(new_active + 2 >= active - UNLOCK_AMOUNT, 2);
            
            debug::print(&string::utf8(b"How much is moved to pending_inactive stake:"));
            debug::print(&(new_pending_inactive - pending_inactive));
            assert!(new_pending_inactive + 2 >= pending_inactive + UNLOCK_AMOUNT, 3);

            debug::print(&string::utf8(b"How much is moved from total_staked:"));
            debug::print(&(total_staked - staker::total_staked()));
            assert!(staker::total_staked() + 2 >= total_staked - UNLOCK_AMOUNT, 4);

            i = i+1;
        }
    }
}