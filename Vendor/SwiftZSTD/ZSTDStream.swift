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
    // An Objective-C class instance wrapping C compression API. It can be nil
    // if no compression operation has been performed using this instance yet.
    var compOC : CompressionOC? = nil
    
    // An Objective-C class instance wrapping C compression API.  It can be nil
    // if no decompression operation has been performed using this instance yet.
    var decompOC : DecompressionOC? = nil
    
    public init() {}
    
    /**
     * Start a compression operation using the given compression level.
     * Compression level must be valid, and no compression operation can be already
     * in progress
     * - parameter compressionLevel: compression level to use
     */
    public func startCompression(compressionLevel : Int32) throws {
        guard isValidCompressionLevel(compressionLevel) else {
            throw ZSTDError.invalidCompressionLevel(cl: compressionLevel)
        }
        // Create a CompressionOC object if needed
        if compOC == nil { compOC = CompressionOC() }
        guard let unwrappedCompOC = compOC else { // failed to init CompressionOC
            throw ZSTDStreamError.operationInitFailure
        }
        if (!unwrappedCompOC.start(compressionLevel)) {
            throw ZSTDStreamError.operationAlreadyInProgress
        }
    }
    
    /**
     * Process a chunk of data as part of a stream being compressed.
     * Operation must have been started prior to calling this method.
     * - parameter dataIn: chunk of input data to compress
     * - returns: compressed chunk of output data
     */
    public func compressionProcess(dataIn : Data) throws -> Data {
        return try compressionHelper(dataIn: dataIn, finalize: false)
    }
    
    /**
     * Process the last chunk of the stream being compressed and finalize the stream.
     * Operation must have been started prior to calling this method.
     * - parameter dataIn: chunk of data to add to the stream being compressed
     * - returns: compressed chunk of output data
     */
    public func compressionFinalize(dataIn : Data) throws -> Data {
        return try compressionHelper(dataIn: dataIn, finalize: true)
    }
    
    /**
     * A helper used by compression processing & finalization methods.
     * - parameter dataIn: chunk of data to be compressed as part of the stream
     * - parameter finalize: true if this is the last chunk
     * - returns: compressed chunk of output data
     */
    fileprivate func compressionHelper(dataIn: Data, finalize: Bool) throws -> Data {
        guard let unwrappedCompOC = compOC else { throw ZSTDStreamError.operationNotStarted }
        guard unwrappedCompOC.inProgress else { throw ZSTDStreamError.operationNotStarted }

        var rc : Int = 0
        guard let retData = unwrappedCompOC.processData(dataIn, andFinalize: finalize, withErrorCode: &rc)
        else {
            if let errStr = getProcessorErrorString(rc) {
                throw ZSTDError.libraryError(errMsg: errStr)
            } else {
                throw ZSTDError.unknownError
            }
        }
        return retData
    }

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
