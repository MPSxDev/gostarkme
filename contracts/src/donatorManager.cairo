use starknet::ContractAddress;
use starknet::class_hash::ClassHash;

#[starknet::interface]
pub trait IDonatorManager<TContractState> {
    fn newDonator(ref self: TContractState);
    fn getOwner(self: @TContractState) -> ContractAddress;
    fn getDonatorClassHash(self: @TContractState) -> ClassHash;
    fn getDonatorByAddress(self: @TContractState, owner: ContractAddress) -> ContractAddress;
}

#[starknet::contract]
mod DonatorManager {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::array::ArrayTrait;
    use core::traits::TryInto;
    use starknet::ContractAddress;
    use starknet::syscalls::deploy_syscall;
    use starknet::class_hash::ClassHash;
    use starknet::get_caller_address;

    // *************************************************************************
    //                            STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        owner: ContractAddress,
        donators: LegacyMap::<ContractAddress, ContractAddress>,
        donator_class_hash: ClassHash,
    }

    // *************************************************************************
    //                            CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState, donator_class_hash: felt252) {
        self.owner.write(get_caller_address());
        self.donator_class_hash.write(donator_class_hash.try_into().unwrap());
    }

    // *************************************************************************
    //                            EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        DonatorContractDeployed: DonatorContractDeployed,
    }

    #[derive(Drop, starknet::Event)]
    struct DonatorContractDeployed {
        new_donator: ContractAddress,
        owner: ContractAddress
    }


    // *************************************************************************
    //                            EXTERNALS
    // *************************************************************************
    #[abi(embed_v0)]
    impl DonatorManagerImpl of super::IDonatorManager<ContractState> {
        fn newDonator(ref self: ContractState) {
            let mut calldata = ArrayTrait::<felt252>::new();
            calldata.append(get_caller_address().try_into().unwrap());

            let (address_0, _) = deploy_syscall(
                self.donator_class_hash.read(), 12345, calldata.span(), false
            )
                .unwrap();
            self.donators.write(get_caller_address().try_into().unwrap(), address_0);
            self
                .emit(
                    DonatorContractDeployed { owner: get_caller_address(), new_donator: address_0 }
                )
        }
        fn getOwner(self: @ContractState) -> ContractAddress {
            return self.owner.read();
        }
        fn getDonatorClassHash(self: @ContractState) -> ClassHash {
            return self.donator_class_hash.read();
        }
        fn getDonatorByAddress(self: @ContractState, owner: ContractAddress) -> ContractAddress {
            return self.donators.read(owner);
        }
    }
}
