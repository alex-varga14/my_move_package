module more_move::simple_warrior {
    
    // A warrior may or may not have a sword and shield, and they should be able to replace them at any time.

    // There are a few limitations in object wrapping:
    // 1. A wrapped object can be accessed only via its wrapper. 
    //  It cannot be used directly in a transaction or queried by its ID (e.g., in the explorer).
    // 2. An object can become very large if it wraps several other objects. 
    //  Larger objects can lead to higher gas fees in transactions. 
    //  In addition, there is an upper bound on object size.
    // 3. As we will see in future chapters, there will be use cases where we need to store a collection
    //   of objects of heterogeneous types. 
    //   Since the Move vector type must be templated on one single type T, it is not suitable for this.
    struct Sword has key, store {
        info: Info,
        strength: u8,
    }

    struct Shield has key, store {
        info: Info, 
        armor: u8,
    }

    struct SimpleWarrior {
        info: Info, 
        sword: Option<Sword>,
        shield: Option<Shield>,
    }

    public entry fun create_sword(strength: u8, ctx: &mut TxContext) {
        let sword = Sword {
            info: object::new(ctx),
            strength,
        };
        transfer::transfer(sword, tx_context::sender(ctx))
    }

    public entry fun create_shield(armor: u8, ctx: &mut TxContext) {
        let shield = Shield {
            info: object::new(ctx),
            armor,
        };
        transfer::transfer(shield, tx_context::sender(ctx))
    }

    public entry fun create_warrior(ctx: &mut TxContext) {
        let warrior = SimpleWarrior {
            info: object::new(ctx),
            sword: option::none(),
            shield: option::none(),
        };
        transfer::transfer(warrior, tx_context::sender(ctx))
    }

    // define function to equip new swords or shields
    // pass SimpleWarrior as mut reference and sword passed by value because we need to wrap it
    // NOTE - bc Sword is a SUI object without drop ability, if the warrior already has a sword equipped, that sword
    // cannot just be dropped
    // If we make the call to option::fill without first checking or taking out the existing sword, a runtime error
    // may occur.
    // Hence we first check if there is a sword equipped, if so we take it out and send it back to the sender.
    public entry fun equip_sword(warrior: &mut SimpleWarrior, sword: Sword, ctx: &mut TxContext) {
        if (option::is_some(&warror.sword)) {
            let old_sword = option::extract(&mut warrior.sword);
            transfer::transfer(old_sword, tx_context::sender(ctx));
        };
        option::fill(&mut warrior.sword, sword);
    }

    public entry fun equip_shield(warrior: &mut SimpleWarrior, shield: Shield, ctx: &mut TxContext) {
        if (option::is_some(&warror.shield)) {
            let old_shield= option::extract(&mut warrior.shield);
            transfer::transfer(old_shield, tx_context::sender(ctx));
        };
        option::fill(&mut warrior.shield, shield);
    }
}