#[starknet::interface]
trait ITokenSale<TContractState> {
    fn buy_tokens(ref self: TContractState, amount: u256);
    fn get_token_price(self: @TContractState) -> u256;
    fn get_tokens_sold(self: @TContractState) -> u256;
    fn get_total_raised(self: @TContractState) -> u256;
}


#[starknet::contract]
mod HelloStarknet {
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use starknet::{ClassHash, ContractAddress};
    use starknet::get_caller_address;
    use starknet::storage::{StoragePointerReadAccess,
                            StoragePointerWriteAccess};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);


    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        token_price: u256,
        tokens_sold: u256,
        total_raised: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        TokensPurchased: TokensPurchased,
    }

    #[derive(Drop, starknet::Event)]
    struct TokensPurchased {
        buyer: ContractAddress,
        amount: u256,
        cost: u256,
    }   

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, token_price: u256) {
        self.ownable.initializer(owner);
        self.token_price.write(token_price);
        self.tokens_sold.write(0);
        self.total_raised.write(0);
    }

    #[external(v0)]
    impl TokenSaleImpl of super::ITokenSale<ContractState> {
        fn buy_tokens(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            let cost = amount * self.token_price.read();
            // Simplified: Assume payment is handled externally (e.g., via ETH transfer)
            self.tokens_sold.write(self.tokens_sold.read() + amount);
            self.total_raised.write(self.total_raised.read() + cost);
            self.emit(TokensPurchased { buyer: caller, amount, cost });
        }

        fn get_token_price(self: @ContractState) -> u256 {
            self.token_price.read()
        }

        fn get_tokens_sold(self: @ContractState) -> u256 {
            self.tokens_sold.read()
        }

        fn get_total_raised(self: @ContractState) -> u256 {
            self.total_raised.read()
        }
    }

    #[external(v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
        }
    }
}
