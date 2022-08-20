module more_move::give_coin {
    use sui::coin;
    use sui::transfer;
    use sui::sui::SUI;
    use sui::tx_context::{Self, TxContext};
    
    struct GODCOIN has drop {}

    fun init(ctx: &mut TxContext) {
        transfer::transfer(coin::create_currency(GODCOIN {}, ctx),
        tx_context::sender(ctx)
        )
    }
}