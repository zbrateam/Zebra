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

struct ZBBaseSource {
    const char *archiveType;
    const char *repositoryURI;
    const char *distribution;
    const char *components;
    const char *baseFilename;
};

enum PARSEL_RETURN_TYPE {
    PARSEL_OK,
    PARSEL_FILENOTFOUND
};

void createTable(sqlite3 *database, int table);
int needsMigration(sqlite3 *database, int table);
enum PARSEL_RETURN_TYPE importRepoToDatabase(struct ZBBaseSource source, const char *endpointURL, const char *releasePath, sqlite3 *database, int repoID);
enum PARSEL_RETURN_TYPE updateRepoInDatabase(struct ZBBaseSource source, const char *endpointURL, const char *releasePath, sqlite3 *database, int repoID);
void createDummyRepo(const char *packagesPath, sqlite3 *database, int repoID);
enum PARSEL_RETURN_TYPE importPackagesToDatabase(const char *path, sqlite3 *database, int repoID);
enum PARSEL_RETURN_TYPE updatePackagesInDatabase(const char *path, sqlite3 *database, int repoID, sqlite3_int64 currentDate);

#endif /* parsel_h */
