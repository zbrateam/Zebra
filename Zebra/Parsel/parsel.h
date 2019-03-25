//
//  parsel.h
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#ifndef parsel_h
#define parsel_h

#include <stdio.h>
#include <sqlite3.h>
#include <string.h>
#include <libgen.h>

void importRepoToDatabase(const char *sourcePath, const char *path, sqlite3 *database, int repoID);
void updateRepoInDatabase(const char *sourcePath, const char *path, sqlite3 *database, int repoID);
void importPackagesToDatabase(const char *path, sqlite3 *database, int repoID);
void updatePackagesInDatabase(const char *path, sqlite3 *database, int repoID);

#endif /* parsel_h */
