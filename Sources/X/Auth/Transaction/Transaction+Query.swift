//
//  File.swift
//  
//
//  Created by Jaap Wijnen on 16/03/2021.
//
import NIO
import Tendermint

internal func getBlocksForTransactionResults(transactionResponses: [TransactionResponse], restClient: RESTClient) -> EventLoopFuture<[Int64: BlockResponse]> {

    // filter responses with same height parameter
    let heights = Set(transactionResponses.map { $0.height })

    let futures = heights.map { height in
        return restClient.block(params: .init(height: height)).flatMap { response -> EventLoopFuture<(Int64, BlockResponse)> in
            switch response.result {
            case let .success(value):
                return restClient.client.eventLoopGroup.next().makeSucceededFuture((height, value))
            case let .failure(error):
                // maybe we should return a failed future if there's no value?
                return restClient.client.eventLoopGroup.next().makeFailedFuture(error)
            }
        }
    }

    return EventLoopFuture.whenAllSucceed(futures, on: restClient.client.eventLoopGroup.next()).map { results in
        return results.reduce(into: [:]) { $0[$1.0] = $1.1 }
    }
}
