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
        let client = RESTClient(url: txFlags.node.description, httpClient: httpClient)
        
        let response = try client.broadcastTransaction(
            params: .init(transaction: standardTransaction.encoded!)
        ).flatMapResult { wrappedBroadcastTransactionResponse in
            wrappedBroadcastTransactionResponse.result
        }.wait()
        
        //return clientCtx.PrintProto(res)
        print(response)
    }
}
