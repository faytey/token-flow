use starknet::ContractAddress;

#[starknet::interface]
trait ICredit<TContractState> {
    fn lend(ref self: TContractState, contract: ContractAddress, amount: u128) -> bool;
    fn borrow(ref self: TContractState, contract: ContractAddress, amount: u128) -> bool;
    fn get_pool_balance(self: @TContractState) -> u128;
    fn withdraw(ref self: TContractState, amount: u128) -> bool;
    fn repay(ref self: TContractState, amount: u128) -> bool;
}

#[starknet::contract]
mod Credit {
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use super::{ICredit, ITokenDispatcher, ITokenDispatcherTrait};

    #[storage]
    struct Storage {
        contract_balance: u128,
        lenders: LegacyMap<ContractAddress, u128>,
        borrowers: LegacyMap<ContractAddress, u128>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Success: Success
    }

    #[derive(Drop, starknet::Event)]
    struct Success {
        #[key]
        user: ContractAddress,
        amount: u128,
        success: bool,
    }


    #[external(v0)]
    impl ICreditImpl of ICredit<ContractAddress> {
        
        fn lend(ref self: ContractState, contract: ContractAddress, amount: u128) -> bool {
            let con_address = ITokenDispatcher {contract_address: contract};
            let user = get_caller_address();
            let con = get_contract_address();
            assert(con_address.get_balance_of_user(user) >= amount);
            con_address.transfer_from(user, con, amount);
            self.contract_balance.write(self.contract_balance.read + amount);
            self.lenders.write(user, amount);
            assert(con_address.get_balance_of_user(con) == self.contract_balance.read());
            self.emit(Success{ user: user, amount: amount, success: true})
        }

        
        fn borrow(ref self: ContractState, contract: ContractAddress, amount: u128) -> bool {
            let con_address = ITokenDispatcher {contract_address: contract};
            let user = get_caller_address();
            let con = get_contract_address();
            assert(self.contract_balance.read() >= amount);
            con_address.transfer(user, amount);
            self.contract_balance.write(self.contract_balance.read() - amount);
            self.borrowers.write(user, amount);
            assert(con_address.get_balance_of_user(con) == self.contract_balance.read());
            self.emit(user: user, amount: amount, success: true);
        }

        
        fn get_pool_balance(self: @ContractState) -> u128 {
            self.contract_balance.read()
        }

        fn withdraw(ref self: ContractState, amount: u128) -> bool {
            let con_address = ITokenDispatcher {contract_address: contract};
            let user = get_caller_address();
            let con = get_contract_address();
            assert(self.lenders.read(user) >= amount, 'No balance');
            self.lenders.write(user, self.lenders.read(user) - amount);
            con_address.get_balance_of_user(user) + amount;
            self.emit(user: user, amount: amount, success: true);
        }

        fn repay(ref self: ContractState, amount: u128) -> bool {
            let con_address = ITokenDispatcher {contract_address: contract};
            let user = get_caller_address();
            let con = get_contract_address();
            assert(self.borrowers.read(user) >= amount, 'No loan');
            con_address.transfer_from(user, con, amount);
            self.borrowers.write(user, self.borrowers.read(user) - amount);
            self.emit(user: user, amount: amount, success: true);
        }

    }
}