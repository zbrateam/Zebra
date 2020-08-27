//
//  parsel.c
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#include "parsel.h"
#include "dict.h"
#include <ctype.h>
#include <stdlib.h>
#include <stdbool.h>
#include <time.h>
#include <Database/ZBColumn.h>

#define LONG_DESCRIPTION_MAX_LENGTH 32768

char *trim(char *s) {
    size_t size = strlen(s);
    if (!size)
        return s;
    char *end = s + size - 1;
    while (end >= s && (*end == '\n' || *end == '\r' || isspace(*end)))
        end--; // remove trailing space
    *(end + 1) = '\0';
    return s;
}

typedef char *multi_tok_t;

char *multi_tok(char *input, multi_tok_t *string, char *delimiter) {
    if (input != NULL)
        *string = input;
    
    if (*string == NULL)
        return *string;
    
    if (delimiter == NULL)
        return *string;
    
    char *end = strstr(*string, delimiter);
    if (end == NULL) {
        char *temp = *string;
        *string = NULL;
        return temp;
    }
    
    char *temp = *string;
    
    *end = '\0';
    *string = end + strlen(delimiter);
    return temp;
}

multi_tok_t init() { return NULL; }

char *replace_char(char *str, char find, char replace) {
    char *current_pos = strchr(str, find);
    while (current_pos) {
        *current_pos = replace;
        current_pos = strchr(current_pos, find);
    }
    return str;
}

int isSourceSecure(const char *sourcePath, char *sourceURL) {
    FILE *file = fopen(sourcePath, "r");
    if (file != NULL) {
        char line[256];
        
        char *url = strtok(sourceURL, "_");
        
        while (fgets(line, sizeof(line), file) != NULL) {
            if (strcasestr(line, url) != NULL && line[8] == 's') {
                return 1;
            }
        }
    }
    return 0;
}

char *sourcesSchema() {
    return "REPOS(TYPE STRING, URI STRING, DISTRIBUTION STRING, COMPONENTS STRING, DESCRIPTION STRING, ORIGIN STRING, LABEL STRING, VERSION VARCHAR(16), SUITE STRING, CODENAME STRING, ARCHITECTURES STRING, VENDOR STRING, BASEFILENAME STRING, REPOID INTEGER PRIMARY KEY)";
}

const char *sourceInsertQuery = "INSERT INTO REPOS(TYPE, URI, DISTRIBUTION, COMPONENTS, DESCRIPTION, ORIGIN, LABEL, VERSION, SUITE, CODENAME, ARCHITECTURES, VENDOR, BASEFILENAME, REPOID) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";

const char *sourceUpdateQuery = "UPDATE REPOS SET (TYPE, URI, DISTRIBUTION, COMPONENTS, DESCRIPTION, ORIGIN, LABEL, VERSION, SUITE, CODENAME, ARCHITECTURES, VENDOR, BASEFILENAME) = (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) WHERE REPOID = ?;";

char *packagesSchema() {
    return "PACKAGES(PACKAGE STRING, NAME STRING, VERSION VARCHAR(16), TAGLINE STRING, DESCRIPTION STRING, SECTION STRING, DEPICTION STRING, TAG STRING, AUTHORNAME STRING, AUTHOREMAIL STRING, DEPENDS STRING, CONFLICTS STRING, PROVIDES STRING, REPLACES STRING, FILENAME STRING, ICON STRING, REPOID INTEGER, LASTSEEN TIMESTAMP, INSTALLEDSIZE INTEGER, DOWNLOADSIZE INTEGER, PRIORITY STRING, ESSENTIAL STRING, SHA256 STRING, HEADER STRING, CHANGELOGTITLE STRING, CHANGELOG STRING, HOMEPAGE STRING, PREVIEWS STRING, MAINTAINERNAME STRING, MAINTAINEREMAIL STRING, PREFERNATIVE STRING)";
}

const char *packageInsertQuery = "INSERT INTO PACKAGES(PACKAGE, NAME, VERSION, TAGLINE, DESCRIPTION, SECTION, DEPICTION, TAG, AUTHORNAME, AUTHOREMAIL, DEPENDS, CONFLICTS, PROVIDES, REPLACES, FILENAME, ICON, REPOID, LASTSEEN, INSTALLEDSIZE, DOWNLOADSIZE, PRIORITY, ESSENTIAL, SHA256, HEADER, CHANGELOGTITLE, CHANGELOG, HOMEPAGE, PREVIEWS, MAINTAINERNAME, MAINTAINEREMAIL, PREFERNATIVE) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";

char *updatesSchema() {
    return "UPDATES(PACKAGE STRING PRIMARY KEY, VERSION VARCHAR(16) NOT NULL, IGNORE INTEGER DEFAULT 0)";
}

char *schemaForTable(int table) {
    switch (table) {
        case 0:
            return sourcesSchema();
        case 1:
            return packagesSchema();
        case 2:
            return updatesSchema();
    }
    
    return NULL;
}

int needsMigration(sqlite3 *database, int table) {
    if (table < 0 || table > 2)
        return 0;
    char query[100];
    char *tableNames[20] = { "REPOS", "PACKAGES", "UPDATES" };
    snprintf(query, sizeof(query), "SELECT sql FROM sqlite_master WHERE name = \"%s\";", tableNames[table]);
    char *schema = NULL;
    
    sqlite3_stmt *statement = NULL;
    
    if (sqlite3_prepare_v2(database, query, -1, &statement, 0) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            schema = (char *)sqlite3_column_text(statement, 0);
            break;
        }
        
        if (schema != NULL) {
            // Remove CREATE TABLE
            multi_tok_t s = init();
            multi_tok(schema, &s, "CREATE TABLE ");
            schema = multi_tok(NULL, &s, "CREATE TABLE ");
            
            int result = strcmp(schema, schemaForTable(table));
            sqlite3_finalize(statement);
            return result;
        }
    } else {
        printf("[Zebra] Error creating migration check statement: %s\n", sqlite3_errmsg(database));
    }
    return 0;
}

void createTable(sqlite3 *database, int table) {
    char sql[1024] = "CREATE TABLE IF NOT EXISTS ";
    switch (table) {
        case 0:
            strcat(sql, sourcesSchema());
            break;
        case 1:
            strcat(sql, packagesSchema());
            break;
        case 2:
            strcat(sql, updatesSchema());
            break;
    }
    
    sqlite3_exec(database, sql, NULL, 0, NULL);
    if (table == 1) {
        char *packageIndex = "CREATE INDEX IF NOT EXISTS tag_PACKAGEVERSION ON PACKAGES (PACKAGE, VERSION);";
        sqlite3_exec(database, packageIndex, NULL, 0, NULL);
    } else if (table == 2) {
        char *updateIndex = "CREATE INDEX IF NOT EXISTS tag_PACKAGE ON UPDATES (PACKAGE);";
        sqlite3_exec(database, updateIndex, NULL, 0, NULL);
    }
}

void printDatabaseError(sqlite3 *database) {
    const char *error = sqlite3_errmsg(database);
    if (strcmp(error, "not an error") && strcmp(error, "no more rows available")) {
        printf("sql error: %s\n", error);
    }
}

enum PARSEL_RETURN_TYPE addSourceToDatabase(struct ZBBaseSource source, const char *releasePath, sqlite3 *database, int sourceID, bool update) {
    FILE *file = fopen(releasePath, "r");
    if (file == NULL) {
        return PARSEL_FILENOTFOUND;
    }
    
    char line[256];
    
    createTable(database, 0);
    
    dict *sourceDict = dict_new();
    while (fgets(line, sizeof(line), file) != NULL) {
        char *info = strtok(line, "\n");
        
        multi_tok_t s = init();
        
        char *key = multi_tok(info, &s, ": ");
        char *value = multi_tok(NULL, &s, NULL);
        
        if (key == NULL || value == NULL) { // y'all suck at maintaining sources, what do you do? make the package files by hand??
            key = multi_tok(info, &s, ":");
            value = multi_tok(NULL, &s, NULL);
        }
        
        dict_add(sourceDict, key, value);
    }
    
    sqlite3_stmt *insertStatement;
    
    const char *insertQuery = update ? sourceUpdateQuery : sourceInsertQuery;
    
    if (sqlite3_prepare_v2(database, insertQuery, -1, &insertStatement, 0) == SQLITE_OK) {
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnArchiveType, source.archiveType, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnRepositoryURI, source.repositoryURI, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnDistribution, source.distribution, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnComponents, source.components, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnDescription, dict_get(sourceDict, "Description"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnOrigin, dict_get(sourceDict, "Origin"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnLabel, dict_get(sourceDict, "Label"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnVersion, dict_get(sourceDict, "Version"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnSuite, dict_get(sourceDict, "Suite"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnCodename, dict_get(sourceDict, "Codename"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnArchitectures, dict_get(sourceDict, "Architectures"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnBaseFilename, source.baseFilename, -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(insertStatement, 1 + ZBSourceColumnSourceID, sourceID);
        sqlite3_step(insertStatement);
    } else {
        printDatabaseError(database);
    }
    
    sqlite3_finalize(insertStatement);
    
    dict_free(sourceDict);
    
    fclose(file);
    return PARSEL_OK;
}

enum PARSEL_RETURN_TYPE importSourceToDatabase(struct ZBBaseSource source, const char *releasePath, sqlite3 *database, int sourceID) {
    return addSourceToDatabase(source, releasePath, database, sourceID, false);
}

enum PARSEL_RETURN_TYPE updateSourceInDatabase(struct ZBBaseSource source, const char *releasePath, sqlite3 *database, int sourceID) {
    return addSourceToDatabase(source, releasePath, database, sourceID, true);
}

enum PARSEL_RETURN_TYPE addPaymentEndpointForSource(const char *endpointURL, sqlite3 *database, int sourceID) {
    sqlite3_stmt *updateStatement;
    const char *query = "UPDATE REPOS SET (VENDOR) = (?) WHERE REPOID = ?;";
    if (sqlite3_prepare_v2(database, query, -1, &updateStatement, 0) == SQLITE_OK) {
        sqlite3_bind_text(updateStatement, 1, endpointURL, -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(updateStatement, 2, sourceID);
        if (sqlite3_step(updateStatement) != SQLITE_OK) {
            printDatabaseError(database);
        }
    }
    else {
        printDatabaseError(database);
    }
    sqlite3_finalize(updateStatement);
    
    return PARSEL_OK;
}

void createDummySource(struct ZBBaseSource source, sqlite3 *database, int sourceID) {
    createTable(database, 0);
    
    sqlite3_stmt *insertStatement;
    const char *insertQuery = sourceInsertQuery;
    if (sqlite3_prepare_v2(database, insertQuery, -1, &insertStatement, 0) == SQLITE_OK) {
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnArchiveType, source.archiveType, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnRepositoryURI, source.repositoryURI, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnDistribution, source.distribution, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnComponents, source.components, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnDescription, "No Release File Provided", -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnOrigin, source.repositoryURI, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnLabel, source.repositoryURI, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnVersion, "0.9.0", -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnSuite, "Unknown", -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnCodename, "Unknown", -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnArchitectures, "iphoneos-arm", -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBSourceColumnBaseFilename, source.baseFilename, -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(insertStatement, 1 + ZBSourceColumnSourceID, sourceID);
        sqlite3_step(insertStatement);
    } else {
        printDatabaseError(database);
    }
    
    sqlite3_finalize(insertStatement);
}

sqlite3_int64 getCurrentPackageTimestamp(sqlite3 *database, const char *packageIdentifier, const char *version, int sourceID) {
    char query[250];
    snprintf(query, sizeof(query), "SELECT LASTSEEN FROM PACKAGES_SNAPSHOT WHERE PACKAGE = \"%s\" AND VERSION = \"%s\" AND REPOID = %d LIMIT 1;", packageIdentifier, version, sourceID);
    
    sqlite3_int64 timestamp = -1;
    sqlite3_stmt *statement = NULL;
    if (sqlite3_prepare_v2(database, query, -1, &statement, NULL) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            timestamp = sqlite3_column_int64(statement, 0);
            break;
        }
    } else {
        printf("[Parsel] Error preparing current package timestamp statement: %s\n", sqlite3_errmsg(database));
    }
    sqlite3_finalize(statement);
    return timestamp;
}

pair *splitNameAndEmail(const char *author) {
    pair *p = malloc(sizeof(pair));
    
    if (author == NULL) {
        p->key = NULL;
        p->value = NULL;
    } else {
        unsigned long length = strlen(author);
        p->key = malloc(length + 1);
        
        char *l = strchr(author, '<');
        char *r = strchr(author, '>');
        
        if (l && r) {
            p->value = malloc(length + 1);
            
            int nameSize = (int)(l - author);
            int emailSize = (int)(r - author) - nameSize - 1;
            
            strncpy(p->key, author, nameSize);
            p->key[nameSize] = 0;
            
            strncpy(p->value, l + 1, emailSize);
            p->value[emailSize] = 0;
        }
        else {
            strcpy(p->key, author);
            p->value = NULL;
        }
    }
    
    return p;
}

bool bindPackage(dict **package_, int sourceID, int safeID, char *depends, sqlite3 *database, bool import, sqlite3_int64 currentDate) {
    dict *package = *package_;
    char *packageIdentifier = (char *)dict_get(package, "Package");
    for (int i = 0; packageIdentifier[i]; ++i) {
        packageIdentifier[i] = tolower(packageIdentifier[i]);
    }
    const char *tags = dict_get(package, "Tag");
    const char *status = dict_get(package, "Status");
    if (!import || (strcasestr(status, "not-installed") == NULL && strcasestr(status, "deinstall") == NULL)) {
        if (tags != NULL && strcasestr(tags, "role::cydia") != NULL) {
            sourceID = -1;
        } else if (sourceID == -1) {
            sourceID = safeID;
        }
        
        if (dict_get(package, "Name") == 0) {
            dict_add(package, "Name", packageIdentifier);
        }
        
        sqlite3_stmt *insertStatement;
        
        if (sqlite3_prepare_v2(database, packageInsertQuery, -1, &insertStatement, 0) == SQLITE_OK) {
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnPackage, packageIdentifier, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnName, dict_get(package, "Name"), -1, SQLITE_TRANSIENT);
            const char *packageVersion = dict_get(package, "Version");
            if (packageVersion == NULL) {
                dict_add(package, "Version", packageVersion = "1.0");
            }
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnVersion, packageVersion, -1, SQLITE_TRANSIENT);
            
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnTagline, dict_get(package, "Tagline"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnDescription, dict_get(package, "Description"), -1, SQLITE_TRANSIENT);
            
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnSection, dict_get(package, "Section"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnDepiction, dict_get(package, "Depiction"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnTag, tags, -1, SQLITE_TRANSIENT);
            
            pair *author = splitNameAndEmail(dict_get(package, "Author"));
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnAuthorName, author->key, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnAuthorEmail, author->value, -1, SQLITE_TRANSIENT);
            free(author->key);
            free(author->value);
            free(author);
            
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnDepends, depends[0] == '\0' ? NULL : depends, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnConflicts, dict_get(package, "Conflicts"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnProvides, dict_get(package, "Provides"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnReplaces, dict_get(package, "Replaces"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnFilename, dict_get(package, "Filename"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnIcon, dict_get(package, "Icon"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(insertStatement, 1 + ZBPackageColumnSourceID, sourceID);
            sqlite3_int64 previousTimestamp = import ? -1 : getCurrentPackageTimestamp(database, packageIdentifier, dict_get(package, "Version"), sourceID);
            sqlite3_int64 newTimestamp = 0;
            if (!import) {
                if (previousTimestamp == -1) {
                    newTimestamp = currentDate;
                } else {
                    newTimestamp = previousTimestamp;
                }
            }
            sqlite3_bind_int64(insertStatement, 1 + ZBPackageColumnLastSeen, newTimestamp);
            
            const char *installedSizeString = dict_get(package, "Installed-Size");
            if (installedSizeString != (void *)0) {
                int installedSize = atoi(installedSizeString);
                sqlite3_bind_int(insertStatement, 1 + ZBPackageColumnInstalledSize, installedSize);
            }
            else {
                sqlite3_bind_int(insertStatement, 1 + ZBPackageColumnInstalledSize, -1);
            }
            
            const char *downloadSizeString = dict_get(package, "Size");
            if (downloadSizeString != (void *)0) {
                int downloadSize = atoi(downloadSizeString);
                sqlite3_bind_int(insertStatement, 1 + ZBPackageColumnDownloadSize, downloadSize);
            }
            else {
                sqlite3_bind_int(insertStatement, 1 + ZBPackageColumnDownloadSize, -1);
            }
            
            const char *priority = dict_get(package, "Priority");
            if (priority != (void *)0) {
                sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnPriority, priority, -1, SQLITE_TRANSIENT);
            }
            
            const char *essential = dict_get(package, "Essential");
            if (essential != (void *)0) {
                sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnEssential, essential, -1, SQLITE_TRANSIENT);
            }
            
            const char *sha256 = dict_get(package, "SHA256");
            if (sha256 != (void *)0) {
                sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnSHA256, sha256, -1, SQLITE_TRANSIENT);
            }
            
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnHeader, dict_get(package, "Header"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnChangelog, dict_get(package, "Changelog"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnChangelogNotes, dict_get(package, "ChangelogNotes"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnHomepage, dict_get(package, "Homepage"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnPreviews, dict_get(package, "Previews"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnMaintainerName, dict_get(package, "Homepage"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnHomepage, dict_get(package, "Homepage"), -1, SQLITE_TRANSIENT);
            
            pair *maintainer = splitNameAndEmail(dict_get(package, "Maintainer"));
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnMaintainerName, maintainer->key, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnMaintainerEmail, maintainer->value, -1, SQLITE_TRANSIENT);
            free(maintainer->key);
            free(maintainer->value);
            free(maintainer);
            
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnPreferNative, dict_get(package, "Prefer-Native"), -1, SQLITE_TRANSIENT);
            
            if (depends[0] != '\0')
                depends[strlen(depends) - 1] = '\0';
            sqlite3_step(insertStatement);
        } else {
            printf("[Parsel] Error preparing package binding statement: %s", sqlite3_errmsg(database));
        }
        
        sqlite3_finalize(insertStatement);
        
        dict_free(*package_);
        *package_ = dict_new();
//        longDescription[0] = '\0';
        depends[0] = '\0';
    } else {
        dict_free(*package_);
        *package_ = dict_new();
//        longDescription[0] = '\0';
        depends[0] = '\0';
        return true;
    }
    return false;
}

void readMultiLineKey(FILE **file, char **buffer) {
    char line[2048];
    long int position = ftell(*file);
    
    while (fgets(line, sizeof(line), *file)) {
        strtok(line, "\n");
        strtok(line, "\r");
        
        if (isspace(line[0]) && strlen(trim(line)) != 0) { // Still contained in the multiline
            int i = 0;
            while (line[i] != '\0' && isspace(line[i])) {
                ++i;
            }
            
            if (strlen(&line[i]) + strlen(*buffer) + 1 < LONG_DESCRIPTION_MAX_LENGTH) {
                if (strlen(&line[i]) > 1 && line[i] != '.') strcat(*buffer, &line[i]);
                strcat(*buffer, "\n");
            }
            
            position = ftell(*file);
        }
        else { // Next line is another key or a newline
            if (strlen(*buffer) != 0) { // If we actually found multi-line information
                char *end = strrchr(*buffer, '\n');
                if (end != NULL) {
                    *end = '\0';
                }
            }
            
            fseek(*file, position, SEEK_SET);
            break;
        }
    }
}

enum PARSEL_RETURN_TYPE importPackagesToDatabase(const char *path, sqlite3 *database, int sourceID) {
    FILE *file = fopen(path, "r");
    if (file == NULL) {
        return PARSEL_FILENOTFOUND;
    }
    
    char line[2048];
    
    createTable(database, 1);
    sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, NULL);
    
    dict *package = dict_new();
    int safeID = sourceID;
    
    char depends[512] = "";
    
    while (fgets(line, sizeof(line), file)) {
        if (strlen(trim(line)) != 0) {
            strtok(line, "\n");
            char *info = strtok(line, "\r");
            
            multi_tok_t s = init();
            
            char *key = multi_tok(info, &s, ": ");
            char *value = multi_tok(NULL, &s, NULL);
            
            if (key == NULL || value == NULL) {
                key = multi_tok(info, &s, ":");
                value = multi_tok(NULL, &s, NULL);
            }
            
            if (key != NULL && value != NULL && (strcmp(key, "Depends") == 0 || strcmp(key, "Pre-Depends") == 0)) {
                size_t dependsLen = strlen(depends);
                if (dependsLen + strlen(value) + 2 < 512) {
                    if (dependsLen) {
                        strcat(depends, ", ");
                    }
                    strcat(depends, value);
                }
                continue;
            }
            
            if (key != NULL && (strcmp(key, "Description") == 0 || strcmp(key, "Changelog") == 0)) { // Check for a long description or changelog
                if (strcmp(key, "Description") == 0) {
                    
                    char *longDescription = malloc(sizeof(char) * LONG_DESCRIPTION_MAX_LENGTH);
                    readMultiLineKey(&file, &longDescription);
                    
                    if (longDescription[0] != '\0') {
                        dict_add(package, "Tagline", value);
                        dict_add(package, "Description", longDescription);
                    }
                    else {
                        dict_add(package, "Description", value);
                    }
                    
                    // Not sure how necessary this extra clearing of the buffer is but it seems to prevent strange behavior
                    longDescription[0] = '\0';
                    free(longDescription);
                    
                    continue;
                }
                else if (strcmp(key, "Changelog") == 0) {
                    char *changelog = malloc(sizeof(char) * LONG_DESCRIPTION_MAX_LENGTH);
                    readMultiLineKey(&file, &changelog);
                    
                    if (changelog[0] != '\0') {
                        dict_add(package, key, value);
                        dict_add(package, "ChangelogNotes", changelog);
                    }
                    
                    // Not sure how necessary this extra clearing of the buffer is but it seems to prevent strange behavior
                    changelog[0] = '\0';
                    free(changelog);
                    
                    continue;
                }
            }
            
            dict_add(package, key, value);
        } else if (dict_get(package, "Package") != 0) {
            if (bindPackage(&package, sourceID, safeID, depends, database, true, 0))
                continue;
        } else {
            dict_free(package);
            package = dict_new();
            depends[0] = '\0';
        }
    }
    if (dict_get(package, "Package") != 0) {
        bindPackage(&package, sourceID, safeID, depends, database, true, 0);
    }
    
    dict_free(package);
    
    fclose(file);
    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, NULL);
    return PARSEL_OK;
}

enum PARSEL_RETURN_TYPE updatePackagesInDatabase(const char *path, sqlite3 *database, int sourceID, sqlite3_int64 currentDate) {
    FILE *file = fopen(path, "r");
    if (file == NULL) {
        return PARSEL_FILENOTFOUND;
    }
    char line[2048];
    
    sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, NULL);
    char sql[64];
    snprintf(sql, sizeof(sql), "DELETE FROM PACKAGES WHERE REPOID = %d", sourceID);
    sqlite3_exec(database, sql, NULL, 0, NULL);
    
    dict *package = dict_new();
    int safeID = sourceID;

    char depends[512] = "";
    
    while (fgets(line, sizeof(line), file)) {
        if (strlen(trim(line)) != 0) {
            strtok(line, "\n");
            char *info = strtok(line, "\r");
            
            multi_tok_t s = init();
            
            char *key = multi_tok(info, &s, ": ");
            char *value = multi_tok(NULL, &s, NULL);
            
            if (key == NULL || value == NULL) { // y'all suck at maintaining sources, what do you do? make the package files by hand??
                key = multi_tok(info, &s, ":");
                value = multi_tok(NULL, &s, NULL);
            }
            
            if (key != NULL && value != NULL && (strcmp(key, "Depends") == 0 || strcmp(key, "Pre-Depends") == 0)) {
                size_t dependsLen = strlen(depends);
                if (dependsLen + strlen(value) + 2 < 512) {
                    if (dependsLen) {
                        strcat(depends, ", ");
                    }
                    strcat(depends, value);
                }
                continue;
            }
            
            if (key != NULL && (strcmp(key, "Description") == 0 || strcmp(key, "Changelog") == 0)) { // Check for a long description or changelog
                if (strcmp(key, "Description") == 0) {
                    
                    char *longDescription = malloc(sizeof(char) * LONG_DESCRIPTION_MAX_LENGTH);
                    readMultiLineKey(&file, &longDescription);
                    
                    if (longDescription[0] != '\0') {
                        dict_add(package, "Tagline", value);
                        dict_add(package, "Description", longDescription);
                    }
                    else {
                        dict_add(package, "Description", value);
                    }
                    
                    // Not sure how necessary this extra clearing of the buffer is but it seems to prevent strange behavior
                    longDescription[0] = '\0';
                    free(longDescription);

                    continue;
                }
                else if (strcmp(key, "Changelog") == 0) {
                    char *changelog = malloc(sizeof(char) * LONG_DESCRIPTION_MAX_LENGTH);
                    readMultiLineKey(&file, &changelog);
                    
                    if (changelog[0] != '\0') {
                        dict_add(package, key, value);
                        dict_add(package, "ChangelogNotes", changelog);
                    }
                    
                    // Not sure how necessary this extra clearing of the buffer is but it seems to prevent strange behavior
                    changelog[0] = '\0';
                    free(changelog);

                    continue;
                }
            }
            dict_add(package, key, value);
        } else if (dict_get(package, "Package") != 0) {
            bindPackage(&package, sourceID, safeID, depends, database, false, currentDate);
        } else {
            dict_free(package);
            package = dict_new();
            depends[0] = '\0';
        }
    }
    if (dict_get(package, "Package") != 0) {
        bindPackage(&package, sourceID, safeID, depends, database, false, currentDate);
    }
    
    dict_free(package);
    
    fclose(file);
    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, NULL);
    return PARSEL_OK;
}
