/*
 package rpc

 import (
     "context"
     "fmt"
     "net/http"
     "strconv"

     "github.com/gorilla/mux"
     "github.com/spf13/cobra"

     "github.com/cosmos/cosmos-sdk/client"
     "github.com/cosmos/cosmos-sdk/client/flags"
     "github.com/cosmos/cosmos-sdk/codec/legacy"
     "github.com/cosmos/cosmos-sdk/types/rest"
 )
 */
import ArgumentParser
import Tendermint
import ABCIMessages
import AsyncHTTPClient


/*public struct GetAccount: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "account",
        abstract: "Query for account by address"
    )
    
    @OptionGroup var queryFlags: Flags.QueryFlags

    @Argument var address: AccountAddress
    
    
    struct GetAccountPayload: Codable {
        let Address: AccountAddress
    }
    
    public init() {}
        
    public mutating func run() throws {
        // TODO: map url to the proper value
        let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        let client = RESTClient(url: queryFlags.node.description, httpClient: httpClient)
        let height: Int64 = 4
        let prove = false
        
        let params = RESTABCIQueryParameters(path: "custom/acc/account", data: GetAccountPayload(Address: self.address), height: height, prove: prove)
        
        let response: RESTResponse<ABCIQueryResponse<AnyProtocolCodable>> = try client.abciQueryMapToData(parameters: params).wait()
                
        let data = try JSONEncoder().encode(response)
        
        print(String(data: data, encoding: .utf8)!)
    }
}*/

extension Height: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(string: argument)
    }
}

public struct BlockCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "block",
        abstract: "Get verified data for a the block at given height"
    )
    
    @Option(name: .shortAndLong, help: "<host>:<port> Node to connect to")
    public var node: Flags.NodeURL = .init()!
        
    @Argument var height: Height
    
    public init() { }
    
    public mutating func run() throws {
        let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        let client = RESTClient(url: node.description, httpClient: httpClient)
        
        
        let blockResponse = try client.block(params: .init(height: height))
            .flatMapResult { wrappedBlockResponse in
                return wrappedBlockResponse.result
            }.wait()
        
//        output, err := legacy.Cdc.MarshalJSON(res)
//        fmt.Println(string(output))
        print(blockResponse)
    }
}

/*
 // get the current blockchain height
 func GetChainHeight(clientCtx client.Context) (int64, error) {
     node, err := clientCtx.GetNode()
     if err != nil {
         return -1, err
     }

     status, err := node.Status(context.Background())
     if err != nil {
         return -1, err
     }

     height := status.SyncInfo.LatestBlockHeight
     return height, nil
 }

 // REST handler to get a block
 func BlockRequestHandlerFn(clientCtx client.Context) http.HandlerFunc {
     return func(w http.ResponseWriter, r *http.Request) {
         vars := mux.Vars(r)

         height, err := strconv.ParseInt(vars["height"], 10, 64)
         if err != nil {
             rest.WriteErrorResponse(w, http.StatusBadRequest,
                 "couldn't parse block height. Assumed format is '/block/{height}'.")
             return
         }

         chainHeight, err := GetChainHeight(clientCtx)
         if err != nil {
             rest.WriteErrorResponse(w, http.StatusInternalServerError, "failed to parse chain height")
             return
         }

         if height > chainHeight {
             rest.WriteErrorResponse(w, http.StatusNotFound, "requested block height is bigger then the chain length")
             return
         }

         output, err := getBlock(clientCtx, &height)
         if rest.CheckInternalServerError(w, err) {
             return
         }

         rest.PostProcessResponseBare(w, clientCtx, output)
     }
 }

 // REST handler to get the latest block
 func LatestBlockRequestHandlerFn(clientCtx client.Context) http.HandlerFunc {
     return func(w http.ResponseWriter, r *http.Request) {
         output, err := getBlock(clientCtx, nil)
         if rest.CheckInternalServerError(w, err) {
             return
         }

         rest.PostProcessResponseBare(w, clientCtx, output)
     }
 }

 */
