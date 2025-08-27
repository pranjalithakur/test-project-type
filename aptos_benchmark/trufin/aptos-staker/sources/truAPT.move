module publisher::truAPT {
    // =================== Uses ====================
    use std::error;
    use std::option;
    use std::signer;
    use std::string::utf8;
    
    use aptos_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, Metadata};
    use aptos_framework::object;
    use aptos_framework::primary_fungible_store;

    friend publisher::staker;

    // =============== Constants ===================
    const ASSET_SYMBOL: vector<u8> = b"TruAPT";

    // ==================== Errors =====================
    
    /// Not the owner.
    const ENOT_OWNER: u64 = 1;

    // =============== Structs =====================

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    ///@notice Hold refs to control the minting, transfer and burning of fungible assets.
    struct ManagedFungibleAsset has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef,
    }

    // =============== Public View Functions ===============

    #[view]
    /// @notice Returns the fungible asset metadata object.
    public fun get_metadata(): object::Object<Metadata> {
        let asset_address = object::create_object_address(&@publisher, ASSET_SYMBOL);
        object::address_to_object<Metadata>(asset_address)
    }

    #[view]
    /// @notice Returns the fungible asset supply.
    public fun total_supply(): (u64) {
        let asset_supply = fungible_asset::supply(get_metadata());
        return (option::get_with_default<u128>(&mut asset_supply, 0) as u64)
    }
    
    #[view]
    /// @notice Returns the balance of an address.
    public fun balance_of(owner: address): (u64) {
        return primary_fungible_store::balance(owner, get_metadata()) 
    }
    
    // =============== Public Functions ===============

    /// @notice Initialize the fungible asset and store created refs.
    /// @param Owner account.
    public(friend) fun initialize(owner: &signer) {
        let constructor_ref = &object::create_named_object(owner, ASSET_SYMBOL);
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::none(), /* max supply */
            utf8(b"TruAPT coin"), /* name */
            utf8(ASSET_SYMBOL), /* symbol */
            8, /* decimals */
            utf8(b""), /* icon */
            utf8(b"https://trufin.io"), /* project */
        );

        // Create mint/burn/transfer refs to allow creator to manage the fungible asset.
        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let metadata_object_signer = object::generate_signer(constructor_ref);
        move_to(
            &metadata_object_signer,
            ManagedFungibleAsset { mint_ref, transfer_ref, burn_ref }
        )
    }

    // =============== Public Entry Functions ===============
   
    /// @notice Owner function to mint the fungible asset to a given address. 
    /// @param Owner account.
    /// @param Address of the recipient.
    /// @param Amount to transfer.
    public entry fun mint(owner: &signer, to: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let managed_fungible_asset = authorized_borrow_refs(owner, asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let fa = fungible_asset::mint(&managed_fungible_asset.mint_ref, amount);
        fungible_asset::deposit_with_ref(&managed_fungible_asset.transfer_ref, to_wallet, fa);
    }

    /// @notice Owner function to burn the fungible asset from a specified account.
    /// @param Owner account.
    /// @param Address of account that holds the fungible asset to burn.
    /// @param Amount to burn.
    public entry fun burn(owner: &signer, from: address, amount: u64) acquires ManagedFungibleAsset {
        let asset = get_metadata();
        let burn_ref = &authorized_borrow_refs(owner, asset).burn_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        fungible_asset::burn_from(burn_ref, from_wallet, amount);
    }

    // =============== Inline Functions ===============

    /// @notice Function to borrow the immutable reference of the refs of `metadata`. Validates that signer is the owner.
    /// @param Owner account.
    /// @param Metadata object of the fungible asset. 
    inline fun authorized_borrow_refs(
        owner: &signer,
        asset: object::Object<Metadata>,
    ): &ManagedFungibleAsset acquires ManagedFungibleAsset {
        assert!(object::is_owner(asset, signer::address_of(owner)), error::permission_denied(ENOT_OWNER));
        borrow_global<ManagedFungibleAsset>(object::object_address(&asset))
    }

    // =============== Test helper Functions ===============

    #[test_only]
    public fun test_initialize(account: &signer) {
        initialize(account);
  }
}
