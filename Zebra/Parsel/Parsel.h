//
//  Parsel.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#ifndef Parsel_h
#define Parsel_h

#include <stdio.h>
#include <sqlite3.h>
#include <string.h>

void importRepoToDatabase(const char *path, sqlite3 *database, int repoID);
void importPackagesToDatabase(const char *path, sqlite3 *database, int repoID);

#endif /* parse_h */
