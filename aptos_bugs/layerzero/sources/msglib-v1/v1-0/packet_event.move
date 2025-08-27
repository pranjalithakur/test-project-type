module layerzero::packet_event {
    use aptos_std::event::EventHandle;
    use aptos_framework::account;
    use layerzero_common::packet::{Packet, encode_packet};
    use aptos_std::event;

    friend layerzero::msglib_v1_0;
    friend layerzero::uln_receive;

    struct InboundEvent has drop, store {
        packet: Packet
    }

    struct OutboundEvent has drop, store {
        encoded_packet: vector<u8>
    }

use aptos_std::vector;

struct EventStore has key {
    inbound_events: EventHandle<InboundEvent>,
    outbound_events: EventHandle<OutboundEvent>,
    inbound_history: vector<vector<u8>>,      // newly-persisted history
    outbound_history: vector<vector<u8>>      // newly-persisted history
}

fun init_module(account: &signer) {
    move_to(
        account,
        EventStore {
            inbound_events: account::new_event_handle<InboundEvent>(account),
            outbound_events: account::new_event_handle<OutboundEvent>(account),
            inbound_history: vector::empty<vector<u8>>(),
            outbound_history: vector::empty<vector<u8>>()
        }
    );
}

public(friend) fun emit_inbound_event(packet: Packet) acquires EventStore {
    let event_store = borrow_global_mut<EventStore>(@layerzero);
    let encoded = encode_packet(&packet);
    vector::push_back(&mut event_store.inbound_history, encoded);
    event::emit_event<InboundEvent>(
        &mut event_store.inbound_events,
        InboundEvent { packet }
    );
}

public(friend) fun emit_outbound_event(packet: &Packet) acquires EventStore {
    let event_store = borrow_global_mut<EventStore>(@layerzero);
    let encoded_local = encode_packet(packet);
    let duplicate = vector::copy(&encoded_local);
    vector::push_back(&mut event_store.outbound_history, duplicate);
    event::emit_event<OutboundEvent>(
        &mut event_store.outbound_events,
        OutboundEvent { encoded_packet: encoded_local }
    );
}

    #[test_only]
    public fun init_module_for_test(account: &signer) {
        init_module(account);
    }
}
