import Cosmos
import Auth
import Params

// Keeper defines a module interface that facilitates the transfer of coins
// between accounts.
public protocol BankKeeper: SendKeeper {
    func delegateCoins(
        request: Request,
        delegatorAddress: AccountAddress,
        moduleAccountAddress: AccountAddress,
        amount: Coins
    ) throws
    
    func undelegateCoins(
        request: Request,
        moduleAccountAddress: AccountAddress,
        delegatorAddress: AccountAddress,
        amount: Coins
    ) throws
}

// BaseKeeper manages transfers between accounts. It implements the Keeper interface.
public final class BaseKeeper: BaseSendKeeper, BankKeeper  {
    /// InitGenesis initializes the bank module's state from a given genesis state.
    public func initGenesis(request: Request, state: BankGenesisState) {
        // TODO: Implement
        fatalError()
    }

    // NewBaseKeeper returns a new BaseKeeper
    public override init(
        accountKeeper: AccountKeeper,
        paramSpace: Subspace,
        blacklistedAddresses: [String: Bool]
    ) {
        let paramSpace = paramSpace.with(keyTable: .paramKeyTable)
        
        super.init(
            accountKeeper: accountKeeper,
            paramSpace: paramSpace,
            blacklistedAddresses: blacklistedAddresses
        )
    }
    
    // DelegateCoins performs delegation by deducting amt coins from an account with
    // address addr. For vesting accounts, delegations amounts are tracked for both
    // vesting and vested coins.
    // The coins are then transferred from the delegator address to a ModuleAccount address.
    // If any of the delegation amounts are negative, an error is returned.
    public func delegateCoins(request: Request, delegatorAddress: AccountAddress, moduleAccountAddress: AccountAddress, amount: Coins) throws {
        // TODO: Implement
        fatalError()
/*
         delegatorAcc := keeper.ak.GetAccount(ctx, delegatorAddr)
         if delegatorAcc == nil {
             return sdkerrors.Wrapf(sdkerrors.ErrUnknownAddress, "account %s does not exist", delegatorAddr)
         }

         moduleAcc := keeper.ak.GetAccount(ctx, moduleAccAddr)
         if moduleAcc == nil {
             return sdkerrors.Wrapf(sdkerrors.ErrUnknownAddress, "module account %s does not exist", moduleAccAddr)
         }

         if !amt.IsValid() {
             return sdkerrors.Wrap(sdkerrors.ErrInvalidCoins, amt.String())
         }

         oldCoins := delegatorAcc.GetCoins()

         _, hasNeg := oldCoins.SafeSub(amt)
         if hasNeg {
             return sdkerrors.Wrapf(
                 sdkerrors.ErrInsufficientFunds, "insufficient account funds; %s < %s", oldCoins, amt,
             )
         }

         if err := trackDelegation(delegatorAcc, ctx.BlockHeader().Time, amt); err != nil {
             return sdkerrors.Wrap(err, "failed to track delegation")
         }

         keeper.ak.SetAccount(ctx, delegatorAcc)

         _, err := keeper.AddCoins(ctx, moduleAccAddr, amt)
         if err != nil {
             return err
         }

         return nil
         */
    }
    
    public func undelegateCoins(request: Request, moduleAccountAddress: AccountAddress, delegatorAddress: AccountAddress, amount: Coins) throws {
        // TODO: Implement
        fatalError()
        /*
         delegatorAcc := keeper.ak.GetAccount(ctx, delegatorAddr)
         if delegatorAcc == nil {
             return sdkerrors.Wrapf(sdkerrors.ErrUnknownAddress, "account %s does not exist", delegatorAddr)
         }

         moduleAcc := keeper.ak.GetAccount(ctx, moduleAccAddr)
         if moduleAcc == nil {
             return sdkerrors.Wrapf(sdkerrors.ErrUnknownAddress, "module account %s does not exist", moduleAccAddr)
         }

         if !amt.IsValid() {
             return sdkerrors.Wrap(sdkerrors.ErrInvalidCoins, amt.String())
         }

         oldCoins := moduleAcc.GetCoins()

         newCoins, hasNeg := oldCoins.SafeSub(amt)
         if hasNeg {
             return sdkerrors.Wrapf(
                 sdkerrors.ErrInsufficientFunds, "insufficient account funds; %s < %s", oldCoins, amt,
             )
         }

         err := keeper.SetCoins(ctx, moduleAccAddr, newCoins)
         if err != nil {
             return err
         }

         if err := trackUndelegation(delegatorAcc, amt); err != nil {
             return sdkerrors.Wrap(err, "failed to track undelegation")
         }

         keeper.ak.SetAccount(ctx, delegatorAcc)
         return nil
         */
    }
    
    public func inputOutputCoins(request: Request, inputs: [Input], outputs: [Output]) throws {
        // TODO: Implement
        fatalError()
        /*
         // Safety check ensuring that when sending coins the keeper must maintain the
         // Check supply invariant and validity of Coins.
         if err := types.ValidateInputsOutputs(inputs, outputs); err != nil {
             return err
         }

         for _, in := range inputs {
             _, err := keeper.SubtractCoins(ctx, in.Address, in.Coins)
             if err != nil {
                 return err
             }

             ctx.EventManager().EmitEvent(
                 sdk.NewEvent(
                     sdk.EventTypeMessage,
                     sdk.NewAttribute(types.AttributeKeySender, in.Address.String()),
                 ),
             )
         }

         for _, out := range outputs {
             _, err := keeper.AddCoins(ctx, out.Address, out.Coins)
             if err != nil {
                 return err
             }

             ctx.EventManager().EmitEvent(
                 sdk.NewEvent(
                     types.EventTypeTransfer,
                     sdk.NewAttribute(types.AttributeKeyRecipient, out.Address.String()),
                     sdk.NewAttribute(sdk.AttributeKeyAmount, out.Coins.String()),
                 ),
             )

             // Create account if recipient does not exist.
             //
             // NOTE: This should ultimately be removed in favor a more flexible approach
             // such as delegated fee messages.
             acc := keeper.ak.GetAccount(ctx, out.Address)
             if acc == nil {
                 keeper.ak.SetAccount(ctx, keeper.ak.NewAccountWithAddress(ctx, out.Address))
             }
         }

         return nil
         */
    }
    
    public func sendCoins(request: Request, fromAddress: AccountAddress, toAddress: AccountAddress, amount: Coins) throws {
        #warning("This operation should be atomic")
        let attributeRecipient = Attribute(
            key: AttributeKey.recipient,
            value: "\(fromAddress)"
        )
        let attributeSender = Attribute(
            key: AttributeKey.sender,
            value: "\(toAddress)"
        )
        let attributeAmount = Attribute(
            key: AttributeKey.amount,
            value: "\(amount)"
        )
        let transferEvent = Event(
            type: EventType.transfer, // types.EventTypeTransfer
            attributes: [attributeRecipient, attributeSender, attributeAmount]
        )

        request.eventManager.emit(event: transferEvent)
        
        let messageEvent = Event(
            type: EventType.message, // types.EventTypeTransfer
            attributes: [attributeSender]
        )

        request.eventManager.emit(event: messageEvent)

        
        _ = try subtractCoins(request: request, address: fromAddress, amount: amount)
        
        _ = try addCoins(request: request, address: toAddress, amount: amount)
        /*
         ctx.EventManager().EmitEvents(sdk.Events{
             // This event should have all info (to, from, amount) without looking at other events
             sdk.NewEvent(
                 types.EventTypeTransfer,
                 sdk.NewAttribute(types.AttributeKeyRecipient, toAddr.String()),
                 sdk.NewAttribute(types.AttributeKeySender, fromAddr.String()),
                 sdk.NewAttribute(sdk.AttributeKeyAmount, amt.String()),
             ),
             sdk.NewEvent(
                 sdk.EventTypeMessage,
                 sdk.NewAttribute(types.AttributeKeySender, fromAddr.String()),
             ),
         })

         _, err := keeper.SubtractCoins(ctx, fromAddr, amt)
         if err != nil {
             return err
         }

         _, err = keeper.AddCoins(ctx, toAddr, amt)
         if err != nil {
             return err
         }

         return nil
         */
    }
    
    public func subtractCoins(request request: Request, address: AccountAddress, amount: Coins) throws -> Coins {
        // TODO: Implement
        var oldCoins = [Coin]()
        var spendableCoins = [Coin]()
        if var acct = self.accountKeeper.account(request: request, address: address) {
            oldCoins = acct.coins
            spendableCoins = acct.spendableCoins(blockTime: request.header.time.timeIntervalSince1970)
        }
        
        // For non-vesting accounts, spendable coins will simply be the original coins.
        // So the check here is sufficient instead of subtracting from oldCoins.
        // TODO: implement
//        _, hasNeg := spendableCoins.SafeSub(amt)
//        if hasNeg {
//            return amt, sdkerrors.Wrapf(
//                sdkerrors.ErrInsufficientFunds, "insufficient account funds; %s < %s", spendableCoins, amt,
//            )
//        }
        
        let newCoins = try Coins.substract(from: oldCoins, this: amount)
        
        try self.setCoins(request: request, address: address, amount: newCoins)
        
        return newCoins
        /*
         if !amt.IsValid() {
             return nil, sdkerrors.Wrap(sdkerrors.ErrInvalidCoins, amt.String())
         }

         oldCoins, spendableCoins := sdk.NewCoins(), sdk.NewCoins()

         acc := keeper.ak.GetAccount(ctx, addr)
         if acc != nil {
             oldCoins = acc.GetCoins()
             spendableCoins = acc.SpendableCoins(ctx.BlockHeader().Time)
         }

         // For non-vesting accounts, spendable coins will simply be the original coins.
         // So the check here is sufficient instead of subtracting from oldCoins.
         _, hasNeg := spendableCoins.SafeSub(amt)
         if hasNeg {
             return amt, sdkerrors.Wrapf(
                 sdkerrors.ErrInsufficientFunds, "insufficient account funds; %s < %s", spendableCoins, amt,
             )
         }

         newCoins := oldCoins.Sub(amt) // should not panic as spendable coins was already checked
         err := keeper.SetCoins(ctx, addr, newCoins)

         return newCoins, err
         */
    }
    
    // TODO: Check if it's OK to discard the result
    @discardableResult
    public func addCoins(request: Request, address: AccountAddress, amount: Coins) throws -> Coins {
        // TODO: Implement
        var oldCoins = [Coin]()
        var spendableCoins = [Coin]()
        if var acct = self.accountKeeper.account(request: request, address: address) {
            oldCoins = acct.coins
            spendableCoins = acct.spendableCoins(blockTime: request.header.time.timeIntervalSince1970)
        }
        let newCoins = oldCoins + amount
        
        try self.setCoins(request: request, address: address, amount: newCoins)
        
        return newCoins
        
        /*
         if !amt.IsValid() {
             return nil, sdkerrors.Wrap(sdkerrors.ErrInvalidCoins, amt.String())
         }

         oldCoins := keeper.GetCoins(ctx, addr)
         newCoins := oldCoins.Add(amt...)

         if newCoins.IsAnyNegative() {
             return amt, sdkerrors.Wrapf(
                 sdkerrors.ErrInsufficientFunds, "insufficient account funds; %s < %s", oldCoins, amt,
             )
         }

         err := keeper.SetCoins(ctx, addr, newCoins)
         return newCoins, err
         */
    }
    
    public func setCoins(request: Request, address: AccountAddress, amount: Coins) throws {
        // TODO: Implement
        if var acct = self.accountKeeper.account(request: request, address: address) {
            try acct.set(coins: amount)
            self.accountKeeper.setAccount(request: request, account: acct as! BaseAccount)
        } else {
            // create new account
            let acct = self.accountKeeper.makeAccountWithAddress(request: request, address: address)
            self.accountKeeper.setAccount(request: request, account: acct as! BaseAccount)
        }
        
        
    /*
         if !amt.IsValid() {
             sdkerrors.Wrap(sdkerrors.ErrInvalidCoins, amt.String())
         }

         acc := keeper.ak.GetAccount(ctx, addr)
         if acc == nil {
             acc = keeper.ak.NewAccountWithAddress(ctx, addr)
         }

         err := acc.SetCoins(amt)
         if err != nil {
             panic(err)
         }

         keeper.ak.SetAccount(ctx, acc)
         return nil
         */
    }
    
    // GetSendEnabled returns the current SendEnabled
    public func isSendEnabled(request: Request) -> Bool {
        guard let res: Bool = paramSpace.get(
            request: request,
            key: KeyTable.paramStoreKeySendEnabled
        ) else {
            fatalError("send_enabled parameter not set in Bank store")
        }
        return res
    }
    
    // SetSendEnabled sets the send enabled
    public func setSendEnabled(request: Request, enabled: Bool) {
        paramSpace.set(
            request: request,
            key: KeyTable.paramStoreKeySendEnabled,
            value: enabled
        )
    }
    
    public func isBlacklisted(address: AccountAddress) -> Bool {
        blacklistedAddresses[address.description] != nil
    }
    
    public func coins(request: Request, address: AccountAddress) -> Coins? {
        // TODO: Implement
        fatalError()
        /*
         acc := keeper.ak.GetAccount(ctx, addr)
         if acc == nil {
             return sdk.NewCoins()
         }
         return acc.GetCoins()
         */
    }
    
    public func hasCoins(request: Request, address: AccountAddress, amount: Coins) -> Bool {
        // TODO: Implement
        fatalError()
        /*
         return keeper.GetCoins(ctx, addr).IsAllGTE(amt)
         */
    }
}

// BaseSendKeeper only allows transfers between accounts without the possibility of
// creating coins. It implements the SendKeeper interface.
public class BaseSendKeeper: BaseViewKeeper {
    let paramSpace: Subspace
    // list of addresses that are restricted from receiving transactions
    let blacklistedAddresses: [String: Bool]
    
    init(
        accountKeeper: AccountKeeper,
        paramSpace: Subspace,
        blacklistedAddresses: [String: Bool]
    ) {
        self.paramSpace = paramSpace
        self.blacklistedAddresses = blacklistedAddresses
        super.init(accountKeeper: accountKeeper)
    }
}

extension BaseSendKeeper {
}

// BaseViewKeeper implements a read only keeper implementation of ViewKeeper.
public class BaseViewKeeper {
    let accountKeeper: AccountKeeper
    
    init(accountKeeper: AccountKeeper) {
        self.accountKeeper = accountKeeper
    }
}

// SendKeeper defines a module interface that facilitates the transfer of coins
// between accounts without the possibility of creating coins.
public protocol SendKeeper: ViewKeeper {
    func inputOutputCoins(request: Request, inputs: [Input], outputs: [Output]) throws
    func sendCoins(request: Request, fromAddress: AccountAddress, toAddress: AccountAddress, amount: Coins) throws

    // TODO: Check if it's OK to discard the result
    @discardableResult
    func subtractCoins(request: Request, address: AccountAddress, amount: Coins) throws -> Coins
    // TODO: Check if it's OK to discard the result
    @discardableResult
    func addCoins(request: Request, address: AccountAddress, amount: Coins) throws -> Coins
    func setCoins(request: Request, address: AccountAddress, amount: Coins) throws

    func isSendEnabled(request: Request) -> Bool
    func setSendEnabled(request: Request, enabled: Bool)

    func isBlacklisted(address: AccountAddress) -> Bool
}

// ViewKeeper defines a module interface that facilitates read only access to
// account balances.
public protocol ViewKeeper {
    func coins(request: Request, address: AccountAddress) -> Coins?
    func hasCoins(request: Request, address: AccountAddress, amount: Coins) -> Bool
}
