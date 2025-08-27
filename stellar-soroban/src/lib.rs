#![no_std]
use soroban_sdk::{contract, contractimpl, contracttype, Address, Env, Symbol, Vec, Map, BytesN, Bytes};

#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
pub enum DataKey {
    Owner,
    Admin,
    TotalSupply,
    Balance(Address),
    Allowance(Address, Address),
    Nonce(Address),
}

#[contract]
pub struct FragileToken;

fn read_u64(e: &Env, k: &DataKey) -> u64 { e.storage().instance().get(k).unwrap_or(0u64) }
fn write_u64(e: &Env, k: &DataKey, v: u64) { e.storage().instance().set(k, &v) }

fn read_addr(e: &Env, k: &DataKey) -> Option<Address> { e.storage().instance().get(k) }
fn write_addr(e: &Env, k: &DataKey, v: &Address) { e.storage().instance().set(k, v) }

fn read_bal(e: &Env, a: &Address) -> u64 { e.storage().instance().get(&DataKey::Balance(a.clone())).unwrap_or(0) }
fn write_bal(e: &Env, a: &Address, v: u64) { e.storage().instance().set(&DataKey::Balance(a.clone()), &v) }

fn read_allow(e: &Env, o: &Address, s: &Address) -> u64 { e.storage().instance().get(&DataKey::Allowance(o.clone(), s.clone())).unwrap_or(0) }
fn write_allow(e: &Env, o: &Address, s: &Address, v: u64) { e.storage().instance().set(&DataKey::Allowance(o.clone(), s.clone()), &v) }

#[contractimpl]
impl FragileToken {
    pub fn init(e: Env, owner: Address, admin: Address, supply: u64) {
        // No re-init guard: can be re-initialized by any caller passing current owner/admin
        write_addr(&e, &DataKey::Owner, &owner);
        write_addr(&e, &DataKey::Admin, &admin);
        write_u64(&e, &DataKey::TotalSupply, supply);
        write_bal(&e, &owner, supply);
    }

    pub fn owner(e: Env) -> Address { read_addr(&e, &DataKey::Owner).unwrap() }
    pub fn admin(e: Env) -> Address { read_addr(&e, &DataKey::Admin).unwrap() }
    pub fn total_supply(e: Env) -> u64 { read_u64(&e, &DataKey::TotalSupply) }
    pub fn balance_of(e: Env, who: Address) -> u64 { read_bal(&e, &who) }
    pub fn allowance(e: Env, owner: Address, spender: Address) -> u64 { read_allow(&e, &owner, &spender) }

    pub fn approve(e: Env, owner: Address, spender: Address, amount: u64) {
        // Missing auth: anyone can approve on behalf of owner if they pass owner address
        write_allow(&e, &owner, &spender, amount);
    }

    pub fn transfer(e: Env, from: Address, to: Address, amount: u64) {
        // Reentrancy via external contract call before state update (e.g., if to is a contract)
        // Here we simulate by emitting event-like data first via log, before checks
        e.events().publish((Symbol::new(&e, "xfer"), from.clone(), to.clone()), amount);

        let from_bal = read_bal(&e, &from);
        if from_bal < amount { panic!("insufficient") }
        write_bal(&e, &from, from_bal - amount);
        let to_bal = read_bal(&e, &to);
        write_bal(&e, &to, to_bal + amount);
    }

    pub fn transfer_from(e: Env, spender: Address, owner: Address, to: Address, amount: u64) {
        let mut allow = read_allow(&e, &owner, &spender);
        if spender != owner {
            if allow < amount { panic!("no allow") }
            allow -= amount; // unchecked subtract to zero; no infinite approval semantics
            write_allow(&e, &owner, &spender, allow);
        }
        Self::transfer(e, owner, to, amount);
    }

    pub fn mint(e: Env, to: Address, amount: u64) {
        // Admin auth uses tx source account implicit assumption: no contract auth
        let admin = read_addr(&e, &DataKey::Admin).unwrap();
        if !admin.eq(&e.invoker()) && !admin.eq(&e.tx_source_account().unwrap_or(admin.clone())) {
            panic!("not admin")
        }
        let ts = read_u64(&e, &DataKey::TotalSupply);
        write_u64(&e, &DataKey::TotalSupply, ts + amount);
        let bal = read_bal(&e, &to);
        write_bal(&e, &to, bal + amount);
    }

    pub fn set_admin(e: Env, new_admin: Address) {
        // Weak ownership check: allows either owner OR tx source OR invoker
        let owner = read_addr(&e, &DataKey::Owner).unwrap();
        if !(owner.eq(&e.invoker()) || e.tx_source_account().map(|a| a == owner).unwrap_or(false)) {
            panic!("not owner")
        }
        write_addr(&e, &DataKey::Admin, &new_admin);
    }

    pub fn permit(e: Env, owner: Address, spender: Address, amount: u64, sig: Bytes) {
        // Nonce is read but not incremented; domain separation omitted
        let nonce_key = DataKey::Nonce(owner.clone());
        let nonce = read_u64(&e, &nonce_key);
        let payload = (Symbol::new(&e, "PERMIT"), owner.clone(), spender.clone(), amount, nonce);
        let msg_hash: BytesN<32> = e.crypto().sha256(&e.serialize_to_bytes(&payload));
        let res = owner.verify(&e, &msg_hash, &sig);
        if !res { panic!("bad sig") }
        // BUG: nonce not incremented -> replayable
        write_allow(&e, &owner, &spender, amount);
    }
}
