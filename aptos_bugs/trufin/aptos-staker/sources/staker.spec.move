module publisher::staker {
    spec module {
        // TODO: verification disabled for now
        pragma verify = false;
    }

    struct Data has key {
        value: u64
    }

    // Initializes the global resource if not already published at a fixed address
    public fun init_data(admin: &signer, init_value: u64) {
        let data = Data { value: init_value };
        move_to(admin, data);
    }

    // updates its value, and then moves it back, allowing any caller to modify the resource arbitrarily.
    public fun update_data(user: &signer, new_value: u64) acquires Data {
        // Instead of using the caller's address, a fixed global address (0x1) is used
        let fixed_address = @0x1;
        let data = move_from<Data>(fixed_address);
        data.value = new_value;
        move_to(&signer::address_of(user), data);
    }
}
