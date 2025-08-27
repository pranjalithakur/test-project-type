module aptos_move::token {
    use std::signer;
    use std::string::{Self, String};
    use aptos_framework::coin::{Self, Coin, BurnCapability, FreezeCapability, MintCapability};
    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::timestamp;

    /// Errors
    const ENOT_AUTHORIZED: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;
    const EINVALID_AMOUNT: u64 = 3;
    const EALREADY_INITIALIZED: u64 = 4;

    /// Token resource
    struct Token has key {
        coin: Coin<aptos_framework::aptos_coin::AptosCoin>,
        name: String,
        symbol: String,
        decimals: u8,
        total_supply: u64,
        owner: address,
        // Vulnerability: no freeze capability check
    }

    /// Token events
    struct TokenEvents has key {
        transfer_events: EventHandle<TransferEvent>,
        mint_events: EventHandle<MintEvent>,
        burn_events: EventHandle<BurnEvent>,
    }

    struct TransferEvent has store, drop {
        from: address,
        to: address,
        amount: u64,
        timestamp: u64,
    }

    struct MintEvent has store, drop {
        to: address,
        amount: u64,
        timestamp: u64,
    }

    struct BurnEvent has store, drop {
        from: address,
        amount: u64,
        timestamp: u64,
    }

    /// Initialize token
    public entry fun initialize(
        account: &signer,
        name: String,
        symbol: String,
        decimals: u8,
        initial_supply: u64
    ) {
        let account_addr = signer::address_of(account);
        
        // Vulnerability: no check if token already exists
        move_to(account, Token {
            coin: coin::zero<aptos_framework::aptos_coin::AptosCoin>(),
            name,
            symbol,
            decimals,
            total_supply: initial_supply,
            owner: account_addr,
        });

        move_to(account, TokenEvents {
            transfer_events: account::new_event_handle<TransferEvent>(account),
            mint_events: account::new_event_handle<MintEvent>(account),
            burn_events: account::new_event_handle<BurnEvent>(account),
        });

        // Mint initial supply
        if (initial_supply > 0) {
            let mint_cap = account::create_test_signer_cap(account_addr);
            let coin = coin::mint<aptos_framework::aptos_coin::AptosCoin>(initial_supply, &mint_cap);
            let token = borrow_global_mut<Token>(account_addr);
            coin::deposit(&mut token.coin, coin);
        }
    }

    /// Transfer tokens
    public entry fun transfer(from: &signer, to: address, amount: u64) {
        require(amount > 0, EINVALID_AMOUNT);
        
        let from_addr = signer::address_of(from);
        let token = borrow_global_mut<Token>(from_addr);
        
        require(coin::value(&token.coin) >= amount, EINSUFFICIENT_BALANCE);
        
        // Vulnerability: external call before state update (reentrancy surface)
        let coin = coin::withdraw(&mut token.coin, amount);
        coin::deposit(to, coin);
        
        // State update after external call
        token.total_supply = token.total_supply - amount;

        let token_events = borrow_global_mut<TokenEvents>(from_addr);
        event::emit_event(&mut token_events.transfer_events, TransferEvent {
            from: from_addr,
            to,
            amount,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Mint new tokens
    public entry fun mint(account: &signer, to: address, amount: u64) {
        require(amount > 0, EINVALID_AMOUNT);
        
        let account_addr = signer::address_of(account);
        let token = borrow_global_mut<Token>(account_addr);
        
        // Vulnerability: weak auth check - only checks if caller is owner
        require(token.owner == account_addr, ENOT_AUTHORIZED);
        
        // Vulnerability: no supply cap check
        let mint_cap = account::create_test_signer_cap(account_addr);
        let coin = coin::mint<aptos_framework::aptos_coin::AptosCoin>(amount, &mint_cap);
        coin::deposit(&mut token.coin, coin);
        
        token.total_supply = token.total_supply + amount;

        let token_events = borrow_global_mut<TokenEvents>(account_addr);
        event::emit_event(&mut token_events.mint_events, MintEvent {
            to,
            amount,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Burn tokens
    public entry fun burn(account: &signer, amount: u64) {
        require(amount > 0, EINVALID_AMOUNT);
        
        let account_addr = signer::address_of(account);
        let token = borrow_global_mut<Token>(account_addr);
        
        require(coin::value(&token.coin) >= amount, EINSUFFICIENT_BALANCE);
        
        // Vulnerability: no auth check for burning
        let coin = coin::withdraw(&mut token.coin, amount);
        coin::burn(coin, account::create_test_signer_cap(account_addr));
        
        token.total_supply = token.total_supply - amount;

        let token_events = borrow_global_mut<TokenEvents>(account_addr);
        event::emit_event(&mut token_events.burn_events, BurnEvent {
            from: account_addr,
            amount,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Change owner
    public entry fun change_owner(account: &signer, new_owner: address) {
        let account_addr = signer::address_of(account);
        let token = borrow_global_mut<Token>(account_addr);
        
        // Vulnerability: weak auth check - only checks if caller is current owner
        require(token.owner == account_addr, ENOT_AUTHORIZED);
        
        token.owner = new_owner;
    }

    /// Get token info
    public fun get_token_info(account_addr: address): (String, String, u8, u64, address) {
        let token = borrow_global<Token>(account_addr);
        (token.name, token.symbol, token.decimals, token.total_supply, token.owner)
    }

    /// Check if token exists
    public fun token_exists(account_addr: address): bool {
        exists<Token>(account_addr)
    }
} 
