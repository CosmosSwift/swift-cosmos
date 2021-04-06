import Foundation
import ArgumentParser
import Cosmos
import AsyncHTTPClient
import Tendermint


// GetBroadcastCommand returns the tx broadcast command.
public struct GetBroadcast: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "broadcast",
        abstract: "Broadcast transactions generated offline",
        discussion: """
             Broadcast transactions created with the --generate-only
             flag and signed with the sign command. Read a transaction from [file_path] and
             broadcast it to a node. If you supply a dash (-) argument in place of an input
             filename, the command reads from standard input.
             $ <appd> tx broadcast ./mytxn.json
            """
    )
    
    @OptionGroup var txFlags: Flags.TransactionFlags
  
    @Argument var filePath: String

    public init() {}
    
//    struct Payload: RequestPayload {
//        static var method: ABCIREST.Method { .abci_query }
//        var path: String { "custom/acc/" }
//
//        typealias ResponsePayload = AnyProtocolCodable // This is an Account
//
//        let Address: AccountAddress
//        
//    }
    
    public mutating func run() throws {
        if txFlags.offline {
            #warning("Then why do we support having this flag here?")
            fatalError("Cannot broadcast tx during offline mode")
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        let transactionData = try Data(contentsOf: fileURL)

        let jsonDecoder = JSONDecoder()
        let standardTransaction = try jsonDecoder.decode(StandardTransaction.self, from: transactionData)
        
        let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        let client = RESTClient(url: "http://192.168.64.1:26657", httpClient: httpClient)
        
        let response = try client.broadcastTransaction(
            params: .init(transaction: standardTransaction.encoded!)
        ).flatMapResult { wrappedBroadcastTransactionResponse in
            wrappedBroadcastTransactionResponse.result
        }.wait()
        
        //return clientCtx.PrintProto(res)
        print(response)
    }
}





/*
 
 
 package cli

 import (
     "errors"
     "strings"

     "github.com/spf13/cobra"

     "github.com/cosmos/cosmos-sdk/client"
     "github.com/cosmos/cosmos-sdk/client/flags"
     authclient "github.com/cosmos/cosmos-sdk/x/auth/client"
 )

 // GetBroadcastCommand returns the tx broadcast command.
 func GetBroadcastCommand() *cobra.Command {
     cmd := &cobra.Command{
         Use:   "broadcast [file_path]",
         Short: "Broadcast transactions generated offline",
         Long: strings.TrimSpace(`Broadcast transactions created with the --generate-only
 flag and signed with the sign command. Read a transaction from [file_path] and
 broadcast it to a node. If you supply a dash (-) argument in place of an input
 filename, the command reads from standard input.
 $ <appd> tx broadcast ./mytxn.json
 `),
         Args: cobra.ExactArgs(1),
         RunE: func(cmd *cobra.Command, args []string) error {
             clientCtx, err := client.GetClientTxContext(cmd)
             if err != nil {
                 return err
             }

             if offline, _ := cmd.Flags().GetBool(flags.FlagOffline); offline {
                 return errors.New("cannot broadcast tx during offline mode")
             }

             stdTx, err := authclient.ReadTxFromFile(clientCtx, args[0])
             if err != nil {
                 return err
             }

             txBytes, err := clientCtx.TxConfig.TxEncoder()(stdTx)
             if err != nil {
                 return err
             }

             res, err := clientCtx.BroadcastTx(txBytes)
             if err != nil {
                 return err
             }

             return clientCtx.PrintProto(res)
         },
     }

     flags.AddTxFlagsToCmd(cmd)

     return cmd
 }
 */
