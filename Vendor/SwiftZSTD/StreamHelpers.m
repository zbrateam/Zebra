//
//  StreamHelpers.m
//  SwiftZSTD
//
//  Created by Anatoli on 9/16/17.
//
//

#import <Foundation/Foundation.h>
#import "StreamHelpers.h"

@implementation CompressionOC {
    ZSTD_CStream * cStream;
    uint8_t * outputData;
    size_t outputSize;
}

-(id)init {
    outputSize = ZSTD_CStreamOutSize();
    outputData = (uint8_t*)malloc(outputSize);
    if (!outputData) return nil;

    cStream = ZSTD_createCStream();
    self.inProgress = NO;
    
    return self;
}

-(BOOL)start:(int)compressionLevel {
    if (self.inProgress) return NO;
    ZSTD_initCStream(cStream, compressionLevel);
    return self.inProgress = YES;
}

-(NSData *)processData:(NSData *)d andFinalize:(BOOL)flag withErrorCode:(size_t*)errorCode {
    ZSTD_inBuffer inBuffer;
    inBuffer.src = d.bytes;
    inBuffer.pos = 0;
    inBuffer.size = d.length;
    
    ZSTD_outBuffer outBuffer;
    outBuffer.dst = outputData;
    outBuffer.pos = 0;
    outBuffer.size = outputSize;
    
    *errorCode = 0;
    
    // Set up the return value to be of input size, which should suffice
    NSMutableData * retVal = [NSMutableData dataWithCapacity: d.length];

    do {
        size_t remainingBytes = 0;
        size_t rc = ZSTD_compressStream(cStream, &outBuffer, &inBuffer);
        if (ZSTD_isError(rc)) { *errorCode = rc; return nil; }
        size_t(*flusher)(ZSTD_CStream *, ZSTD_outBuffer *) =
            !flag || inBuffer.pos < inBuffer.size ? ZSTD_flushStream : ZSTD_endStream;
        do {
            remainingBytes = flusher(cStream, &outBuffer);
            if (ZSTD_isError(remainingBytes)) { *errorCode = remainingBytes; return nil; }
            [retVal appendBytes:outBuffer.dst length:outBuffer.pos];
            outBuffer.pos = 0;
        } while (remainingBytes > 0);
    } while (inBuffer.pos < inBuffer.size);

    if (flag) self.inProgress = NO;
        
    return retVal;
}

-(void)dealloc {
    free(outputData);
    ZSTD_freeCStream(cStream);
}

@end

@implementation DecompressionOC {
    ZSTD_DStream * dStream;
    uint8_t * outputData;
    size_t outputSize;
}

-(id)init {
    outputSize = ZSTD_DStreamOutSize();
    outputData = (uint8_t*)malloc(outputSize);
    if (!outputData) return nil;
    
    dStream = ZSTD_createDStream();
    self.inProgress = NO;
    
    return self;
}

-(BOOL)start {
    if (self.inProgress) return NO;
    ZSTD_initDStream(dStream);
    return self.inProgress = YES;
}

-(NSData *)processData:(NSData *)d withErrorCode:(size_t*)errorCode {    
    ZSTD_inBuffer inBuffer;
    inBuffer.src = d.bytes;
    inBuffer.pos = 0;
    inBuffer.size = d.length;
    
    ZSTD_outBuffer outBuffer;
    outBuffer.dst = outputData;
    outBuffer.pos = 0;
    outBuffer.size = outputSize;
    
    *errorCode = 0;
    
    // Just in case, initially allocate 3 x input size for the return value
    // Even using 0 for the initial capacity works, so it is just a slight
    // efficiency improvement.
    NSMutableData * retVal = [NSMutableData dataWithCapacity: 3 * d.length];

    do {
        size_t rc = ZSTD_decompressStream(dStream, &outBuffer, &inBuffer);
        if (ZSTD_isError(rc)) { *errorCode = rc; return nil; }
        [retVal appendBytes:outBuffer.dst length:outBuffer.pos];
        if (rc == 0) { self.inProgress = NO;  return retVal; }
        outBuffer.pos = 0;
    } while (inBuffer.pos < inBuffer.size);

    return retVal;
}

-(void)dealloc {
    free(outputData);
    ZSTD_freeDStream(dStream);
}

@end
