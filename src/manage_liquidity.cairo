use ekubo::interfaces::core::{ICoreDispatcherTrait};
use ekubo::types::keys::{PoolKey, PositionKey};
use ekubo::types::i129::{i129};
use ekubo::types::bounds::{Bounds};
use traits::{TryInto, Into};
use option::{OptionTrait};
use starknet::{StorePacking};
use integer::{u256_safe_divmod, u256_as_non_zero};

// 192 bits total, can be packed in a single felt using StorePacking
#[derive(Copy, Drop, starknet::Store)]
struct PoolState {
    // 64 bits
    block_timestamp_last: u64,
    // this value can fit in 96 bits
    // because the max tick is 88722883 which fits in 32 bits w/ the sign,
    // and block timestamps (by which the tick is multiplied) are 64 bits
    tick_cumulative_last: i129,
}

#[starknet::interface]
trait IOracle<TStorage> {
    // Returns the cumulative tick value for a given pool, in order to compute a geomean TWAP
    fn get_tick_cumulative(self: @TStorage, pool_key: PoolKey) -> i129;
}

#[starknet::contract]
mod Oracle {
    use super::{IOracle, PoolKey, PositionKey, PoolState};
    use ekubo::types::call_points::{CallPoints};
    use ekubo::types::bounds::{Bounds};
    use ekubo::types::i129::{i129};
    use ekubo::interfaces::core::{
        ICoreDispatcher, ICoreDispatcherTrait, IExtension, SwapParameters, UpdatePositionParameters,
        Delta
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};
    use zeroable::{Zeroable};
    use traits::{Into, TryInto};
    use option::{OptionTrait};

    #[storage]
    struct Storage {
        core: ICoreDispatcher,
        pool_state: LegacyMap<PoolKey, PoolState>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, core: ICoreDispatcher) {
        self.core.write(core);
    }

    #[generate_trait]
    impl Internal of InternalTrait {
        fn check_caller_is_core(self: @ContractState) -> ICoreDispatcher {
            let core = self.core.read();
            assert(core.contract_address == get_caller_address(), 'CALLER_NOT_CORE');
            core
        }

        fn update_pool(ref self: ContractState, core: ICoreDispatcher, pool_key: PoolKey) {
            let state = self.pool_state.read(pool_key);

            let time = get_block_timestamp();
            let time_passed: u128 = (time - state.block_timestamp_last).into();

            if (time_passed.is_zero()) {
                return ();
            }

            let price = core.get_pool_price(pool_key);

            let tick_cumulative_next = state.tick_cumulative_last
                + (price.tick * i129 { mag: time_passed, sign: false });

            self
                .pool_state
                .write(
                    pool_key,
                    PoolState {
                        block_timestamp_last: time,
                        tick_cumulative_last: tick_cumulative_next,
                    }
                );
        }
    }

    #[external(v0)]
    impl OracleImpl of IOracle<ContractState> {
        fn get_tick_cumulative(self: @ContractState, pool_key: PoolKey) -> i129 {
            let time = get_block_timestamp();
            let state = self.pool_state.read(pool_key);

            if (time == state.block_timestamp_last) {
                state.tick_cumulative_last
            } else {
                let price = self.core.read().get_pool_price(pool_key);
                state.tick_cumulative_last
                    + (price.tick * i129 {
                        mag: (time - state.block_timestamp_last).into(), sign: false
                    })
            }
        }
    }

    #[external(v0)]
    impl OracleExtension of IExtension<ContractState> {
        fn before_initialize_pool(
            ref self: ContractState, caller: ContractAddress, pool_key: PoolKey, initial_tick: i129
        ) -> CallPoints {
            self.check_caller_is_core();

            self
                .pool_state
                .write(
                    pool_key,
                    PoolState {
                        block_timestamp_last: get_block_timestamp(),
                        tick_cumulative_last: Zeroable::zero(),
                    }
                );

            CallPoints {
                after_initialize_pool: false,
                before_swap: true,
                after_swap: false,
                before_update_position: true,
                after_update_position: false,
            }
        }

        fn after_initialize_pool(
            ref self: ContractState, caller: ContractAddress, pool_key: PoolKey, initial_tick: i129
        ) {
            assert(false, 'NOT_USED');
        }

        fn before_swap(
            ref self: ContractState,
            caller: ContractAddress,
            pool_key: PoolKey,
            params: SwapParameters
        ) {
            let core = self.check_caller_is_core();
            self.update_pool(core, pool_key);
        }

        fn after_swap(
            ref self: ContractState,
            caller: ContractAddress,
            pool_key: PoolKey,
            params: SwapParameters,
            delta: Delta
        ) {
            assert(false, 'NOT_USED');
        }

        fn before_update_position(
            ref self: ContractState,
            caller: ContractAddress,
            pool_key: PoolKey,
            params: UpdatePositionParameters
        ) {
            let core = self.check_caller_is_core();
            self.update_pool(core, pool_key);
        }

        fn after_update_position(
            ref self: ContractState,
            caller: ContractAddress,
            pool_key: PoolKey,
            params: UpdatePositionParameters,
            delta: Delta
        ) {
            assert(false, 'NOT_USED');
        }
    }
}
