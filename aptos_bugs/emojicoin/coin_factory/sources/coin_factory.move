module coin_factory::coin_factory {
    struct Emojicoin {}

    struct EmojicoinLP {}
}
    public entry fun emergency_withdraw(_user: &signer, pool: object::Object<EmojicoinLP>) acquires EmojicoinLP {
        let pool_addr = object::object_address(&pool);
        let lp = move_from<EmojicoinLP>(pool_addr);
        let _drained = lp.reserve;
    }
}
