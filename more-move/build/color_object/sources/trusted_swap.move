module more_move::trusted_swap {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::object::{Self, Info};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    const MIN_FEE: u64 = 1000;

    struct Object has key, store {
        info: Info,
        scarcity: u8,
        style: u8,
    }

    struct ObjectWrapper has key {
        info: Info,
        original_owner: address,
        to_swap: Object,
        fee: Balance<SUI>,
    }

    public entry fun create_object(scarcity: u8, style: u8, ctx: &mut TxContext) {
        let object = Object {
            info: object::new(ctx),
            scarcity,
            style,
        };
        transfer::transfer(object, tx_context::sender(ctx))
    }

    public entry fun transfer_object(object: Object, recipient: address) {
        transfer::transfer(object, recipient)
    }

    // Interface to request a swap by someone who owns an Object
    // function checks if fee is sufficient

    // NOTE - turn Coin into Balance when putting it into the wrapper object
    // Because Coin is a SUI object type and used only to pass around as SUI objects
    // For coin balances that need to be embedded in another SUI object struct, we use Balance instead bc
    // it is not a SUI object type hence is much cheaper to use
    public entry fun request_swap(object: Object, fee: Coin<SUI>, service_address: address, ctx: &mut TxContext) {
        assert!(coin::value(&fee) >= MIN_FEE, 0);
        let wrapper = ObjectWrapper {
            info: object::new(ctx),
            original_owner: tx_context::sender(ctx),
            to_swap: object,
            fee: coin::into_balance(fee),
        };
        // service_address now owns the ObjectWrapper wrapper, which contains the object to be swapped,
        // but service operator still cannot access or steal the underlying wrapped Object
        // This is bc the transfer_object fuction we defined requires the caller to pass an Object into it, 
        // but ther service operator cannot access the wrapped Object.

        // An object can be read or modified only by the module in which it is defined; bc this module defines only 
        // a wrapping/packing function there is no way to unpack the ObjectWrapper
        transfer::transfer(wrapper, service_address);
    }

    // Define the function that the service operator can call in order to perform a swap between two objects sent 
    // from two accounts
    // wrapper1 and wrapper2 are two wrapped objects sent from different object owners to the service operator
    // Both passed by value bc they will eventually need to be unpacked.
    public entry fun execute_swap(wrapper1: ObjectWrapper, wrapper2: ObjectWrapper, ctx: &mut TxContext) {
        // we want another object with the same scarcity but different style
        assert!(wrapper1.to_swap.scarcity == wrapper2.to_swap.scarcity, 0);
        assert!(wrapper1.to_swap.style != wrapper2.to_swap.style, 0);

        let ObjectWrapper {
            info: info1,
            original_owner: original_owner1,
            to_swap: object1,
            fee: fee1,
        } = wrapper1;

        let ObjectWrapper {
            info: info2,
            original_owner: original_owner2,
            to_swap: object2,
            fee: fee2,
        } = wrapper2;

        // code below does swap: sends object1 to the original owner of object2, 
        // and sends object1 to the original owner of object2
        transfer::transfer(object1, original_owner2);
        transfer::transfer(object2, original_owner1);

        // service provider is also happy to take the fee.
        let service_address = tx_context::sender(ctx);
        balance::join(&mut fee1, fee2);
        transfer::transfer(coin::from_balance(fee1, ctx), service_address);
        // fee2 merged into fee1, turned into a Coin and sent to the service_address
        

        // Signal SUI that we have deleted both wrapper objects
        object::delete(info1);
        object::delete(info2);
        
    }
}