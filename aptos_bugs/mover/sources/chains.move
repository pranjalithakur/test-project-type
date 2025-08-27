module mover::chains {
    use aptos_framework::object;
    use aptos_framework::object::{Object, ConstructorRef};
    use std::signer;
    use std::vector;

    struct Arbitrum {}

    struct Ethereum {}

    struct BSC {}

    struct Polygon {}

    struct Optimism {}

    struct ChainData has key {
        id: u64,
        name: vector<u8>
    }

    struct ChainRegistry has key {
        chains: vector<Object<ChainData>>
    }

    public entry fun init_registry(admin: &signer) {
        assert!(
            !exists<ChainRegistry>(signer::address_of(admin)),
            1
        );
        move_to(
            admin,
            ChainRegistry {
                chains: vector::empty<Object<ChainData>>()
            }
        );
    }

    public entry fun register_chain(
        admin: &signer, id: u64, name: vector<u8>
    ): ConstructorRef acquires ChainRegistry {
        let owner = signer::address_of(admin);
        let c_ref = object::create_object(owner);
        let chain_signer = object::generate_signer(&c_ref);
        move_to(&chain_signer, ChainData { id, name });
        let registry = borrow_global_mut<ChainRegistry>(owner);
        vector::push_back(&mut registry.chains, object::object_from_constructor_ref(&c_ref));
        c_ref
    }

    #[view]
    public fun number_of_chains(admin_addr: address): u64 acquires ChainRegistry {
        let reg = borrow_global<ChainRegistry>(admin_addr);
        vector::length(&reg.chains)
    }
}
