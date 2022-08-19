module more_move::color_object {

    //Only way to create a new UID for SUI object is to call "object::new"
    // new function takes the current txn context as an arg to generate unique UIDs
    // TXN context is of type "&mut TxContext" and is passed down from an entry function
    use sui::object::Info;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    // struct defines a data structure that can represent RGB color.
    // To Define a struct that represents a SUI object type, we must add a "key" capability
    // to the definition, and the first field of the struct must be the id of the object with type "UID"

    // - Move supports field punning, which allows us to skip the field values if the field name happens to the be 
    // the same as the name of the value variable it is bound to.
    // Code "red," shorthand for "red: red,"
    struct ColorObject has key {
        info: Info,
        red: u8,
        green: u8,
        blue: u8,
    }

    // == Functions covered in Chapter 1 ==

    fun new(red: u8, green: u8, blue: u8, ctx: &mut TxContext): ColorObject {
        use sui::object;

        ColorObject {
            info: object::new(ctx),
            red,
            green,
            blue,
        }
    }

    // CTOR, creates new ColorObject and makes it owned by the sender of the txn
    public entry fun create(red: u8, green: u8, blue: u8, ctx: &mut TxContext) {
        let color_object = new(red, green, blue, ctx);
        transfer::transfer(color_object, tx_context::sender(ctx))
    }

    // getter to ColorObject so that modules outside of ColorObject are able to read their values
    public fun get_color(self: &ColorObject): (u8, u8, u8) {
        (self.red, self.green, self.blue)
    }

    // == Functions covered in Chapter 2 ==

    /// Copies the values of `from_object` into `into_object`.
    // from_object: read only because we only need its fields
    // Conversly, into_object: mutable because we need to mutate it

    // In order for a txn to make a call to the copy_into function,
    // THE SENDER OF THE TXN MUST BE THE OWNER OF BOTH OF "from_object" and "into_object"
    public entry fun copy_into(from_object: &ColorObject, into_object: &mut ColorObject) {
        into_object.red = from_object.red;
        into_object.green = from_object.green;
        into_object.blue = from_object.blue;
    }

    public entry fun delete(object: ColorObject) {
        use sui::object;
        let ColorObject { info, red: _, green: _, blue: _ } = object;
        object::delete(info);
    }

    public entry fun transfer(object: ColorObject, recipient: address) {
        transfer::transfer(object, recipient)
    }

    // == Functions covered in Chapter 3 ==

    // Entry function to turn an existing (owned) ColorObject into an immutable object

    // transfer::freeze_object requires passing object by value.
    // passing by reference would allow for the object to be mutable after being frozen
    public entry fun freeze_object(object: ColorObject) {
        transfer::freeze_object(object)
    }

    // API that creates immutable object at birth. IMMUTABLE CTOR
    public entry fun create_immutable(red: u8, green: u8, blue: u8, ctx: &mut TxContext) {
        let color_object = new(red, green, blue, ctx);
        transfer::freeze_object(color_object)
    }

    public entry fun update(
        object: &mut ColorObject,
        red: u8, green: u8, blue: u8,
    ) {
        object.red = red;
        object.green = green;
        object.blue = blue;
    }
}

#[test_only]
module more_move::color_objectTests {
    use sui::test_scenario;
    use more_move::color_object::{Self, ColorObject};
    use sui::object;
    use sui::tx_context;

    // == Tests covered in Chapter 1 ==

    #[test]
    fun test_create() {
        let owner = @0x1;
        // Create a ColorObject and transfer it to @owner.
        let scenario = &mut test_scenario::begin(&owner);
        {
            let ctx = test_scenario::ctx(scenario);
            color_object::create(255, 0, 255, ctx);
        };
        // Check that @not_owner does not own the just-created ColorObject.
        let not_owner = @0x2;
        test_scenario::next_tx(scenario, &not_owner);
        {
            assert!(!test_scenario::can_take_owned<ColorObject>(scenario), 0);
        };
        // Check that @owner indeed owns the just-created ColorObject.
        // Also checks the value fields of the object.
        test_scenario::next_tx(scenario, &owner);
        {
            let object = test_scenario::take_owned<ColorObject>(scenario);
            let (red, green, blue) = color_object::get_color(&object);
            assert!(red == 255 && green == 0 && blue == 255, 0);
            test_scenario::return_owned(scenario, object);
        };
    }

    // == Tests covered in Chapter 2 ==

    #[test]
    fun test_copy_into() {
        let owner = @0x1;
        let scenario = &mut test_scenario::begin(&owner);
        // Create two ColorObjects owned by `owner`, and obtain their IDs.
        let (id1, id2) = {
            let ctx = test_scenario::ctx(scenario);
            color_object::create(255, 255, 255, ctx);
            let id1 =
                object::id_from_address(tx_context::last_created_object_id(ctx));
            color_object::create(0, 0, 0, ctx);
            let id2 =
                object::id_from_address(tx_context::last_created_object_id(ctx));
            (id1, id2)
        };
        test_scenario::next_tx(scenario, &owner);
        {
            let obj1 = test_scenario::take_owned_by_id<ColorObject>(scenario, id1);
            let obj2 = test_scenario::take_owned_by_id<ColorObject>(scenario, id2);
            let (red, green, blue) = color_object::get_color(&obj1);
            assert!(red == 255 && green == 255 && blue == 255, 0);

            color_object::copy_into(&obj2, &mut obj1);
            test_scenario::return_owned(scenario, obj1);
            test_scenario::return_owned(scenario, obj2);
        };
        test_scenario::next_tx(scenario, &owner);
        {
            let obj1 = test_scenario::take_owned_by_id<ColorObject>(scenario, id1);
            let (red, green, blue) = color_object::get_color(&obj1);
            assert!(red == 0 && green == 0 && blue == 0, 0);
            test_scenario::return_owned(scenario, obj1);
        }
    }

    #[test]
    fun test_delete() {
        let owner = @0x1;
        // Create a ColorObject and transfer it to @owner.
        let scenario = &mut test_scenario::begin(&owner);
        {
            let ctx = test_scenario::ctx(scenario);
            color_object::create(255, 0, 255, ctx);
        };
        // Delete the ColorObject we just created.
        test_scenario::next_tx(scenario, &owner);
        {
            let object = test_scenario::take_owned<ColorObject>(scenario);
            color_object::delete(object);
        };
        // Verify that the object was indeed deleted.
        test_scenario::next_tx(scenario, &owner);
        {
            assert!(!test_scenario::can_take_owned<ColorObject>(scenario), 0);
        }
    }

    #[test]
    fun test_transfer() {
        let owner = @0x1;
        // Create a ColorObject and transfer it to @owner.
        let scenario = &mut test_scenario::begin(&owner);
        {
            let ctx = test_scenario::ctx(scenario);
            color_object::create(255, 0, 255, ctx);
        };
        // Transfer the object to recipient.
        let recipient = @0x2;
        test_scenario::next_tx(scenario, &owner);
        {
            let object = test_scenario::take_owned<ColorObject>(scenario);
            color_object::transfer(object, recipient);
        };
        // Check that owner no longer owns the object.
        test_scenario::next_tx(scenario, &owner);
        {
            assert!(!test_scenario::can_take_owned<ColorObject>(scenario), 0);
        };
        // Check that recipient now owns the object.
        test_scenario::next_tx(scenario, &recipient);
        {
            assert!(test_scenario::can_take_owned<ColorObject>(scenario), 0);
        };
    }

    // == Tests covered in Chapter 3 ==

    #[test]
    fun test_immutable() {
        let sender1 = @0x1;
        let scenario = &mut test_scenario::begin(&sender1);
        {
            let ctx = test_scenario::ctx(scenario);
            color_object::create_immutable(255, 0, 255, ctx);
        };
        test_scenario::next_tx(scenario, &sender1);
        {
            // take_owned does not work for immutable objects.
            assert!(!test_scenario::can_take_owned<ColorObject>(scenario), 0);
        };
        // Any sender can work.
        let sender2 = @0x2;
        test_scenario::next_tx(scenario, &sender2);
        {
            // use take_immutable and subsequently borrow to obtain read only reference to object
            let object_wrapper = test_scenario::take_immutable<ColorObject>(scenario);
            let object = test_scenario::borrow(&object_wrapper);
            let (red, green, blue) = color_object::get_color(object);
            assert!(red == 255 && green == 0 && blue == 255, 0);
            test_scenario::return_immutable(scenario, object_wrapper);
        };
    }
}