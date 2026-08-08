//
//  ZBUtils.m
//  Zebra
//
//  Created by Thatchapon Unprasert on 30/4/2563 BE.
//  Copyright © 2563 Wilson Styres. All rights reserved.
//

#import "ZBUtils.h"
#import <dlfcn.h>
#import <libgen.h>
#import <mach-o/dyld.h>

@implementation ZBUtils

+ (NSString *)decodeCString:(const char *)cString fallback:(NSString *)fallback {
    return cString != 0 ? ([NSString stringWithUTF8String:cString] ?: [NSString stringWithCString:cString encoding:NSASCIIStringEncoding]) : (fallback ?: NSLocalizedString(@"Unknown", @""));
}

+ (void)removeMalware {
    // Remove LicGenerator malware. This crashes with a null pointer deref because the server is long gone.
    // Our process will still crash because the bad code is already loaded. The next launch should be fine.
    // Name is split up because I don’t feel like getting false positives on awful VirusTotal AVs for this.
    // https://theapplewiki.com/wiki/MainRepoEGG
    char *dylibName = malloc(sizeof(char) * 19);
    sprintf(dylibName, "%serat%sib", "LicGen", "or.dyl");

    uint32_t i = 0;
    char *imageName;
    while ((imageName = (char *)_dyld_get_image_name(i))) {
        if (strcmp(basename(imageName), dylibName) == 0) {
            unlink(imageName);
            free(dylibName);
            [NSException raise:@"ZBMalwareRemovedException" format:@"Terminating to ensure malware removal: %s", imageName];
        }

        i++;
    }

    free(dylibName);
}

@end
