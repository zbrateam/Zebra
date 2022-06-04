//
//  StreamHelpers.m
//  SwiftZSTD
//
//  Created by Anatoli on 9/16/17.
//
//

#import <Foundation/Foundation.h>
#import "StreamHelpers.h"

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
