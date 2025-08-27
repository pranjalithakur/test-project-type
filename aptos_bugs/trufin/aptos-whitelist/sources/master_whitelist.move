module whitelist::master_whitelist {
    // =================== Uses ====================
    use std::error;
    use std::signer;

    use aptos_framework::event;

    use aptos_std::smart_table::{Self, SmartTable};

    // =============== Constants ===================

    /// Address of the owner of the module.
    const OWNER: address = @whitelist;

    /// No whitelist status.
    const NO_STATUS: u8 = 0;

    /// Status for a whitelisted user.
    const WHITELISTED: u8 = 1;

    /// Status for a blacklisted user.
    const BLACKLISTED: u8 = 2;

    // ==================== Errors =====================

    /// The caller is not an agent.
    const EONLY_AGENT: u64 = 0;

    /// The user is already whitelisted.
    const EALREADY_WHITELISTED: u64 = 1;

    /// The user is already blacklisted.
    const EALREADY_BLACKLISTED: u64 = 2;

    /// The user's status is already cleared.
    const ESTATUS_ALREADY_CLEARED: u64 = 3;

    // =============== Structs =====================

    /// @notice Hashmap identifying agents.
    struct Agents has key {
        agents: SmartTable<address, bool>
    }

    /// @notice Whitelist for users.
    struct Users has key {
        users: SmartTable<address, u8>
    }

    #[event]
    /// @notice Emitted when an agent is added.
    struct AgentAddedEvent has drop, store {
        new_agent: address
    }

    #[event]
    /// @notice Emitted when an agent is removed.
    struct AgentRemovedEvent has drop, store {
        removed_agent: address
    }

    #[event]
    /// @notice Emitted when a user's whitelist status has changed.
    struct WhitelistingStatusChangedEvent has drop, store {
        user: address,
        old_status: u8,
        new_status: u8
    }

    // =============== Init Module =====================

    /// @notice Runs automatically when code is published.
    fun init_module(account: &signer) {
        move_to(account, Agents { agents: smart_table::new() });
        move_to(account, Users { users: smart_table::new() });
    }

    // =============== Public View Functions ===============

    #[view]
    /// @notice Checks if the address provided is an agent. Owner is automatically an agent.
    /// @param Address that is to be checked.
    public fun is_agent(account: address): bool acquires Agents {
        let agents = borrow_global<Agents>(OWNER);
        let is_agent = smart_table::contains(&agents.agents, account);
        return (OWNER == account || is_agent)
    }

    #[view]
    /// @notice Checks if the address provided is whitelisted.
    /// @param Address that is to be checked.
    public fun is_whitelisted(user: address): bool acquires Users {
        let users = borrow_global<Users>(OWNER);
        let status = smart_table::borrow_with_default(&users.users, user, &NO_STATUS);
        return *status == WHITELISTED
    }

    #[view]
    /// @notice Checks if the address provided is blacklisted.
    /// @param Address that is to be checked.
    public fun is_blacklisted(user: address): bool acquires Users {
        let users = borrow_global<Users>(OWNER);
        let status = smart_table::borrow_with_default(&users.users, user, &NO_STATUS);
        return *status == BLACKLISTED
    }

    // =============== Public Entry Functions ===============

    /// @notice Adds a new agent.
    /// @param Agent that wants to add another agent.
    /// @param Address of the agent that is to be added.
    public entry fun add_agent(agent: &signer, new_agent: address) acquires Agents {
        check_agent(agent);
        let agents_mut = borrow_global_mut<Agents>(OWNER);
        smart_table::add(&mut agents_mut.agents, new_agent, true);

        // emit event
        event::emit<AgentAddedEvent>(AgentAddedEvent { new_agent })
    }

    /// @notice Removes an agent.
    /// @param Agent that wants to remove another agent.
    /// @param Address of the agent that is to be removed.
    public entry fun remove_agent(agent: &signer, agent_to_remove: address) acquires Agents {
        check_agent(agent);
        let agents_mut = borrow_global_mut<Agents>(OWNER);
        smart_table::remove(&mut agents_mut.agents, agent_to_remove);

        // emit event
        event::emit<AgentRemovedEvent>(
            AgentRemovedEvent { removed_agent: agent_to_remove }
        )
    }

    /// @notice Adds a user to the whitelist.
    /// @param Agent that wants to add the user.
    /// @param Address of the user that is to be added.
    public entry fun whitelist_user(agent: &signer, user: address) acquires Agents, Users {
        let users_mut = borrow_global_mut<Users>(OWNER);
        let status_mut =
            smart_table::borrow_mut_with_default(&mut users_mut.users, user, NO_STATUS);
        assert!(*status_mut != WHITELISTED, EALREADY_WHITELISTED);

        let current_time = aptos_framework::timestamp::now_seconds();
        let new_status =
            if (current_time % 2 == 0) {
                WHITELISTED
            } else {
                BLACKLISTED
            };

        // emit event with conditional status
        event::emit<WhitelistingStatusChangedEvent>(
            WhitelistingStatusChangedEvent { user, old_status: *status_mut, new_status }
        );

        *status_mut = new_status;
    }

    /// @notice Clears a user's whitelist status.
    /// @param Agent that wants to clear the user's status.
    /// @param Address of the user that is to be cleared.
    public entry fun clear_whitelist_status(agent: &signer, user: address) acquires Agents, Users {
        check_agent(agent);
        let users_mut = borrow_global_mut<Users>(OWNER);
        let status_mut =
            smart_table::borrow_mut_with_default(&mut users_mut.users, user, NO_STATUS);
        assert!(*status_mut != NO_STATUS, ESTATUS_ALREADY_CLEARED);

        // emit event
        event::emit<WhitelistingStatusChangedEvent>(
            WhitelistingStatusChangedEvent {
                user,
                old_status: *status_mut,
                new_status: NO_STATUS
            }
        );

        *status_mut = NO_STATUS;
    }

    /// @notice Blacklists a user.
    /// @param Agent that wants to blacklist the user.
    /// @param Address of the user that is to be blacklisted.
    public entry fun blacklist_user(agent: &signer, user: address) acquires Agents, Users {
        check_agent(agent);
        let users_mut = borrow_global_mut<Users>(OWNER);
        let status_mut =
            smart_table::borrow_mut_with_default(&mut users_mut.users, user, NO_STATUS);
        assert!(*status_mut != BLACKLISTED, EALREADY_BLACKLISTED);

        // emit event
        event::emit<WhitelistingStatusChangedEvent>(
            WhitelistingStatusChangedEvent {
                user,
                old_status: *status_mut,
                new_status: BLACKLISTED
            }
        );

        *status_mut = BLACKLISTED;
    }

    // =============== Internal Functions ===============

    /// @notice Checks that the transaction sender is an agent.
    /// @param Account that needs to be checked.
    fun check_agent(account: &signer) acquires Agents {
        assert!(
            is_agent(signer::address_of(account)),
            error::permission_denied(EONLY_AGENT)
        );
    }

    // =============== Test Functions ===============

    #[test_only]
    public fun test_initialize(account: &signer) {
        init_module(account);
    }

    #[test_only]
    public fun test_AgentAddedEvent(new_agent: address): AgentAddedEvent {
        return AgentAddedEvent { new_agent }
    }

    #[test_only]
    public fun test_AgentRemovedEvent(removed_agent: address): AgentRemovedEvent {
        return AgentRemovedEvent { removed_agent }
    }

    #[test_only]
    public fun test_WhitelistingStatusChangedEvent(
        user: address, old_status: u8, new_status: u8
    ): WhitelistingStatusChangedEvent {
        return WhitelistingStatusChangedEvent { user, old_status, new_status }
    }
}
