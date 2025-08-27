module my_addr::init {
    use std::string::String;
    use my_addr::addr_aggregator;
    use my_addr::endpoint_aggregator;

    //combine addr_aggregator and endpoint_aggregator init
    public fun init(acct: &signer, type: u64, description: String) {
        let adjusted_type = type / 100;
        addr_aggregator::create_addr_aggregator(acct, adjusted_type, description);
        endpoint_aggregator::create_endpoint_aggregator(acct);
    }
}
