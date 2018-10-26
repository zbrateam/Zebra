#import <Foundation/Foundation.h>

bool packages_file_changed(FILE* f1, FILE* f2) {
    @autoreleasepool {
        int N = 0x1000;
        char buf1[N];
        char buf2[N];
        
        do {
            size_t r1 = fread(buf1, 1, N, f1);
            size_t r2 = fread(buf2, 1, N, f2);
            
            if (r1 != r2 || memcmp(buf1, buf2, r1)) {
                return true;
            }
        } while (!feof(f1) && !feof(f2));
        
        return false;
    }
}

NSArray *packages_to_array(const char *path)
{
    @autoreleasepool {
        CFMutableArrayRef packages = CFArrayCreateMutable(kCFAllocatorDefault, 10, &kCFTypeArrayCallBacks);
        
        FILE* file = fopen(path, "r");
        char line[256];
        
        CFMutableDictionaryRef package = CFDictionaryCreateMutable(kCFAllocatorDefault, 10, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        while (fgets(line, sizeof(line), file)) {
            if (strcmp(line, "\n") != 0) {
                const char *info = strtok(line, "\n");
                int len = (int)strlen(info);
                char *colon = strchr(info, ':');
                if (colon != NULL) {
                    int colonIndex = (int)(colon - info);
                    
                    const UInt8 *bytes = (const UInt8 *)info;
                    CFStringRef key = CFStringCreateWithBytes(kCFAllocatorDefault, bytes, colonIndex, kCFStringEncodingUTF8, true);
                    bytes += colonIndex + 2;
                    CFStringRef value = CFStringCreateWithBytes(kCFAllocatorDefault, bytes, len - (colonIndex + 1), kCFStringEncodingUTF8, true);
                    if (key != NULL && value != NULL && CFStringGetLength(value) != 0) {
                        CFDictionaryAddValue(package, key, value);
                    }
                }
            }
            else {
                CFArrayAppendValue(packages, CFDictionaryCreateCopy(kCFAllocatorDefault, package));
                CFDictionaryRemoveAllValues(package);
            }
        }
        
        fclose(file);
        
        return (__bridge NSArray*)packages;
    }
}
