//
//  File.swift
//  
//
//  Created by Alex Tran-Qui on 06/03/2021.
//

import Foundation
import NIO
import Tendermint

// BroadcastTx broadcasts a transactions either synchronously or asynchronously
// based on the context parameters. The result of the broadcast is parsed into
// an intermediate structure which is logged if the context has a logger
// defined.

extension RESTClient {
    public func broadcastTransaction(params: RESTBroadcastTransactionParameters, mode: Flags.TransactionFlags.BroadcastMode = .block) -> EventLoopFuture<RESTResponse<TransactionResponse>> {
        switch mode {
        case .sync:
            // BroadcastTxSync broadcasts transaction bytes to a Tendermint node
            // synchronously (i.e. returns after CheckTx execution).
            return self.broadcastTransactionSync(params: params).map { response in
                // RESTResponse<BroadcastTransactionResponse> -> RESTResponse<TransactionResponse>
                if let checked = checkTendermintError(response.result, params.transaction) {
                    return response.map { _ in checked }
                }
                return response.map { TransactionResponse($0) }
            }
        case .async:
            // BroadcastTxAsync broadcasts transaction bytes to a Tendermint node
            // asynchronously (i.e. returns immediately).
            return self.broadcastTransactionAsync(params: params).map { response in
                // RESTResponse<BroadcastTransactionResponse> -> RESTResponse<TransactionResponse>
                if let checked = checkTendermintError(response.result, params.transaction) {
                    return response.map { _ in checked }
                }
                return response.map { TransactionResponse($0) }
            }
        case .block:
            // BroadcastTxCommit broadcasts transaction bytes to a Tendermint node and
            // waits for a commit. An error is only returned if there is no RPC node
            // connection or if broadcasting fails.
            //
            // NOTE: This should ideally not be used as the request may timeout but the tx
            // may still be included in a block. Use BroadcastTxAsync or BroadcastTxSync
            // instead.
            return self.broadcastTransactionCommit(params: params).map { response in
                // RESTResponse<BroadcastTransactionCommitResponse> -> RESTResponse<TransactionResponse>
                
                
                if let checked = checkTendermintError(response.result, params.transaction) {
                    return response.map { _ in checked }
                }
                return response.map { TransactionResponse($0) }
            }
        }
    }
}

// CheckTendermintError checks if the error returned from BroadcastTx is a
// Tendermint error that is returned before the tx is submitted due to
// precondition checks that failed. If an Tendermint error is detected, this
// function returns the correct code back in TxResponse.
//
// TODO: Avoid brittle string matching in favor of error matching. This requires
// a change to Tendermint's RPCError type to allow retrieval or matching against
// a concrete error type.
func checkTendermintError<Payload: Codable>(_ result: Swift.Result<Payload, ErrorWrapper>, _ transaction: TransactionBytes) ->
TransactionResponse? {
    
    switch result {
    case .success:
        return nil
    case let .failure(error):
        let errorString: String = "\(error)"
        let hash = Tendermint.Hash.sum(data: transaction)

        if errorString.contains("tx already exists in cache") { // mempool.ErrTxInCache.Error()
            return TransactionResponse(CosmosError.errTxInMempoolCache.code, hash)
        } else if errorString.contains("mempool is full") {
            return TransactionResponse(CosmosError.errMempoolIsFull.code, hash)
        } else if errorString.contains("tx too large") {
            return TransactionResponse(CosmosError.errTxTooLarge.code, hash)
        }
        return nil
    }
}

/*
 package context

 import (
     "fmt"
     "strings"

     "github.com/tendermint/tendermint/crypto/tmhash"
     "github.com/tendermint/tendermint/mempool"

     "github.com/cosmos/cosmos-sdk/client/flags"
     sdk "github.com/cosmos/cosmos-sdk/types"
     sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
 )

 // BroadcastTx broadcasts a transactions either synchronously or asynchronously
 // based on the context parameters. The result of the broadcast is parsed into
 // an intermediate structure which is logged if the context has a logger
 // defined.
 func (ctx CLIContext) BroadcastTx(txBytes []byte) (res sdk.TxResponse, err error) {
     switch ctx.BroadcastMode {
     case flags.BroadcastSync:
         res, err = ctx.BroadcastTxSync(txBytes)

     case flags.BroadcastAsync:
         res, err = ctx.BroadcastTxAsync(txBytes)

     case flags.BroadcastBlock:
         res, err = ctx.BroadcastTxCommit(txBytes)

     default:
         return sdk.TxResponse{}, fmt.Errorf("unsupported return type %s; supported types: sync, async, block", ctx.BroadcastMode)
     }

     return res, err
 }

 // CheckTendermintError checks if the error returned from BroadcastTx is a
 // Tendermint error that is returned before the tx is submitted due to
 // precondition checks that failed. If an Tendermint error is detected, this
 // function returns the correct code back in TxResponse.
 //
 // TODO: Avoid brittle string matching in favor of error matching. This requires
 // a change to Tendermint's RPCError type to allow retrieval or matching against
 // a concrete error type.
 func CheckTendermintError(err error, txBytes []byte) *sdk.TxResponse {
     if err == nil {
         return nil
     }

     errStr := strings.ToLower(err.Error())
     txHash := fmt.Sprintf("%X", tmhash.Sum(txBytes))

     switch {
     case strings.Contains(errStr, strings.ToLower(mempool.ErrTxInCache.Error())):
         return &sdk.TxResponse{
             Code:   sdkerrors.ErrTxInMempoolCache.ABCICode(),
             TxHash: txHash,
         }

     case strings.Contains(errStr, "mempool is full"):
         return &sdk.TxResponse{
             Code:   sdkerrors.ErrMempoolIsFull.ABCICode(),
             TxHash: txHash,
         }

     case strings.Contains(errStr, "tx too large"):
         return &sdk.TxResponse{
             Code:   sdkerrors.ErrTxTooLarge.ABCICode(),
             TxHash: txHash,
         }

     default:
         return nil
     }
 }

 // BroadcastTxCommit broadcasts transaction bytes to a Tendermint node and
 // waits for a commit. An error is only returned if there is no RPC node
 // connection or if broadcasting fails.
 //
 // NOTE: This should ideally not be used as the request may timeout but the tx
 // may still be included in a block. Use BroadcastTxAsync or BroadcastTxSync
 // instead.
 func (ctx CLIContext) BroadcastTxCommit(txBytes []byte) (sdk.TxResponse, error) {
     node, err := ctx.GetNode()
     if err != nil {
         return sdk.TxResponse{}, err
     }

     res, err := node.BroadcastTxCommit(txBytes)
     if err != nil {
         if errRes := CheckTendermintError(err, txBytes); errRes != nil {
             return *errRes, nil
         }

         return sdk.NewResponseFormatBroadcastTxCommit(res), err
     }

     if !res.CheckTx.IsOK() {
         return sdk.NewResponseFormatBroadcastTxCommit(res), nil
     }

     if !res.DeliverTx.IsOK() {
         return sdk.NewResponseFormatBroadcastTxCommit(res), nil
     }

     return sdk.NewResponseFormatBroadcastTxCommit(res), nil
 }

 // BroadcastTxSync broadcasts transaction bytes to a Tendermint node
 // synchronously (i.e. returns after CheckTx execution).
 func (ctx CLIContext) BroadcastTxSync(txBytes []byte) (sdk.TxResponse, error) {
     node, err := ctx.GetNode()
     if err != nil {
         return sdk.TxResponse{}, err
     }

     res, err := node.BroadcastTxSync(txBytes)
     if errRes := CheckTendermintError(err, txBytes); errRes != nil {
         return *errRes, nil
     }

     return sdk.NewResponseFormatBroadcastTx(res), err
 }

 // BroadcastTxAsync broadcasts transaction bytes to a Tendermint node
 // asynchronously (i.e. returns immediately).
 func (ctx CLIContext) BroadcastTxAsync(txBytes []byte) (sdk.TxResponse, error) {
     node, err := ctx.GetNode()
     if err != nil {
         return sdk.TxResponse{}, err
     }

     res, err := node.BroadcastTxAsync(txBytes)
     if errRes := CheckTendermintError(err, txBytes); errRes != nil {
         return *errRes, nil
     }

     return sdk.NewResponseFormatBroadcastTx(res), err
 }

 */
