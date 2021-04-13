//
//  File.swift
//  
//
//  Created by Jaap Wijnen on 16/03/2021.
//
import NIO
import Tendermint
import ABCIMessages

internal func getBlocksForTransactionResults(transactionResponses: [Tendermint.TransactionResponse], restClient: RESTClient) -> EventLoopFuture<[Int64: BlockResponse]> {
    
    
    // filter responses with same height parameter
    let heights = Set(transactionResponses.map { $0.height })
    
    let futures = heights.map { height in
        getBlockForHeight(height: height, restClient: restClient).map { blockResponse in
            return (height, blockResponse)
        }
    }

    return EventLoopFuture.whenAllSucceed(futures, on: restClient.client.eventLoopGroup.next()).map { results in
        return results.reduce(into: [:]) { $0[$1.0] = $1.1 }
    }
}

private func getBlockForHeight(height: Int64, restClient: RESTClient) -> EventLoopFuture<BlockResponse> {
    restClient.block(params: .init(height: height)).flatMap { response in
        switch response.result {
        case let .success(value):
            return restClient.client.eventLoopGroup.next().makeSucceededFuture(value)
        case let .failure(error):
            return restClient.client.eventLoopGroup.next().makeFailedFuture(error)
        }
    }
}

internal func getBlockForTransactionResult(transactionResponse: Tendermint.TransactionResponse, restClient: RESTClient) -> EventLoopFuture<BlockResponse> {
    getBlockForHeight(height: transactionResponse.height, restClient: restClient)
}
