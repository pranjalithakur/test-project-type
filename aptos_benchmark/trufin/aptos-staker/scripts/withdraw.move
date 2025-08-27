script {
    use std::vector;
    use std::string;
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use publisher::staker;
    use aptos_framework::delegation_pool;
    use aptos_std::debug;

    const UNLOCK_AMOUNT: u64 = 10_000_000_00; //10 APT

    fun withdraw(user: &signer) {
        // Add your nonces from unlock script execution here. Should be same length as pools.
        let nonces: vector<u64> = vector[56,57,58]; 

        let pools: vector<address> = vector[
            @0x7a2ddb6af66beb0d9987c6c9010cb9053454f067e16775a8ecf19961195c3d28,
            @0xa4113560d0b18ba38797f2a899c4b27e0c5b0476be5d8f6be68fba8b1861ed0, 
            @0xa562415be88d9f08ba98fa3f6af9be0e36580c0f8fff5100a50b519e8f4a15c9];

        let user_addr = signer::address_of(user);
        
        let i = 0;
        while(i < vector::length(&nonces)) {
            let pool = vector::borrow(&pools, i);
            let nonce = vector::borrow(&nonces, i);
            
            let balance_before = coin::balance<AptosCoin>(@publisher);
            let balance_user_before = coin::balance<AptosCoin>(user_addr);   
            let( _, pre_inactive, pre_pending_inactive) = delegation_pool::get_stake(*pool, @publisher);
            let (pre_price_num, pre_price_denom) = staker::share_price();

            staker::withdraw(user, *nonce);

            let balance_after = coin::balance<AptosCoin>(@publisher);
            let balance_user = coin::balance<AptosCoin>(user_addr);   
            let( _, inactive, pending_inactive) = delegation_pool::get_stake(*pool, @publisher);
            let (price_num, price_denom) = staker::share_price();

            // checks 
            assert!(inactive == 0, 0); // should withdraw entire inactive amount
            assert!(pre_pending_inactive == pending_inactive, 1); // pending_inactive should not change
            assert!(pre_price_num/pre_price_denom == price_num/price_denom, 2); // share price should not change
            assert!(balance_after + UNLOCK_AMOUNT == balance_before + pre_inactive, 3);
            assert!(balance_user == balance_user_before + UNLOCK_AMOUNT, 4);

            debug::print(&string::utf8(b"Pool:"));
            debug::print(&(*pool));

            debug::print(&string::utf8(b"Nonce:"));
            debug::print(&(*nonce));

            debug::print(&string::utf8(b"How much is moved into the staker vs amount of inactive stake:"));
            debug::print(&(balance_after + UNLOCK_AMOUNT - balance_before));
            debug::print(&pre_inactive);
            
            debug::print(&string::utf8(b"How much has the user received:"));
            debug::print(&(balance_user - balance_user_before));

            i = i+1;
        }
    }
}