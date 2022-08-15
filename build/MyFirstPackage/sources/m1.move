module my_first_package::m1 {
    use sui::object::Info;
    use sui::tx_context::TxContext;

    // module initializer to be executed when this module is published
    fun init(ctx: &mut TxContext) {
        use sui::transfer;
        use sui::tx_context;

         //needed to add for "info: object" to work, or else "unbound module"
        use sui::object;

        let admin = Forge {
            info: object::new(ctx),
            swords_created: 0,
        };

        // transfer the forge object to the module/package publisher (presumably the game admin)
        transfer::transfer(admin, tx_context::sender(ctx));
    }

    //asset (Sword) has both magic and strength fields describing its respective attribute values.
    struct Sword has key, store {
        info: Info,
        magic: u64,
        strength: u64,
    }

    struct Forge has key, store {
        info: Info,
        swords_created: u64,
    }

    public fun swords_created(self: &Forge): u64 {
        self.swords_created
    }

    //if we want to access sword attributes from a different package, we need accessor functions to our module 
    // similar to the value function in the Coin package.
    public fun magic(self: &Sword): u64 {
        self.magic
    }
    public fun strength(self: &Sword): u64 {
        self.strength
    }

    public entry fun sword_create(forge: &mut Forge, magic: u64, strength: u64, recipient: address, ctx: &mut TxContext) {
        use sui::transfer;
        //use sui::tx_context;

        //needed to add for "info: object" to work, or else "unbound module"
        use sui::object;

        //create a sword
        let sword = Sword {
            info: object::new(ctx),
            magic: magic,
            strength: strength,
        };

        //transfer the sword
        transfer::transfer(sword, recipient);

        forge.swords_created = forge.swords_created + 1;
    }

    public entry fun sword_transfer(sword: Sword, recipient: address) {
        use sui::transfer;

        //transfer the sword
        transfer::transfer(sword, recipient);
    }



    #[test]
    public fun test_module_init() {
        use sui::test_scenario;

        // create test address representing game admin
        let admin = @0xABBA;

        // first transaction to emulate module initializaion
        let scenario = &mut test_scenario::begin(&admin);
        {
            init(test_scenario::ctx(scenario));
        };

        // second transaction to check if the forge has been created,
        // has intial value of zero swords created
        test_scenario::next_tx(scenario, &admin);
        {
            // extract the Forge object
            let forge = test_scenario::take_owned<Forge>(scenario);

            // verify the number of created swords
            assert!(swords_created(&forge) == 0, 1);

            // return the Forge object to the object pool
            test_scenario::return_owned(scenario, forge)
        };


    }

    //objects must be dealt with, cant create a sword and not delete it or "drop" it

    //However, we do not want to "drop" a sword because it is an asset, so another solution to the problem
    // would be to transfer ownership of the sword.

    #[test]
    public fun test_sword_create() {
        //use to transfer ownership of sword created
        use sui::transfer;

        use sui::tx_context;
        
        //needed to add for "info: object" to work, or else "unbound module"
        use sui::object;

        //create a dummy (MOCK) TxContext for testing
        let ctx = tx_context::dummy();

        //create a sword
        let sword = Sword {
            info: object::new(&mut ctx),
            magic: 42,
            strength: 7,
        };

        // check if accessor functions return correct values
        assert!(magic(&sword) == 42 && strength(&sword) == 7, 1);

        //Use transfer module to transfer ownership of the sword to a freshly created dummy address
        let dummy_address = @0xCAFE;
        transfer::transfer(sword, dummy_address);

    }

    #[test]
    fun test_sword_transactions() {
        use sui::test_scenario;

        // Create addresses for users participating in the scenario
        let admin = @0xABBA;
        let initial_owner = @0xCAFE;
        let final_owner = @0xFACE;

        // first transaction executed by admin
        let scenario = &mut test_scenario::begin(&admin);
        {
            init(test_scenario::ctx(scenario));
        };

         // second transaction executed by admin to create the sword
        test_scenario::next_tx(scenario, &admin);
        {
            let forge = test_scenario::take_owned<Forge>(scenario);
            // create the sword and transfer it to the initial owner
            sword_create(&mut forge, 42, 7, initial_owner, test_scenario::ctx(scenario));
            test_scenario::return_owned(scenario, forge)
        };
        // third transaction executed by the initial sword owner
        test_scenario::next_tx(scenario, &initial_owner);
        {
            // extract the sword owned by the initial owner
            let sword = test_scenario::take_owned<Sword>(scenario);
            // transfer the sword to the final owner
            sword_transfer(sword, final_owner);
        };
        // fourth transaction executed by the final sword owner
        test_scenario::next_tx(scenario, &final_owner);
        {

            // extract the sword owned by the final owner
            let sword = test_scenario::take_owned<Sword>(scenario);
            // verify that the sword has expected properties
            assert!(magic(&sword) == 42 && strength(&sword) == 7, 1);
            // return the sword to the object pool (it cannot be simply "dropped")
            test_scenario::return_owned(scenario, sword)
        }
    }
}