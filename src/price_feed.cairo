use starknet::ContractAddress;
use pragma_lib::types::{DataType};


#[starknet::interface]
trait IFeed<TContractState> {
    fn get_asset_price_median(self: @TContractState, asset : DataType) -> u128;
    fn get_btc_to_usd_median(self: @TContractState) -> u128;
    fn get_eth_to_usd_median(self: @TContractState) -> u128;
    fn get_doge_to_usd_median(self: @TContractState) -> u128;
    fn get_avax_to_usd_median(self: @TContractState) -> u128;
    fn get_wbtc_to_usd_median(self: @TContractState) -> u128;
    fn get_wsteth_to_usd_median(self: @TContractState) -> u128;
    fn get_sol_to_usd_median(self: @TContractState) -> u128;
}

#[starknet::contract]
mod PriceFeed {

    use pragma_lib::abi::{IPragmaABIDispatcher, IPragmaABIDispatcherTrait};
    use pragma_lib::types::{AggregationMode, DataType, PragmaPricesResponse};
    use starknet::ContractAddress;
    use starknet::contract_address::contract_address_const;
    use super::{IFeed};

    #[storage]
    struct Storage {
        btc_key: felt252,
        eth_key: felt252,
        doge_key: felt252,
        avax_key: felt252,
        wbtc_key: felt252,
        wsteth_key: felt252,
        sol_key: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.btc_key.write('BTC/USD');
        self.eth_key.write('ETH/USD');
        self.doge_key.write('DOGE/USD');
        self.avax_key.write('AVAX/USD');
        self.wbtc_key.write('WBTC/USD');
        self.wsteth_key.write('WSTETH/USD');
        self.sol_key.write('SOL/USD');
    }

    #[external(v0)]
    impl IFeedImpl of IFeed<ContractState> {
        fn get_asset_price_median(self: @ContractState, asset : DataType) -> u128  { 
            let oracle_address : ContractAddress = contract_address_const::<0x06df335982dddce41008e4c03f2546fa27276567b5274c7d0c1262f3c2b5d167>();
            let oracle_dispatcher = IPragmaABIDispatcher{contract_address : oracle_address};
            let output : PragmaPricesResponse= oracle_dispatcher.get_data(asset, AggregationMode::Median(()));
            return output.price;
        }

        fn get_btc_to_usd_median(self: @ContractState) -> u128 {
            let KEY :felt252 = self.btc_key.read();
            let price = self.get_asset_price_median(DataType::SpotEntry(KEY));
            price
        }

        fn get_eth_to_usd_median(self: @ContractState) -> u128 {
            let KEY :felt252 = self.eth_key.read();
            let price = self.get_asset_price_median(DataType::SpotEntry(KEY));
            price
        }

        fn get_doge_to_usd_median(self: @ContractState) -> u128 {
            let KEY :felt252 = self.doge_key.read();
            let price = self.get_asset_price_median(DataType::SpotEntry(KEY));
            price
        }

        fn get_avax_to_usd_median(self: @ContractState) -> u128 {
            let KEY :felt252 = self.avax_key.read();
            let price = self.get_asset_price_median(DataType::SpotEntry(KEY));
            price
        }

        fn get_wbtc_to_usd_median(self: @ContractState) -> u128 {
            let KEY :felt252 = self.wbtc_key.read();
            let price = self.get_asset_price_median(DataType::SpotEntry(KEY));
            price
        }

        fn get_wsteth_to_usd_median(self: @ContractState) -> u128 {
            let KEY :felt252 = self.wsteth_key.read();
            let price = self.get_asset_price_median(DataType::SpotEntry(KEY));
            price
        }

        fn get_sol_to_usd_median(self: @ContractState) -> u128 {
            let KEY :felt252 = self.sol_key.read();
            let price = self.get_asset_price_median(DataType::SpotEntry(KEY));
            price
        }


    }
}