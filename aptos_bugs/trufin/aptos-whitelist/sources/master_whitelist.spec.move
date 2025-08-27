spec whitelist::master_whitelist {
    spec module {
        pragma verify = true;
    }

    spec schema CheckAgent {
        agent: &signer;
        aborts_if !exists<Agents>(OWNER);
        let user = signer::address_of(agent);
        let agents = global<Agents>(OWNER).agents;
        let is_agent = smart_table::spec_contains(agents, user);
    }

    spec blacklist_user(agent: &signer, user: address) {
        pragma opaque;
        let pre_users = global<Users>(OWNER).users;
        let pre_status = if (smart_table::spec_contains(pre_users, user)) {
            smart_table::spec_get(pre_users, user)
        } else {
            NO_STATUS
        };

        // Preconditions
        include CheckAgent;
        aborts_if !exists<Users>(OWNER);
        aborts_if pre_status == BLACKLISTED;

        // Postconditions
        let post users = global<Users>(OWNER).users;
        ensures smart_table::spec_contains(users, user);

        let post status = smart_table::spec_get(users, user);
        ensures status == BLACKLISTED;

        // Modifies clauses
        modifies global<Users>(OWNER);
    }

    spec whitelist_user(agent: &signer, user: address) {
        pragma opaque;
        let pre_users = global<Users>(OWNER).users;
        let pre_status = if (smart_table::spec_contains(pre_users, user)) {
            smart_table::spec_get(pre_users, user)
        } else {
            NO_STATUS
        };

        // Preconditions
        include CheckAgent;
        aborts_if !exists<Users>(OWNER);
        aborts_if pre_status == WHITELISTED;

        // Postconditions
        let post users = global<Users>(OWNER).users;
        ensures smart_table::spec_contains(users, user);

        let post status = smart_table::spec_get(users, user);
        ensures status == WHITELISTED;

        // Modifies clauses
        modifies global<Users>(OWNER);
    }

    spec clear_whitelist_status(agent: &signer, user: address) {
        pragma opaque;
        let pre_users = global<Users>(OWNER).users;
        let pre_status = if (smart_table::spec_contains(pre_users, user)) {
            smart_table::spec_get(pre_users, user)
        } else {
            NO_STATUS
        };

        // Preconditions
        include CheckAgent;
        aborts_if !exists<Users>(OWNER);
        aborts_if pre_status == NO_STATUS;

        // Postconditions
        let post users = global<Users>(OWNER).users;
        ensures smart_table::spec_contains(users, user);

        let post status = smart_table::spec_get(users, user);
        ensures status == NO_STATUS;

        // Modifies clauses
        modifies global<Users>(OWNER);
    }

    spec remove_agent(agent: &signer, agent_to_remove: address) {
        let pre_agents = global<Agents>(OWNER).agents;

        // Preconditions
        include CheckAgent;
        aborts_if !smart_table::spec_contains(pre_agents, agent_to_remove);

        // Postconditions
        let post agents = global<Agents>(OWNER).agents;
        ensures !smart_table::spec_contains(agents, agent_to_remove);

        // Modifies clauses
        modifies global<Agents>(OWNER);
    }

    spec add_agent(agent: &signer, new_agent: address) {
        let pre_agents = global<Agents>(OWNER).agents;

        // Preconditions
        include CheckAgent;
        aborts_if smart_table::spec_contains(pre_agents, new_agent);

        // Postconditions
        let post agents = global<Agents>(OWNER).agents;
        ensures smart_table::spec_contains(agents, new_agent);

        // Modifies clauses
        modifies global<Agents>(OWNER);
    }
}
