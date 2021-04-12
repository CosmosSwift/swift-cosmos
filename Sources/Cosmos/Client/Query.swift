//
//  File.swift
//  
//
//  Created by Jaap Wijnen on 08/04/2021.
//

import Foundation
import AsyncHTTPClient
import Tendermint
import ABCIMessages

public struct CosmosClient {
    let url: String
    public let client: HTTPClient
    
    public init(url: String, httpClient: HTTPClient) {
        self.url = url
        self.client = httpClient
    }
}

extension CosmosClient {
    // Query performs a query to a Tendermint node with the provided path.
    // It returns the result and height of the query upon success or an error if
    // the query fails.
    public func query(path: String) -> Swift.Result<(Data, Int64), ErrorWrapper> {
        query(path: path, key: Data())
    }
//    func (ctx Context) Query(path string) ([]byte, int64, error) {
//        return ctx.query(path, nil)
//    }

    // QueryWithData performs a query to a Tendermint node with the provided path
    // and a data payload. It returns the result and height of the query upon success
    // or an error if the query fails.
    func queryWithData(path: String, data: Data) -> Swift.Result<(Data, Int64), ErrorWrapper> {
        query(path: path, key: data)
    }
//    func (ctx Context) QueryWithData(path string, data []byte) ([]byte, int64, error) {
//        return ctx.query(path, data)
//    }

    // QueryStore performs a query to a Tendermint node with the provided key and
    // store name. It returns the result and height of the query upon success
    // or an error if the query fails.
    func queryStore(key: Data, storeName: String) -> Swift.Result<(Data, Int64), ErrorWrapper> {
        queryStore(key: key, storeName: storeName, endPath: "key")
    }
//    func (ctx Context) QueryStore(key tmbytes.HexBytes, storeName string) ([]byte, int64, error) {
//        return ctx.queryStore(key, storeName, "key")
//    }

    // GetFromAddress returns the from address from the context's name.
    func queryFromAddress() -> Never /*sdk.AccAddress*/ {
        fatalError()
    }
//    func (ctx Context) GetFromAddress() sdk.AccAddress {
//        return ctx.FromAddress
//    }

    // GetFeeGranterAddress returns the fee granter address from the context
    func getFreeGranterAddress() -> Never /*sdk.AccAddress*/ {
        fatalError()
    }
//    func (ctx Context) GetFeeGranterAddress() sdk.AccAddress {
//        return ctx.FeeGranter
//    }

    // GetFromName returns the key name for the current context.
    func getFromName() -> String {
        fatalError()
    }
//    func (ctx Context) GetFromName() string {
//        return ctx.FromName
//    }
    
    // QueryABCI performs a query to a Tendermint node with the provide RequestQuery.
    // It returns the ResultQuery obtained from the query.
    func queryABCI(req: RequestQuery<Data>, height: Int64) -> Swift.Result<ResponseQuery<Data>, ErrorWrapper> {
        let client = RESTClient(url: self.url, httpClient: self.client)
        
        do {
            return try client.abciQuery(parameters: .init(path: req.path, data: req.data, height: height, prove: req.prove)).map {
                $0.result.map { $0.response }
            }.wait()
        } catch {
            return .failure(.init(error: error))
        }
        //        if !result.Response.IsOK() {
        //            return abci.ResponseQuery{}, sdkErrorToGRPCError(result.Response)
        //        }
        //
        //        // data from trusted node or subspace query doesn't need verification
        
// this last bit doesn't make sense? It returns the same in both cases?
        
        //        if !opts.Prove || !isQueryStoreWithProof(req.Path) {
        //            return result.Response, nil
        //        }
        //
        //        return result.Response, nil
    }
    
    func sdkErrorToGRPCError(response: ResponseQuery<Data>) -> Error {
        fatalError()
        //    func sdkErrorToGRPCError(resp abci.ResponseQuery) error {
        //        switch resp.Code {
        //        case sdkerrors.ErrInvalidRequest.ABCICode():
        //            return status.Error(codes.InvalidArgument, resp.Log)
        //        case sdkerrors.ErrUnauthorized.ABCICode():
        //            return status.Error(codes.Unauthenticated, resp.Log)
        //        case sdkerrors.ErrKeyNotFound.ABCICode():
        //            return status.Error(codes.NotFound, resp.Log)
        //        default:
        //            return status.Error(codes.Unknown, resp.Log)
        //        }
        //    }
    }

    // query performs a query to a Tendermint node with the provided store name
    // and path. It returns the result and height of the query upon success
    // or an error if the query fails.
    func query(path: String, key: Data /*tmbytes.HexBytes*/) -> Swift.Result<(Data, Int64), ErrorWrapper> {
        let client = RESTClient(url: self.url, httpClient: self.client)
        do {
            return try client.abciQuery(parameters: .init(path: path, data: key)).map {
                $0.result.map { response in
                    return (response.response.value, response.response.height)
                }
            }.wait()
        } catch {
            return .failure(.init(error: error))
        }
    }

    // queryStore performs a query to a Tendermint node with the provided a store
    // name and path. It returns the result and height of the query upon success
    // or an error if the query fails.
    func queryStore(key: Data /*tmbytes.HexBytes*/, storeName: String, endPath: String) -> Swift.Result<(Data, Int64), ErrorWrapper> {
        query(path: "/store/\(storeName)/\(endPath)", key: key)
    }

    // isQueryStoreWithProof expects a format like /<queryType>/<storeName>/<subpath>
    // queryType must be "store" and subpath must be "key" to require a proof.
    func isQueryStoreWithProof(path: String) -> Bool {
        if !path.hasPrefix("/") {
            return false
        }
        let paths = path.split(separator: "/")
        
        guard paths.count == 3 else { return false }
        guard paths[0] == "store" else { return false }
        if paths[2] == "key" { //rootmulti.RequireProof("/" + paths[2])
            return true
        }
        return false
    }
}

