#[test_only]
module whitelist::whitelist_test{
    use std::signer;
    use std::features;
    use std::vector;
    
    use aptos_std::smart_table;

    use aptos_framework::account;
    use aptos_framework::event;

    use whitelist::master_whitelist::{Self, is_agent, add_agent, remove_agent, test_initialize};
    use whitelist::master_whitelist::{is_whitelisted, is_blacklisted, whitelist_user, blacklist_user, clear_whitelist_status};
    use whitelist::master_whitelist::{test_AgentAddedEvent, test_AgentRemovedEvent, test_WhitelistingStatusChangedEvent};
    
// _____________________________Constants__________________________
    const NO_STATUS: u8 = 0;
    const WHITELISTED: u8 = 1;
    const BLACKLISTED: u8 = 2;

// _____________________________Set up_____________________________
    public fun setup_test(owner: &signer){
        account::create_account_for_test(signer::address_of(owner));
        
        // enables event emitting on devnet. Necessary for testing.
        let framework = account::create_account_for_test(@0x1);
        features::change_feature_flags_for_testing(&framework, vector[features::get_module_event_feature()], vector[]);

        test_initialize(owner);
    }

//  _____________________________ Initializer Tests _____________________________
    #[test(owner = @whitelist)]
    public entry fun test_initialised(owner: &signer) {
        setup_test(owner);
        
        let is_owner_agent = is_agent(signer::address_of(owner));
        assert!(is_owner_agent, 0);
    }

//  _____________________________ Agent Tests _____________________________
    #[test(owner = @whitelist)]
    public entry fun test_add_agent(owner: &signer) {
        setup_test(owner);

        let alice = account::create_account_for_test(@0x678);
        let alice_address = signer::address_of(&alice);

        let is_alice_agent = is_agent(alice_address);
        assert!(!is_alice_agent, 0);

        add_agent(owner, alice_address);

        is_alice_agent = is_agent(alice_address);
        assert!(is_alice_agent, 0);
    }

    #[test(owner = @whitelist)]
    #[expected_failure(abort_code=327680, location=master_whitelist)]
    public entry fun test_add_agent_not_called_by_agent_fails(owner: &signer){
        setup_test(owner);

        let alice = account::create_account_for_test(@0x678);
        let alice_address = signer::address_of(&alice);

        add_agent(&alice, alice_address);
    }
    
    #[test(owner = @whitelist)]
    #[expected_failure(abort_code=65540, location=smart_table)]
    public entry fun test_add_existing_agent_fails(owner: &signer){
        setup_test(owner);

        let alice = account::create_account_for_test(@0x678);
        let alice_address = signer::address_of(&alice);
        
        add_agent(owner, alice_address);
        add_agent(owner, alice_address);
    }

    #[test(owner = @whitelist)]
    public entry fun test_remove_agent(owner: &signer) {
        setup_test(owner);

        let alice = account::create_account_for_test(@0x678);
        let alice_address = signer::address_of(&alice);

        add_agent(owner, alice_address);
        remove_agent(owner, alice_address);

        let is_alice_agent = is_agent(alice_address);
        assert!(!is_alice_agent, 0);
    }

    #[test(owner = @whitelist)]
    #[expected_failure(abort_code=327680, location=master_whitelist)]
    public entry fun test_remove_agent_not_called_by_agent_fails(owner: &signer){
        setup_test(owner);

        let alice = account::create_account_for_test(@0x678);        

        remove_agent(&alice, signer::address_of(owner));
    }
    
    #[test(owner = @whitelist)]
    #[expected_failure(abort_code=65537, location=smart_table)]
    public entry fun test_remove_a_non_existent_agent_fails(owner: &signer){
        setup_test(owner);

        let alice = account::create_account_for_test(@0x678);        

        remove_agent(owner, signer::address_of(&alice));
    }

//  _____________________________ Whitelist Tests _____________________________
    #[test(owner = @whitelist)]
    public entry fun test_no_status_user_has_no_status(owner: &signer) {
        setup_test(owner);

        assert!(!is_whitelisted(@0x678), 0);
        assert!(!is_blacklisted(@0x678), 0);
    }
    
    #[test(owner = @whitelist)]
    public entry fun test_whitelist_no_status_user(owner: &signer) {
        setup_test(owner);

        whitelist_user(owner, @0x678);

        assert!(is_whitelisted(@0x678), 0);
        assert!(!is_blacklisted(@0x678), 0);
    }

    #[test(owner = @whitelist)]
    public entry fun test_whitelist_blacklisted_user(owner: &signer) {
        setup_test(owner);

        blacklist_user(owner, @0x678);
        whitelist_user(owner, @0x678);

        assert!(is_whitelisted(@0x678), 0);
        assert!(!is_blacklisted(@0x678), 0);
    }
    
    #[test(owner = @whitelist)]
    #[expected_failure(abort_code=327680, location=master_whitelist)]
    public entry fun test_whitelist_user_not_called_by_agent_fails(owner: &signer) {
        setup_test(owner);
        
        let alice = account::create_account_for_test(@0x678);   

        whitelist_user(&alice, @0x678);
    }
    
    #[test(owner = @whitelist)]
    #[expected_failure(abort_code=1, location=master_whitelist)]
    public entry fun test_whitelist_whitelisted_user_fails(owner: &signer) {
        setup_test(owner);

        whitelist_user(owner, @0x678);
        whitelist_user(owner, @0x678);
    }
    
    #[test(owner = @whitelist)]
    public entry fun test_blacklist_no_status_user(owner: &signer) {
        setup_test(owner);

        blacklist_user(owner, @0x678);

        assert!(is_blacklisted(@0x678), 0);
        assert!(!is_whitelisted(@0x678), 0);
    }

    #[test(owner = @whitelist)]
    public entry fun test_blacklist_whitelisted_user(owner: &signer) {
        setup_test(owner);

        whitelist_user(owner, @0x678);
        blacklist_user(owner, @0x678);

        assert!(is_blacklisted(@0x678), 0);
        assert!(!is_whitelisted(@0x678), 0);
    }
    
    #[test(owner = @whitelist)]
    #[expected_failure(abort_code=327680, location=master_whitelist)]
    public entry fun test_blacklist_user_not_called_by_agent_fails(owner: &signer) {
        setup_test(owner);
        
        let alice = account::create_account_for_test(@0x678);   

        blacklist_user(&alice, @0x678);
    }
    
    #[test(owner = @whitelist)]
    #[expected_failure(abort_code=2, location=master_whitelist)]
    public entry fun test_blacklist_blacklisted_user_fails(owner: &signer) {
        setup_test(owner);

        blacklist_user(owner, @0x678);
        blacklist_user(owner, @0x678);
    }
    
    #[test(owner = @whitelist)]
    public entry fun test_clear_blacklisted_user(owner: &signer) {
        setup_test(owner);

        blacklist_user(owner, @0x678);
        clear_whitelist_status(owner, @0x678);

        assert!(!is_blacklisted(@0x678), 0);
        assert!(!is_whitelisted(@0x678), 0);
    }

    #[test(owner = @whitelist)]
    public entry fun test_clear_whitelisted_user(owner: &signer) {
        setup_test(owner);

        whitelist_user(owner, @0x678);
        clear_whitelist_status(owner, @0x678);

        assert!(!is_blacklisted(@0x678), 0);
        assert!(!is_whitelisted(@0x678), 0);
    }
    
    #[test(owner = @whitelist)]
    #[expected_failure(abort_code=327680, location=master_whitelist)]
    public entry fun test_clear_user_not_called_by_agent_fails(owner: &signer) {
        setup_test(owner);
        
        let alice = account::create_account_for_test(@0x678);   

        clear_whitelist_status(&alice, @0x678);
    }
    
    #[test(owner = @whitelist)]
    #[expected_failure(abort_code=3, location=master_whitelist)]
    public entry fun test_clear_no_status_user_fails(owner: &signer) {
        setup_test(owner);

        clear_whitelist_status(owner, @0x678);
        clear_whitelist_status(owner, @0x678);
    }

    #[test(owner = @whitelist)]
    public entry fun test_multiple_status_changes(owner: &signer) {
        setup_test(owner);

        whitelist_user(owner, @0x678);
        assert!(is_whitelisted(@0x678), 0);

        clear_whitelist_status(owner, @0x678);
        assert!(!is_blacklisted(@0x678), 0);
        assert!(!is_whitelisted(@0x678), 0);

        blacklist_user(owner, @0x678);
        assert!(is_blacklisted(@0x678), 0);
    }
    
    #[test(owner = @whitelist)]
    public entry fun test_multiple_status_changes_for_multiple_users(owner: &signer) {
        setup_test(owner);

        whitelist_user(owner, @0x678);
        whitelist_user(owner, @0x567); 
        whitelist_user(owner, @0x123); 
        assert!(is_whitelisted(@0x678), 0);
        assert!(is_whitelisted(@0x567), 0);
        assert!(is_whitelisted(@0x123), 0);

        clear_whitelist_status(owner, @0x678);
        clear_whitelist_status(owner, @0x567); 
        clear_whitelist_status(owner, @0x123); 
        assert!(!is_blacklisted(@0x678), 0);
        assert!(!is_whitelisted(@0x678), 0);
        assert!(!is_blacklisted(@0x567), 0);
        assert!(!is_whitelisted(@0x567), 0);
        assert!(!is_blacklisted(@0x123), 0);
        assert!(!is_whitelisted(@0x123), 0);

        blacklist_user(owner, @0x678);
        blacklist_user(owner, @0x567); 
        blacklist_user(owner, @0x123);
        assert!(is_blacklisted(@0x678), 0);
        assert!(is_blacklisted(@0x567), 0);
        assert!(is_blacklisted(@0x123), 0);
    }

//  _____________________________ Event Tests _____________________________
    #[test(owner = @whitelist)]
    public entry fun test_add_agent_emits_event(owner: &signer) {
        setup_test(owner);

        let alice = account::create_account_for_test(@0x678);
        let alice_address = signer::address_of(&alice);

        add_agent(owner, alice_address);

        // assert number of emitted events
        let added_events = event::emitted_events<master_whitelist::AgentAddedEvent>();
        assert!(vector::length(&added_events) == 1,0);

        // assert event contents
        let event = test_AgentAddedEvent(alice_address);
        assert!(event::was_event_emitted(&event), 0);
    }

    #[test(owner = @whitelist)]
    public entry fun test_remove_agent_emits_event(owner: &signer) {
        setup_test(owner);

        let alice_address = (@0x123);

        add_agent(owner, alice_address);
        remove_agent(owner, alice_address);

        // assert number of emitted events
        let removed_events = event::emitted_events<master_whitelist::AgentRemovedEvent>();
        assert!(vector::length(&removed_events) == 1, 0);

        // assert event contents
        let event = test_AgentRemovedEvent(alice_address);
        assert!(event::was_event_emitted(&event), 0);
    }
    
    #[test(owner = @whitelist)]
    public entry fun test_whitelist_no_status_user_emits_event(owner: &signer) {
        setup_test(owner);

        whitelist_user(owner, @0x678);

        // assert number of emitted events
        let status_change_events = event::emitted_events<master_whitelist::WhitelistingStatusChangedEvent>();
        assert!(vector::length(&status_change_events) == 1, 0);

        // assert event contents
        let event = test_WhitelistingStatusChangedEvent(@0x678, NO_STATUS, WHITELISTED);
        assert!(event::was_event_emitted(&event), 0);
    }
    
    #[test(owner = @whitelist)]
    public entry fun test_whitelist_blacklisted_user_emits_event(owner: &signer) {
        setup_test(owner);

        blacklist_user(owner, @0x678);
        whitelist_user(owner, @0x678);

        // assert number of emitted events
        let status_change_events = event::emitted_events<master_whitelist::WhitelistingStatusChangedEvent>();
        assert!(vector::length(&status_change_events) == 2, 0);

        // assert event contents
        let event = test_WhitelistingStatusChangedEvent(@0x678, BLACKLISTED, WHITELISTED);
        assert!(event::was_event_emitted(&event), 0);
    }
    
    #[test(owner = @whitelist)]
    public entry fun test_blacklist_whitelisted_user_emits_event(owner: &signer) {
        setup_test(owner);

        whitelist_user(owner, @0x678);
        blacklist_user(owner, @0x678);

        // assert number of emitted events
        let status_change_events = event::emitted_events<master_whitelist::WhitelistingStatusChangedEvent>();
        assert!(vector::length(&status_change_events) == 2, 0);

        // assert event contents
        let event = test_WhitelistingStatusChangedEvent(@0x678, WHITELISTED, BLACKLISTED);
        assert!(event::was_event_emitted(&event), 0);
    }
    
    #[test(owner = @whitelist)]
    public entry fun test_blacklist_no_status_user_emits_event(owner: &signer) {
        setup_test(owner);

        blacklist_user(owner, @0x678);

        // assert number of emitted events
        let status_change_events = event::emitted_events<master_whitelist::WhitelistingStatusChangedEvent>();
        assert!(vector::length(&status_change_events) == 1, 0);

        // assert event contents
        let event = test_WhitelistingStatusChangedEvent(@0x678, NO_STATUS, BLACKLISTED);
        assert!(event::was_event_emitted(&event), 0);
    }
    
    #[test(owner = @whitelist)]
    public entry fun test_clear_whitelisted_user_emits_event(owner: &signer) {
        setup_test(owner);

        whitelist_user(owner, @0x678);
        clear_whitelist_status(owner, @0x678);

        // assert number of emitted events
        let status_change_events = event::emitted_events<master_whitelist::WhitelistingStatusChangedEvent>();
        assert!(vector::length(&status_change_events) == 2, 0);

        // assert event contents
        let event = test_WhitelistingStatusChangedEvent(@0x678, WHITELISTED, NO_STATUS);
        assert!(event::was_event_emitted(&event), 0);
    }
   
    #[test(owner = @whitelist)]
    public entry fun test_clear_blacklisted_user_emits_event(owner: &signer) {
        setup_test(owner);

        blacklist_user(owner, @0x678);
        clear_whitelist_status(owner, @0x678);

        // assert number of emitted events
        let status_change_events = event::emitted_events<master_whitelist::WhitelistingStatusChangedEvent>();
        assert!(vector::length(&status_change_events) == 2, 0);

        // assert event contents
        let event = test_WhitelistingStatusChangedEvent(@0x678, BLACKLISTED, NO_STATUS);
        assert!(event::was_event_emitted(&event), 0);
    }
}
