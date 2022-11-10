
module admin::pseudorandom {
    use std::bcs;
    use std::error;
    use std::hash;
    use std::signer;
    use std::vector;
    use 0x1::aptos_coin::AptosCoin;
    use aptos_framework::coin;

    use aptos_framework::account;
    use aptos_framework::block;
    use aptos_framework::timestamp;
    use aptos_framework::transaction_context;

    use admin::bcd;

    const ENOT_ROOT: u64 = 0;
    const EHIGH_ARG_GREATER_THAN_LOW_ARG: u64 = 1;
    const E_INSUFICIENT_APTOS_COIN: u64 = 2;

    /// Resource that wraps an integer counter.
    struct Counter has key {
        value: u64
    }

    /// Publish a `Counter` resource with value `i` under the given `root` account.
    public entry fun init(root: &signer) {
        // "Pack" (create) a Counter resource. This is a privileged operation that
        // can only be done inside the module that declares the `Counter` resource
        assert!(signer::address_of(root) == @admin, error::permission_denied(ENOT_ROOT));
        move_to(root, Counter { value: 0 })
    }

    /// Increment the value of `addr`'s `Counter` resource.
    fun increment(): u64 acquires Counter {
        let c_ref = &mut borrow_global_mut<Counter>(@admin).value;
        *c_ref = *c_ref + 1;
        *c_ref
    }

    /// Acquire a seed using: the hash of the counter, block height, timestamp, script hash, sender address, and sender sequence number.
    fun seed(_sender: &address): vector<u8> acquires Counter {
        let counter = increment();
        let counter_bytes = bcs::to_bytes(&counter);

        let height: u64 = block::get_current_block_height();
        let height_bytes: vector<u8> = bcs::to_bytes(&height);

        let timestamp: u64 = timestamp::now_microseconds();
        let timestamp_bytes: vector<u8> = bcs::to_bytes(&timestamp);

        let script_hash: vector<u8> = transaction_context::get_script_hash();

        let sender_bytes: vector<u8> = bcs::to_bytes(_sender);

        let sequence_number: u64 = account::get_sequence_number(*_sender);
        let sequence_number_bytes = bcs::to_bytes(&sequence_number);

        let info: vector<u8> = vector::empty<u8>();
        vector::append<u8>(&mut info, counter_bytes);
        vector::append<u8>(&mut info, height_bytes);
        vector::append<u8>(&mut info, timestamp_bytes);
        vector::append<u8>(&mut info, script_hash);
        vector::append<u8>(&mut info, sender_bytes);
        vector::append<u8>(&mut info, sequence_number_bytes);

        let hash: vector<u8> = hash::sha3_256(info);
        hash
    }

    /// Acquire a seed using: the hash of the counter, block height, timestamp, and script hash.
    fun seed_no_sender(): vector<u8> acquires Counter {
        let counter = increment();
        let counter_bytes = bcs::to_bytes(&counter);

        let height: u64 = block::get_current_block_height();
        let height_bytes: vector<u8> = bcs::to_bytes(&height);

        let timestamp: u64 = timestamp::now_microseconds();
        let timestamp_bytes: vector<u8> = bcs::to_bytes(&timestamp);

        let script_hash: vector<u8> = transaction_context::get_script_hash();

        let info: vector<u8> = vector::empty<u8>();
        vector::append<u8>(&mut info, counter_bytes);
        vector::append<u8>(&mut info, height_bytes);
        vector::append<u8>(&mut info, timestamp_bytes);
        vector::append<u8>(&mut info, script_hash);

        let hash: vector<u8> = hash::sha3_256(info);
        hash
    }
    /// Generate a random u64
    public fun rand_u64_with_seed(_seed: vector<u8>): u64 {
        bcd::bytes_to_u64(_seed)
    }

    /// Generate a random integer range in [low, high).
    public fun rand_u64_range_with_seed(_seed: vector<u8>, low: u64, high: u64): u64 {
        assert!(high > low, error::invalid_argument(EHIGH_ARG_GREATER_THAN_LOW_ARG));
        let value = rand_u64_with_seed(_seed);
        (value % (high - low)) + low
    }

    public fun rand_u64_range_no_sender(low: u64, high: u64): u64 acquires Counter { rand_u64_range_with_seed(seed_no_sender(), low, high) }
uvc

    public entry fun bet (account: &signer, bet_amount: u64) acquires Counter {
        
        let account_address = signer::address_of(account);
        
        assert!(coin::balance<AptosCoin>(account_address) > bet_amount, E_INSUFICIENT_APTOS_COIN);

        assert!(coin::balance<AptosCoin>(@admin) > (bet_amount * 2) , E_INSUFICIENT_APTOS_COIN);

        let random_number = rand_u64_range_no_sender(0, 100);

        if (random_number < 50) {
            coin::transfer<AptosCoin>(account, @admin, bet_amount);
        } else {
            coin::transfer<AptosCoin>(account, @admin, bet_amount * 2);
        }

    }
    
}