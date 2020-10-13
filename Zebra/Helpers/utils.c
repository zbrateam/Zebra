//
//  utils.c
//  Zebra
//
//  Created by Wilson Styres on 10/13/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#include "utils.h"

#include <stdlib.h>
#include <string.h>
#include <ctype.h>

char **dualArrayOfSize(unsigned int size) {
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

char *trimWhitespaceFromString(char *str) {
    char *end;
    
    while(isspace((unsigned char)*str)) str++;
    if(*str == 0)
        return str;
    end = str + strlen(str) - 1;
    while(end > str && isspace((unsigned char)*end)) end--;
    end[1] = '\0';
    
    return str;
}

