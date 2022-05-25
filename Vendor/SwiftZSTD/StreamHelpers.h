//
//  StreamHelpers.h
//  SwiftZSTD
//
//  Created by Anatoli on 9/16/17.
//
//

@import Foundation;
#import "zstd.h"

@interface CompressionOC : NSObject

@property BOOL inProgress;

-(id)init;
-(BOOL)start:(int)compressionLevel;
-(NSData *)processData:(NSData *)dataIn andFinalize:(BOOL)flag withErrorCode:(size_t*)errorCode;

@end

@interface DecompressionOC : NSObject

@property BOOL inProgress;

-(id)init;
-(BOOL)start;
-(NSData *)processData:(NSData *)dataIn withErrorCode:(size_t*)errorCode;

@end
