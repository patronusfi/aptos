module oracle::oracle_test {
    use aptos_std::type_info::{type_of};
    use aptos_framework::account;
    use aptos_framework::aptos_coin;
    use aptos_framework::timestamp;
    use aptos_framework::block;
    use aptos_framework::signer;

    use switchboard::aggregator::{Self as switchboard_aggregator};

    use oracle::oracle;

    use mock::test_coin::{BTC, ETH, BNB, SOL, USDT, USDC};

    const C1E9: u64 = 1_000_000_000;

    public fun setup_feed<CoinType>(oracle: &signer, feed: address, price: u64, adapter: u8) {
        if (adapter == oracle::switchboard_adapter()) {
            let feed_signer = account::create_account_for_test(feed);
            switchboard_aggregator::new_test(&feed_signer, (price as u128), 9, false);
        } else {
            abort 0
        };

        oracle::update_oracle<CoinType>(oracle, feed, adapter);
    }

    #[test(aptos_framework = @0x1)]
    public fun setup_oracle(aptos_framework: &signer) {
        let oracle = account::create_account_for_test(@oracle);
        let adapter = oracle::switchboard_adapter();

        oracle::init_test(&oracle);
        // account::create_account_for_test(signer::address_of(aptos_framework));
        // block::initialize_for_test(aptos_framework, 1);
        // timestamp::set_time_has_started_for_testing(aptos_framework);

        setup_feed<BTC>(&oracle, @0x100A, C1E9 * 20123, adapter);
        setup_feed<ETH>(&oracle, @0x100B, C1E9 * 1567, adapter);
        setup_feed<BNB>(&oracle, @0x100C, C1E9 * 345, adapter);
        setup_feed<SOL>(&oracle, @0x100D, C1E9 * 34, adapter);
        setup_feed<USDT>(&oracle, @0x100E, C1E9, adapter);
        setup_feed<USDC>(&oracle, @0x100F, C1E9, adapter);
        setup_feed<aptos_coin::AptosCoin>(&oracle, @0x1010, C1E9 * 4, adapter);
    }

    public fun update_price<CoinType>(price: u64) {
        let (feed, adapter) = oracle::lookup(type_of<CoinType>());
        let feed_signer_cap = account::create_test_signer_cap(feed);
        let feed_signer = account::create_signer_with_capability(&feed_signer_cap);

        if (adapter == oracle::switchboard_adapter()) {
            switchboard_set_price<CoinType>(&feed_signer, price);
        } else {
            abort 0
        }
    }

    fun switchboard_set_price<CoinType>(feed_signer: &signer, price: u64) {
        switchboard_aggregator::update_value(feed_signer, (price as u128), 9, false);
    }

    fun assert_price<CoinType>(price: u64) {
        let (_feed, adapter) = oracle::lookup(type_of<CoinType>());
        if (adapter == oracle::switchboard_adapter()) {
            let got = oracle::get_price<CoinType>();
            assert!(price == got, 0);
        } else {
            abort 0
        };
    }

    #[test(aptos_framework = @0x1)]
    fun test_update_price(aptos_framework: &signer) {
        setup_oracle(aptos_framework);

        assert_price<BTC>(C1E9 * 20123);
        assert_price<ETH>(C1E9 * 1567);
        assert_price<BNB>(C1E9 * 345);
        assert_price<SOL>(C1E9 * 34);
        assert_price<USDT>(C1E9);
        assert_price<USDC>(C1E9);
        assert_price<aptos_coin::AptosCoin>(C1E9 * 4);

        update_price<BTC>(C1E9 * 20124);
        assert_price<BTC>(C1E9 * 20124);

        update_price<ETH>(C1E9 * 1568);
        assert_price<ETH>(C1E9 * 1568);

        update_price<BNB>(C1E9 * 346);
        assert_price<BNB>(C1E9 * 346);

        update_price<SOL>(C1E9 * 35);
        assert_price<SOL>(C1E9 * 35);

        update_price<USDT>(C1E9 + 1);
        assert_price<USDT>(C1E9 + 1);

        update_price<USDC>(C1E9 + 2);
        assert_price<USDC>(C1E9 + 2);

        update_price<aptos_coin::AptosCoin>(C1E9 * 5);
        assert_price<aptos_coin::AptosCoin>(C1E9 * 5);
    }
}
