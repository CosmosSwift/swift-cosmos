//package capability
//
//import (
//    "encoding/json"
//    "fmt"
//    "math/rand"
//
//    "github.com/gorilla/mux"
//    "github.com/grpc-ecosystem/grpc-gateway/runtime"
//    "github.com/spf13/cobra"
//
//    abci "github.com/tendermint/tendermint/abci/types"
//
//    "github.com/cosmos/cosmos-sdk/client"
//    "github.com/cosmos/cosmos-sdk/codec"
//    cdctypes "github.com/cosmos/cosmos-sdk/codec/types"
//    sdk "github.com/cosmos/cosmos-sdk/types"
//    "github.com/cosmos/cosmos-sdk/types/module"
//    simtypes "github.com/cosmos/cosmos-sdk/types/simulation"
//    "github.com/cosmos/cosmos-sdk/x/capability/keeper"
//    "github.com/cosmos/cosmos-sdk/x/capability/simulation"
//    "github.com/cosmos/cosmos-sdk/x/capability/types"
//)
//
//var (
//    _ module.AppModuleSimulation = AppModule{}
//)

import ABCIMessages
import JSON
import Cosmos

// ----------------------------------------------------------------------------
// AppModuleBasic
// ----------------------------------------------------------------------------

// AppModuleBasic implements the AppModuleBasic interface for the capability module.
class CapabilityAppModuleBasic: AppModuleBasic {
    let codec: Codec
    
    init(codec: Codec) {
        self.codec = codec
    }
   
    // Name returns the capability module's name.
    var name: String {
        CapabilityKeys.moduleName
    }
    
    // RegisterLegacyAminoCodec does nothing. Capability does not support amino.
    func register(codec: Codec) {}

    // RegisterInterfaces registers the module's interface types
//    func registerInterfaces(_ cdctypes.InterfaceRegistry) {}
    
    // DefaultGenesis returns the capability module's default genesis state.
    func defaultGenesis() -> JSON? {
        let data = codec.mustMarshalJSON(value: CapabilityGenesisState.default)
        return codec.mustUnmarshalJSON(data: data)
    }

    // ValidateGenesis performs genesis state validation for the capability module.
    func validateGenesis(json: JSON) throws {
        var state: CapabilityGenesisState
        
        do {
            let data = try codec.marshalJSON(value: json)
            state = try codec.unmarshalJSON(data: data)
        } catch {
            throw CosmosError.wrap(
                error: error,
                description: "failed to unmarshal \(CapabilityKeys.moduleName) genesis state"
            )
        }
        
        return try state.validate()
    }
    
    //// RegisterRESTRoutes registers the capability module's REST service handlers.
    //func (a AppModuleBasic) RegisterRESTRoutes(_ client.Context, _ *mux.Router) {}
    //
    //// RegisterGRPCGatewayRoutes registers the gRPC Gateway routes for the capability module.
    //func (a AppModuleBasic) RegisterGRPCGatewayRoutes(_ client.Context, _ *runtime.ServeMux) {
    //}
    //
    //// GetTxCmd returns the capability module's root tx command.
    //func (a AppModuleBasic) GetTxCmd() *cobra.Command { return nil }
    //
    //// GetQueryCmd returns the capability module's root query command.
    //func (AppModuleBasic) GetQueryCmd() *cobra.Command { return nil }
    //
}

// ----------------------------------------------------------------------------
// AppModule
// ----------------------------------------------------------------------------

// AppModule implements the AppModule interface for the capability module.
final class CapabilityAppModule: CapabilityAppModuleBasic, AppModule {
    let keeper: CapabilityKeeper
    
    init(codec: Codec, keeper: CapabilityKeeper) {
        self.keeper = keeper
        super.init(codec: codec)
    }
    
    // Name returns the capability module's name.
    override var name: String {
        super.name
    }
    
    // Route returns the capability module's message routing key.
    var route: String {
        ""
    }
    
    // QuerierRoute returns the capability module's query routing key.
    var querierRoute: String {
        ""
    }
    
    // LegacyQuerierHandler returns the capability module's Querier.
    func makeHandler() -> Handler? {
        nil
    }
    
    //// RegisterServices registers a GRPC query service to respond to the
    //// module-specific GRPC queries.
    //func (am AppModule) RegisterServices(module.Configurator) {}
    
    // RegisterInvariants registers the capability module's invariants.
    func registerInvariants(in invariantRegistry: InvariantRegistry) {}
    
    // InitGenesis performs the capability module's genesis initialization It returns
    // no validator updates.
    func initGenesis(request: Request, json: JSON) -> [ValidatorUpdate] {
        let data = codec.mustMarshalJSON(value: json)
        // Initialize global index to index in genesis state
        let state: CapabilityGenesisState = codec.mustUnmarshalJSON(data: data)
        keeper.initGenesis(request: request, state: state)
        return []
    }
    
    // ExportGenesis returns the capability module's exported genesis state as raw JSON bytes.
    func exportGenesis(request: Request) -> JSON {
        let state = keeper.exportGenesis(request: request)
        let data = codec.mustMarshalJSON(value: state)
        return codec.mustUnmarshalJSON(data: data)
    }
}

//// ConsensusVersion implements AppModule/ConsensusVersion.
//func (AppModule) ConsensusVersion() uint64 { return 1 }
//
//// BeginBlock executes all ABCI BeginBlock logic respective to the capability module.
//func (am AppModule) BeginBlock(_ sdk.Context, _ abci.RequestBeginBlock) {}
//
//// EndBlock executes all ABCI EndBlock logic respective to the capability module. It
//// returns no validator updates.
//func (am AppModule) EndBlock(_ sdk.Context, _ abci.RequestEndBlock) []abci.ValidatorUpdate {
//    return []abci.ValidatorUpdate{}
//}
//
//// GenerateGenesisState creates a randomized GenState of the capability module.
//func (AppModule) GenerateGenesisState(simState *module.SimulationState) {
//    simulation.RandomizedGenState(simState)
//}
//
//// ProposalContents performs a no-op
//func (am AppModule) ProposalContents(simState module.SimulationState) []simtypes.WeightedProposalContent {
//    return nil
//}
//
//// RandomizedParams creates randomized capability param changes for the simulator.
//func (AppModule) RandomizedParams(r *rand.Rand) []simtypes.ParamChange {
//    return nil
//}
//
//// RegisterStoreDecoder registers a decoder for capability module's types
//func (am AppModule) RegisterStoreDecoder(sdr sdk.StoreDecoderRegistry) {
//    sdr[types.StoreKey] = simulation.NewDecodeStore(am.cdc)
//}
//
//// WeightedOperations returns the all the gov module operations with their respective weights.
//func (am AppModule) WeightedOperations(simState module.SimulationState) []simtypes.WeightedOperation {
//    return nil
//}
//
