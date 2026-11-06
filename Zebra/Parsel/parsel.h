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
#include <stdbool.h>
#include <sqlite3.h>
#include <string.h>
#include <libgen.h>
#include "dict.h"

#define LONG_DESCRIPTION_MAX_LENGTH 32768
#define DEPENDS_MAX_LENGTH 512

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

bool parseControlLine(char *line, dict *package, char *longDescription, size_t longDescriptionSize, char *depends, size_t dependsSize, bool *longDescFlag);
void createTable(sqlite3 *database, int table);
int needsMigration(sqlite3 *database, int table);
enum PARSEL_RETURN_TYPE importSourceToDatabase(struct ZBBaseSource source, const char *releasePath, sqlite3 *database, int sourceID);
enum PARSEL_RETURN_TYPE updateSourceInDatabase(struct ZBBaseSource source, const char *releasePath, sqlite3 *database, int sourceID);
enum PARSEL_RETURN_TYPE addPaymentEndpointForSource(const char *endpointURL, sqlite3 *database, int sourceID);
void createDummySource(struct ZBBaseSource source, sqlite3 *database, int sourceID);
enum PARSEL_RETURN_TYPE importPackagesToDatabase(const char *path, sqlite3 *database, int sourceID);
enum PARSEL_RETURN_TYPE updatePackagesInDatabase(const char *path, sqlite3 *database, int sourceID, sqlite3_int64 currentDate);

#endif /* parsel_h */
