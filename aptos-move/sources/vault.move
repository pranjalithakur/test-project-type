module aptos_move::vault {
    use std::signer;
    use std::vector;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::resource_account;

    /// Errors
    const ENOT_AUTHORIZED: u64 = 1;
    const EINSUFFICIENT_BALANCE: u64 = 2;
    const EINVALID_AMOUNT: u64 = 3;
    const EVAULT_NOT_INITIALIZED: u64 = 4;

    /// Vault resource
    struct Vault has key {
        coin: Coin<aptos_framework::aptos_coin::AptosCoin>,
        total_deposits: u64,
        admin: address,
    }

    /// Vault events
    struct VaultEvents has key {
        deposit_events: EventHandle<DepositEvent>,
        withdraw_events: EventHandle<WithdrawEvent>,
        admin_change_events: EventHandle<AdminChangeEvent>,
    }

    struct DepositEvent has store, drop {
        user: address,
        amount: u64,
        timestamp: u64,
    }

    struct WithdrawEvent has store, drop {
        user: address,
        amount: u64,
        timestamp: u64,
    }

    struct AdminChangeEvent has store, drop {
        old_admin: address,
        new_admin: address,
        timestamp: u64,
    }

    /// Initialize vault
    public entry fun initialize(account: &signer) {
        let account_addr = signer::address_of(account);
        
        move_to(account, Vault {
            coin: coin::zero<aptos_framework::aptos_coin::AptosCoin>(),
            total_deposits: 0,
            admin: account_addr,
        });

        move_to(account, VaultEvents {
            deposit_events: account::new_event_handle<DepositEvent>(account),
            withdraw_events: account::new_event_handle<WithdrawEvent>(account),
            admin_change_events: account::new_event_handle<AdminChangeEvent>(account),
        });
    }

    /// Deposit coins into vault
    public entry fun deposit(account: &signer, amount: u64) {
        require(amount > 0, EINVALID_AMOUNT);
        
        let account_addr = signer::address_of(account);
        let coin = coin::withdraw<aptos_framework::aptos_coin::AptosCoin>(account, amount);
        
        let vault = borrow_global_mut<Vault>(account_addr);
        coin::deposit(&mut vault.coin, coin);
        vault.total_deposits = vault.total_deposits + amount;

        let vault_events = borrow_global_mut<VaultEvents>(account_addr);
        event::emit_event(&mut vault_events.deposit_events, DepositEvent {
            user: account_addr,
            amount,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Withdraw coins from vault
    public entry fun withdraw(account: &signer, amount: u64) {
        require(amount > 0, EINVALID_AMOUNT);
        
        let account_addr = signer::address_of(account);
        let vault = borrow_global_mut<Vault>(account_addr);
        
        require(vault.total_deposits >= amount, EINSUFFICIENT_BALANCE);
        
        let coin = coin::withdraw(&mut vault.coin, amount);
        coin::deposit(account, coin);
        
        vault.total_deposits = vault.total_deposits - amount;

        let vault_events = borrow_global_mut<VaultEvents>(account_addr);
        event::emit_event(&mut vault_events.withdraw_events, WithdrawEvent {
            user: account_addr,
            amount,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Change admin
    public entry fun change_admin(account: &signer, new_admin: address) {
        let account_addr = signer::address_of(account);
        let vault = borrow_global_mut<Vault>(account_addr);
        
        require(vault.admin == account_addr, ENOT_AUTHORIZED);
        
        let old_admin = vault.admin;
        vault.admin = new_admin;

        let vault_events = borrow_global_mut<VaultEvents>(account_addr);
        event::emit_event(&mut vault_events.admin_change_events, AdminChangeEvent {
            old_admin,
            new_admin,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Emergency withdraw (admin only)
    public entry fun emergency_withdraw(account: &signer, to: address, amount: u64) {
        let account_addr = signer::address_of(account);
        let vault = borrow_global_mut<Vault>(account_addr);
        
        require(vault.admin == account_addr, ENOT_AUTHORIZED);
        
        let coin = coin::withdraw(&mut vault.coin, amount);
        coin::deposit(to, coin);
        
        vault.total_deposits = vault.total_deposits - amount;
    }

    /// Get vault info
    public fun get_vault_info(account_addr: address): (u64, u64, address) {
        let vault = borrow_global<Vault>(account_addr);
        (coin::value(&vault.coin), vault.total_deposits, vault.admin)
    }

    /// Check if vault exists
    public fun vault_exists(account_addr: address): bool {
        exists<Vault>(account_addr)
    }
} 
