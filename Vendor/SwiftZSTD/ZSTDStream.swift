//
//  ZSTDStream.swift
//  SwiftZSTD
//
//  Created by Anatoli on 9/14/17.
//
//

import Foundation

/**
 * Types of exceptions that can be thrown when using stream operations.
 */
public enum ZSTDStreamError : Error {
    case operationInitFailure
    case operationAlreadyInProgress
    case operationNotStarted
}

/**
 * Class for compression/decompression in streaming mode.
 * 
 * An instance of this class is not intended to be thread safe.  At most one streaming
 * compression/decompression operation per instance can be active at any given time.  It is
 * possible to have a compression and decompression operation active simultaneously.
 */

public class ZSTDStream {
    
    // An Objective-C class instance wrapping C compression API.  It can be nil
    // if no decompression operation has been performed using this instance yet.
    private var decompOC : DecompressionOC? = nil
    
    public init() {}

    /**
     * Start a decompression operation.
     * No decompression operation can be already in progress.
     */
    public func startDecompression() throws {
        // Create a DecompressionOC object if needed
        if decompOC == nil { decompOC = DecompressionOC() }
        guard let unwrappedDecompOC = decompOC else { // failed to init DecompressionOC
            throw ZSTDStreamError.operationInitFailure
        }
        if (!unwrappedDecompOC.start()) {
            throw ZSTDStreamError.operationAlreadyInProgress
        }
    }
    
    /**
     * Process a chunk of data as part of a stream being decompressed.
     * - parameter dataIn: chunk of data to add to the stream being decompressed
     * - parameter isDone: true if a frame has been completely decompressed, i.e. no
     *      more input is expected
     * - returns: compressed chunk of data to be wrtitten to the decompressed output
     */
    public func decompressionProcess(dataIn : Data, isDone : inout Bool) throws -> Data {
        guard let unwrappedDecompOC = decompOC else { throw ZSTDStreamError.operationNotStarted }
        guard unwrappedDecompOC.inProgress else { throw ZSTDStreamError.operationNotStarted }
        
        var rc : Int = 0
        guard let retData = unwrappedDecompOC.processData(dataIn, withErrorCode: &rc)
        else {
            if let errStr = getProcessorErrorString(rc) {
                throw ZSTDError.libraryError(errMsg: errStr)
            } else {
                throw ZSTDError.unknownError
            }
        }
        isDone = unwrappedDecompOC.inProgress ? false : true
        return retData
    }

}
