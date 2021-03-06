import Foundation
import JSON
import ABCIMessages

// AppModuleBasic is the standard form for basic non-dependant elements of an application module.
public protocol AppModuleBasic {
    var name: String { get }
    func register(codec: Codec)

    // genesis
    func defaultGenesis() -> JSON?
    func validateGenesis(json: JSON) throws

    // client functionality
//    func registerRESTRoutes(cliContext: context.CLIContext, *mux.Router)
//    GetTxCmd(*codec.Codec) *cobra.Command
//    GetQueryCmd(*codec.Codec) *cobra.Command
}

// BasicManager is a collection of AppModuleBasic
public typealias BasicManager = Dictionary<String, AppModuleBasic>

extension BasicManager {
    // NewBasicManager creates a new BasicManager object
    public init(_ modules: AppModuleBasic...) {
        var moduleMap: BasicManager = [:]
        
        for module in modules {
            moduleMap[module.name] = module
        }
        
        self = moduleMap
    }
    
    // RegisterCodec registers all module codecs
    public func register(codec: Codec) {
        for basic in values {
            basic.register(codec: codec)
        }
    }

    // DefaultGenesis provides default genesis information for all modules
    public func defaultGenesis() -> JSON {
        var genesis: [String: JSON] = [:]
        
        for basic in values {
            genesis[basic.name] = basic.defaultGenesis()
        }
        
        return .object(genesis)
    }

    // ValidateGenesis performs genesis state validation for all modules
    func validateGenesis(genesis: [String: JSON]) throws {
        for basic in values {
            guard let json = genesis[basic.name] else {
                continue
            }
            
            try basic.validateGenesis(json: json)
        }
    }

    // RegisterRESTRoutes registers all module rest routes
//    func (bm BasicManager) RegisterRESTRoutes(ctx context.CLIContext, rtr *mux.Router) {
//        for _, b := range bm {
//            b.RegisterRESTRoutes(ctx, rtr)
//        }
//    }

    // AddTxCommands adds all tx commands to the rootTxCmd
//    func (bm BasicManager) AddTxCommands(rootTxCmd *cobra.Command, cdc *codec.Codec) {
//        for _, b := range bm {
//            if cmd := b.GetTxCmd(cdc); cmd != nil {
//                rootTxCmd.AddCommand(cmd)
//            }
//        }
//    }

    // AddQueryCommands adds all query commands to the rootQueryCmd
//    func addQueryCommands(rootQueryCmd *cobra.Command, cdc *codec.Codec) {
//        for _, b := range bm {
//            if cmd := b.GetQueryCmd(cdc); cmd != nil {
//                rootQueryCmd.AddCommand(cmd)
//            }
//        }
//    }
}

// AppModuleGenesis is the standard form for an application module genesis functions
public protocol AppModuleGenesis: AppModuleBasic {
    func initGenesis(request: Request, json: JSON) -> [ValidatorUpdate]
    func exportGenesis(request: Request) -> JSON
}

// AppModule is the standard form for an application module
public protocol AppModule: AppModuleGenesis {
    // registers
    func registerInvariants(in invariantRegistry: InvariantRegistry)

    // routes
    var route: String { get }
    func makeHandler() -> Handler?
    var querierRoute: String { get }
    func makeQuerier() -> Querier?

    // ABCI
    func beginBlock(request: Request, beginBlockRequest: RequestBeginBlock)
    func endBlock(request: Request, endBlockRequest: RequestEndBlock) -> [ValidatorUpdate]
}

public extension AppModule {
    // RegisterInvariants is a placeholder function register no invariants
    func registerInvariants(in invariantRegistry: InvariantRegistry) {}

    // Route empty module message route
    var route: String { "" }

    // NewHandler returns an empty module handler
    func makeHandler() -> Handler? { nil }

    // QuerierRoute returns an empty module querier route
    var querierRoute: String { "" }

    // NewQuerierHandler returns an empty module querier
    func makeQuerier() -> Querier? { nil }

    // BeginBlock returns an empty module begin-block
    func beginBlock(request: Request, beginBlockRequest: RequestBeginBlock) {}

    // EndBlock returns an empty module end-block
    func endBlock(request: Request, endBlockRequest: RequestEndBlock) -> [ValidatorUpdate] { [] }
}

//____________________________________________________________________________

// Manager defines a module manager that provides the high level utility for managing and executing
// operations for a group of modules
public class ModuleManager {
    let modules: [String: AppModule]
    var orderInitGenesis: [String]
    var orderExportGenesis: [String]
    var orderBeginBlockers: [String]
    var orderEndBlockers: [String]
    
    // NewManager creates a new Manager object
    public init(_ modules: AppModule...) {
        var moduleMap: [String: AppModule] = [:]
        var modulesOrdering: [String] = []
        
        for module in modules {
            moduleMap[module.name] = module
            modulesOrdering.append(module.name)
        }
        
        self.modules = moduleMap
        self.orderInitGenesis = modulesOrdering
        self.orderExportGenesis = modulesOrdering
        self.orderBeginBlockers = modulesOrdering
        self.orderEndBlockers = modulesOrdering
    }
    
    // SetOrderInitGenesis sets the order of init genesis calls
    public func setOrderInitGenesis(_ moduleNames: String...) {
        self.orderInitGenesis = moduleNames
    }
    
    // SetOrderExportGenesis sets the order of export genesis calls
    func setOrderExportGenesis(_ moduleNames: String...) {
        self.orderExportGenesis = moduleNames
    }

    // SetOrderBeginBlockers sets the order of set begin-blocker calls
    func setOrderBeginBlockers(_ moduleNames: String...) {
        self.orderBeginBlockers = moduleNames
    }


    // SetOrderEndBlockers sets the order of set end-blocker calls
    public func setOrderEndBlockers(_ moduleNames: String...) {
        self.orderEndBlockers = moduleNames
    }

    // RegisterRoutes registers all module routes and module querier routes
    public func registerRoutes(router: Router, queryRouter: QueryRouter) {
        for (_, module) in modules {
            if !module.route.isEmpty, let handler = module.makeHandler() {
                router.addRoute(path: module.route, handler: handler)
            }
            
            if !module.querierRoute.isEmpty, let querier = module.makeQuerier() {
                queryRouter.addRoute(path: module.querierRoute, querier: querier)
            }
        }
    }

    // InitGenesis performs init genesis functionality for modules
    public func initGenesis(request: Request, genesisState: [String: JSON]) -> ResponseInitChain {
        var validatorUpdates: [ValidatorUpdate] = []
        
        for moduleName in orderInitGenesis {
            guard let json = genesisState[moduleName] else {
                continue
            }
            
            guard let module = modules[moduleName] else {
                continue
            }
            
            let moduleValUpdates = module.initGenesis(request: request, json: json)

            // use these validator updates if provided, the module manager assumes
            // only one module will update the validator set
            if !moduleValUpdates.isEmpty {
                if !validatorUpdates.isEmpty {
                    fatalError("validator InitGenesis updates already set by a previous module")
                }
                
                validatorUpdates = moduleValUpdates
            }
        }
        
        return ResponseInitChain(validators: validatorUpdates)
    }
    
    // BeginBlock performs begin block functionality for all modules. It creates a
    // child context with an event manager to aggregate events emitted from all
    // modules.
    public func beginBlock(request: Request, beginBlockRequest: RequestBeginBlock) -> ResponseBeginBlock {
        request.eventManager = EventManager()

        for moduleName in orderBeginBlockers {
            modules[moduleName]?.beginBlock(request: request, beginBlockRequest: beginBlockRequest)
        }

        return ResponseBeginBlock(events: request.eventManager.events)
    }
    
    // EndBlock performs end block functionality for all modules. It creates a
    // child context with an event manager to aggregate events emitted from all
    // modules.
    public func endBlock(request: Request, endBlockRequest: RequestEndBlock) -> ResponseEndBlock {
        request.eventManager = EventManager()
        var validatorUpdates: [ValidatorUpdate] = []

        for moduleName in orderEndBlockers {
            guard let module = modules[moduleName] else {
                continue
            }
            
            let moduleValidatorUpdates = module.endBlock(request: request, endBlockRequest: endBlockRequest)

            // use these validator updates if provided, the module manager assumes
            // only one module will update the validator set
            if !moduleValidatorUpdates.isEmpty {
                if !validatorUpdates.isEmpty {
                    fatalError("validator EndBlock updates already set by a previous module")
                }

                validatorUpdates = moduleValidatorUpdates
            }
        }

        return ResponseEndBlock(updates: validatorUpdates, events: request.eventManager.events)
    }

}
