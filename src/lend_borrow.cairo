use starknet::ContractAddress;

#[starknet::interface]
trait ICredit<TContractState> {
    fn lend(ref self: TContractState, contract: ContractAddress, amount: u128) -> bool;
    fn borrow(ref self: TContractState, contract: ContractAddress, amount: u128) -> bool;
    fn get_pool_balance(self: @TContractState) -> u128;
    fn withdraw(ref self: TContractState, contract: ContractAddress, amount: u128) -> bool;
    fn repay(ref self: TContractState, contract: ContractAddress, amount: u128) -> bool;
}

#[starknet::contract]
mod Credit {
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use token_flow::lend_borrow::{ICredit};
    use token_flow::lending_token::{ITokenDispatcher, ITokenDispatcherTrait};

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
    impl ICreditImpl of ICredit<ContractState> {
        
        fn lend(ref self: ContractState, contract: ContractAddress, amount: u128) -> bool {
            let con_address = ITokenDispatcher {contract_address: contract};
            let user = get_caller_address();
            let con = get_contract_address();
            assert(con_address.get_balance_of_user(user) >= amount, 'Insufficient balance');
            con_address.transfer_from(user, con, amount);
            self.contract_balance.write(self.contract_balance.read() + amount);
            self.lenders.write(user, amount);
            assert(con_address.get_balance_of_user(con) == self.contract_balance.read(), 'Incorrect balance');
            self.emit(Success {user: user, amount: amount, success: true});
            true
        }

        
        fn borrow(ref self: ContractState, contract: ContractAddress, amount: u128) -> bool {
            let con_address = ITokenDispatcher {contract_address: contract};
            let user = get_caller_address();
            let con = get_contract_address();
            assert(self.contract_balance.read() >= amount, 'Contract balance Insufficient');
            con_address.transfer(user, amount);
            self.contract_balance.write(self.contract_balance.read() - amount);
            self.borrowers.write(user, amount);
            assert(con_address.get_balance_of_user(con) == self.contract_balance.read(), 'Insufficient Balance');
            self.emit(Success {user: user, amount: amount, success: true});
            true
        }

        
        fn get_pool_balance(self: @ContractState) -> u128 {
            self.contract_balance.read()
        }

        fn withdraw(ref self: ContractState, contract: ContractAddress, amount: u128) -> bool {
            let con_address = ITokenDispatcher {contract_address: contract};
            let user = get_caller_address();
            let con = get_contract_address();
            assert(self.lenders.read(user) >= amount, 'No balance');
            self.lenders.write(user, self.lenders.read(user) - amount);
            con_address.get_balance_of_user(user) + amount;
            self.emit(Success {user: user, amount: amount, success: true});
            true
        }

        fn repay(ref self: ContractState, contract: ContractAddress, amount: u128) -> bool {
            let con_address = ITokenDispatcher {contract_address: contract};
            let user = get_caller_address();
            let con = get_contract_address();
            assert(self.borrowers.read(user) >= amount, 'No loan');
            con_address.transfer_from(user, con, amount);
            self.borrowers.write(user, self.borrowers.read(user) - amount);
            self.emit(Success {user: user, amount: amount, success: true});
            true
        }

    }
}