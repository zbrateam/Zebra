//
//  utils.c
//  Zebra
//
//  Created by Wilson Styres on 10/13/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#include "utils.h"
#include "vercmp.h"

#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#pragma mark - SQLite Aggregation

void maxVersionStep(sqlite3_context *context, int argc, sqlite3_value **argv) {
    if (argc == 1) {
        char *candidateVersion = (char *)sqlite3_value_text(argv[0]);
        char *highestVersion = sqlite3_aggregate_context(context, 32);
        
        if ((candidateVersion != NULL && highestVersion!= NULL) && (highestVersion[0] == '\0' || compare(candidateVersion, highestVersion) > 0)) {
            strcpy(highestVersion, candidateVersion);
        }
    }
}

void maxVersionFinal(sqlite3_context *context) {
    char *highestVersion = sqlite3_aggregate_context(context, 32);
    sqlite3_result_text(context, highestVersion, -1, SQLITE_TRANSIENT);
}

#pragma mark - Dual Arrays

char** dualArrayOfSize(unsigned int size) {
    char **package = malloc(size * sizeof(char *));
    for (int i = 0; i < size; i++) {
        package[i] = malloc(512 * sizeof(void *));
        package[i][0] = '\0';
    }
    
    return package;
}

void freeDualArrayOfSize(char **arr, unsigned int size) {
    for (int i = 0; i < size; i++) {
        free(arr[i]);
    }
    free(arr);
}

char* trimWhitespaceFromString(char *str) {
    char *end;
    
    while(isspace((unsigned char)*str)) str++;
    if(*str == 0)
        return str;
    end = str + strlen(str) - 1;
    while(end > str && isspace((unsigned char)*end)) end--;
    end[1] = '\0';
    
    return str;
}

