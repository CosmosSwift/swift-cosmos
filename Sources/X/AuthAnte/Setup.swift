import Cosmos
import Auth

protocol TransactionWithGas {
    var gas: UInt64 { get }
}


extension StandardTransaction: TransactionWithGas {}


// SetUpContextDecorator sets the GasMeter in the Context and wraps the next AnteHandler with a defer clause
// to recover from any downstream OutOfGas panics in the AnteHandler chain to return an error with information
// on gas provided and gas used.
// CONTRACT: Must be first decorator in the chain
// CONTRACT: Tx must implement GasTx interface
struct SetUpContextDecorator: AnteDecorator {
    func anteHandle(
        request: Request,
        transaction: Transaction,
        simulate: Bool,
        next: AnteHandler?
    ) throws -> Request {
        // TODO: Implement
        
        guard let transaction = transaction as? TransactionWithGas else {
            throw CosmosError.wrap(error: CosmosError.invalidTransaction, description: "Tx must be a GasTx")        }
        
//        // all transactions must implement GasTx
//        gasTx, ok := tx.(GasTx)
//        if !ok {
//            // Set a gas meter with limit 0 as to prevent an infinite gas meter attack
//            // during runTx.
//            newCtx = SetGasMeter(simulate, ctx, 0)
//            return newCtx, sdkerrors.Wrap(sdkerrors.ErrTxDecode, "Tx must be GasTx")
//        }
//

        let request = setGasMeter(simulate, request, transaction.gas)
        
//        // Decorator will catch an OutOfGasPanic caused in the next antehandler
//        // AnteHandlers must have their own defer/recover in order for the BaseApp
//        // to know how much gas was used! This is because the GasMeter is created in
//        // the AnteHandler, but if it panics the context won't be set properly in
//        // runTx's recover call.
//        defer func() {
//            if r := recover(); r != nil {
//                switch rType := r.(type) {
//                case sdk.ErrorOutOfGas:
//                    log := fmt.Sprintf(
//                        "out of gas in location: %v; gasWanted: %d, gasUsed: %d",
//                        rType.Descriptor, gasTx.GetGas(), newCtx.GasMeter().GasConsumed())
//
//                    err = sdkerrors.Wrap(sdkerrors.ErrOutOfGas, log)
//                default:
//                    panic(r)
//                }
//            }
//        }()
//
//        return next(newCtx, tx, simulate)
        if let next = next {
            return (try? next(request, transaction as! Transaction, simulate)) ?? request
        } else {
            return request
        }
    }
    
    // SetGasMeter returns a new context with a gas meter set from a given context.
    func setGasMeter(_ simulate: Bool, _ request: Request, _ gasLimit: UInt64) -> Request {
        // In various cases such as simulation and during the genesis block, we do not
        // meter any gas utilization.
        #warning("In the go code, a copy of the context is made")
        if simulate || request.header.height == 0 {
            
            request.gasMeter = InfiniteGasMeter()
        } else {
            request.gasMeter = BasicGasMeter(limit: gasLimit)
        }
        return request
    }
}
