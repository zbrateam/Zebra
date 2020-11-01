//
//  utils.h
//  Zebra
//
//  Created by Wilson Styres on 10/13/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#include <sqlite3.h>

#ifndef utils_h
#define utils_h

void maxVersionStep(sqlite3_context *context, int argc, sqlite3_value **argv);
void maxVersionFinal(sqlite3_context *context);

char** dualArrayOfSize(unsigned int size);
void freeDualArrayOfSize(char **arr, unsigned int size);
char* trimWhitespaceFromString(char *str);

#endif /* utils_h */
