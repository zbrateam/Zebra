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

int isRepoSecure(const char *sourcePath, char *repoURL) {
    FILE *file = fopen(sourcePath, "r");
    if (file != NULL) {
        char line[256];
        
        char *url = strtok(repoURL, "_");
        
        while (fgets(line, sizeof(line), file) != NULL) {
            if (strcasestr(line, url) != NULL && line[8] == 's') {
                return 1;
            }
        }
    }
    return 0;
}

char *reposSchema() {
    return "REPOS(ORIGIN STRING, DESCRIPTION STRING, BASEFILENAME STRING, BASEURL STRING, SECURE INTEGER, REPOID INTEGER, DEF INTEGER, SUITE STRING, COMPONENTS STRING, ICON BLOB)";
}

const char *repoInsertQuery = "INSERT INTO REPOS(ORIGIN, DESCRIPTION, BASEFILENAME, BASEURL, SECURE, REPOID, DEF, SUITE, COMPONENTS) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?);";

char *packagesSchema() {
    return "PACKAGES(PACKAGE STRING, NAME STRING, VERSION VARCHAR(16), SHORTDESCRIPTION STRING, LONGDESCRIPTION STRING, SECTION STRING, DEPICTION STRING, TAG STRING, AUTHOR STRING, DEPENDS STRING, CONFLICTS STRING, PROVIDES STRING, REPLACES STRING, FILENAME STRING, ICONURL STRING, REPOID INTEGER, LASTSEEN TIMESTAMP)";
}

const char *packageInsertQuery = "INSERT INTO PACKAGES(PACKAGE, NAME, VERSION, SHORTDESCRIPTION, LONGDESCRIPTION, SECTION, DEPICTION, TAG, AUTHOR, DEPENDS, CONFLICTS, PROVIDES, REPLACES, FILENAME, ICONURL, REPOID, LASTSEEN) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";

char *updatesSchema() {
    return "UPDATES(PACKAGE STRING PRIMARY KEY, VERSION STRING NOT NULL, IGNORE INTEGER DEFAULT 0)";
}

char *schemaForTable(int table) {
    switch (table) {
        case 0:
            return reposSchema();
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
    char query[65];
    char *tableNames[10] = { "REPOS", "PACKAGES", "UPDATES" };
    snprintf(query, sizeof(query), "SELECT sql FROM sqlite_master WHERE name = \"%s\";", tableNames[table]);
    char *schema = NULL;
    
    sqlite3_stmt *statement;
    
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
    char sql[512] = "CREATE TABLE IF NOT EXISTS ";
    switch (table) {
        case 0:
            strcat(sql, reposSchema());
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

enum PARSEL_RETURN_TYPE importRepoToDatabaseBase(const char *sourcePath, const char *path, sqlite3 *database, int repoID, bool update) {
    FILE *file = fopen(path, "r");
    if (file == NULL) {
        return PARSEL_FILENOTFOUND;
    }
    
    char line[256];
    
    createTable(database, 0);
    
    dict *repo = dict_new();
    while (fgets(line, sizeof(line), file) != NULL) {
        char *info = strtok(line, "\n");
        
        multi_tok_t s = init();
        
        char *key = multi_tok(info, &s, ": ");
        char *value = multi_tok(NULL, &s, ": ");
        
        dict_add(repo, key, value);
    }
    
    multi_tok_t t = init();
    char *fullfilename = basename((char *)path);
    char *baseFilename = multi_tok(fullfilename, &t, "_Release");
    dict_add(repo, "BaseFileName", baseFilename);
    
    char secureURL[128];
    strcpy(secureURL, baseFilename);
    int secure = isRepoSecure(sourcePath, secureURL);
    
    replace_char(baseFilename, '_', '/');
    if (baseFilename[strlen(baseFilename) - 1] == '.') {
        baseFilename[strlen(baseFilename) - 1] = 0;
    }
    
    dict_add(repo, "BaseURL", baseFilename);
    
    int def = 0;
    if (strstr(baseFilename, "dists") != NULL) {
        def = 1;
    }
    
    sqlite3_stmt *insertStatement;
    
    const char *insertQuery = update ? "UPDATE REPOS SET (ORIGIN, DESCRIPTION, BASEFILENAME, BASEURL, SECURE, DEF, SUITE, COMPONENTS) = (?, ?, ?, ?, ?, ?, ?, ?) WHERE REPOID = ?;" : repoInsertQuery;
    
    if (sqlite3_prepare_v2(database, insertQuery, -1, &insertStatement, 0) == SQLITE_OK) {
        if (update) {
            sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnOrigin, dict_get(repo, "Origin"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnDescription, dict_get(repo, "Description"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnBaseFilename, dict_get(repo, "BaseFileName"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnBaseURL, dict_get(repo, "BaseURL"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(insertStatement, 1 + ZBRepoColumnSecure, secure);
            // repoID shift
            sqlite3_bind_int(insertStatement, ZBRepoColumnDef, def);
            sqlite3_bind_text(insertStatement, ZBRepoColumnSuite, dict_get(repo, "Suite"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, ZBRepoColumnComponents, dict_get(repo, "Components"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(insertStatement, 9, repoID);
        } else {
            sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnOrigin, dict_get(repo, "Origin"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnDescription, dict_get(repo, "Description"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnBaseFilename, dict_get(repo, "BaseFileName"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnBaseURL, dict_get(repo, "BaseURL"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(insertStatement, 1 + ZBRepoColumnSecure, secure);
            sqlite3_bind_int(insertStatement, 1 + ZBRepoColumnRepoID, repoID);
            sqlite3_bind_int(insertStatement, 1 + ZBRepoColumnDef, def);
            sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnSuite, dict_get(repo, "Suite"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnComponents, dict_get(repo, "Components"), -1, SQLITE_TRANSIENT);
        }
        sqlite3_step(insertStatement);
    } else {
        printf("sql error: %s", sqlite3_errmsg(database));
    }
    
    sqlite3_finalize(insertStatement);
    
    dict_free(repo);
    
    fclose(file);
    return PARSEL_OK;
}

enum PARSEL_RETURN_TYPE importRepoToDatabase(const char *sourcePath, const char *path, sqlite3 *database, int repoID) {
    return importRepoToDatabaseBase(sourcePath, path, database, repoID, false);
}

enum PARSEL_RETURN_TYPE updateRepoInDatabase(const char *sourcePath, const char *path, sqlite3 *database, int repoID) {
    return importRepoToDatabaseBase(sourcePath, path, database, repoID, true);
}

void createDummyRepo(const char *sourcePath, const char *path, sqlite3 *database, int repoID) {
    createTable(database, 0);
    
    dict *repo = dict_new();
    
    multi_tok_t t = init();
    char *fullfilename = basename((char *)path);
    char *baseFilename = multi_tok(fullfilename, &t, "_Packages");
    dict_add(repo, "BaseFileName", baseFilename);
    
    char secureURL[128];
    strcpy(secureURL, baseFilename);
    int secure = isRepoSecure(sourcePath, secureURL);
    
    replace_char(baseFilename, '_', '/');
    if (baseFilename[strlen(baseFilename) - 1] == '.') {
        baseFilename[strlen(baseFilename) - 1] = 0;
    }
    
    dict_add(repo, "BaseURL", baseFilename);
    dict_add(repo, "Origin", baseFilename);
    dict_add(repo, "Description", "No Description Provided");
    dict_add(repo, "Suite", "stable");
    dict_add(repo, "Components", "main");
    
    int def = 0;
    if (strstr(baseFilename, "dists") != NULL) {
        def = 1;
    }
    
    sqlite3_stmt *insertStatement;
    
    if (sqlite3_prepare_v2(database, repoInsertQuery, -1, &insertStatement, 0) == SQLITE_OK) {
        sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnOrigin, dict_get(repo, "Origin"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnDescription, dict_get(repo, "Description"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnBaseFilename, dict_get(repo, "BaseFileName"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnBaseURL, dict_get(repo, "BaseURL"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(insertStatement, 1 + ZBRepoColumnSecure, secure);
        sqlite3_bind_int(insertStatement, 1 + ZBRepoColumnRepoID, repoID);
        sqlite3_bind_int(insertStatement, 1 + ZBRepoColumnDef, def);
        sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnSuite, dict_get(repo, "Suite"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 1 + ZBRepoColumnComponents, dict_get(repo, "Components"), -1, SQLITE_TRANSIENT);
        sqlite3_step(insertStatement);
    } else {
        printf("sql error: %s", sqlite3_errmsg(database));
    }
    
    sqlite3_finalize(insertStatement);
    
    dict_free(repo);
}

sqlite3_int64 getCurrentPackageTimestamp(sqlite3 *database, const char *packageIdentifier, const char *version, int repoID) {
    char query[250];
    snprintf(query, sizeof(query), "SELECT LASTSEEN FROM PACKAGES_SNAPSHOT WHERE PACKAGE = \"%s\" AND VERSION = \"%s\" AND REPOID = %d LIMIT 1;", packageIdentifier, version, repoID);
    sqlite3_stmt *statement;
    sqlite3_int64 timestamp = 0;
    bool found = false;
    if (sqlite3_prepare_v2(database, query, -1, &statement, NULL) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            timestamp = sqlite3_column_int64(statement, 0);
            found = true;
            break;
        }
    } else {
        printf("[Parsel] Error preparing current package timestamp statement: %s\n", sqlite3_errmsg(database));
    }
    sqlite3_finalize(statement);
    return found ? timestamp : -1;
}

bool bindPackage(dict **package_, int repoID, int safeID, char *longDescription, char *depends, sqlite3 *database, bool import, sqlite3_int64 currentDate) {
    dict *package = *package_;
    char *packageIdentifier = (char *)dict_get(package, "Package");
    for (int i = 0; packageIdentifier[i]; ++i) {
        packageIdentifier[i] = tolower(packageIdentifier[i]);
    }
    const char *tags = dict_get(package, "Tag");
    const char *status = dict_get(package, "Status");
    if (!import || (strcasestr(status, "not-installed") == NULL && strcasestr(status, "deinstall") == NULL)) {
        if (tags != NULL && strcasestr(tags, "role::cydia") != NULL) {
            repoID = -1;
        } else if (repoID == -1) {
            repoID = safeID;
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
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnShortDescription, dict_get(package, "Description"), -1, SQLITE_TRANSIENT);
            if (longDescription[0] == '\0' || isspace(longDescription[0]))
                sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnLongDescription, NULL, -1, SQLITE_TRANSIENT);
            else
                sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnLongDescription, longDescription, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnSection, dict_get(package, "Section"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnDepiction, dict_get(package, "Depiction"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnTag, tags, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnAuthor, dict_get(package, "Author"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnDepends, depends[0] == '\0' ? NULL : depends, -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnConflicts, dict_get(package, "Conflicts"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnProvides, dict_get(package, "Provides"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnReplaces, dict_get(package, "Replaces"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnFilename, dict_get(package, "Filename"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(insertStatement, 1 + ZBPackageColumnIconURL, dict_get(package, "Icon"), -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(insertStatement, 1 + ZBPackageColumnRepoID, repoID);
            sqlite3_int64 previousTimestamp = import ? -1 : getCurrentPackageTimestamp(database, packageIdentifier, dict_get(package, "Version"), repoID);
            sqlite3_int64 newTimestamp = 0;
            if (!import) {
                if (previousTimestamp == -1) {
                    newTimestamp = currentDate;
                } else {
                    newTimestamp = previousTimestamp;
                }
            }
            sqlite3_bind_int64(insertStatement, 1 + ZBPackageColumnLastSeen, newTimestamp);
            if (longDescription[0] != '\0')
                longDescription[strlen(longDescription) - 1] = '\0';
            if (depends[0] != '\0')
                depends[strlen(depends) - 1] = '\0';
            sqlite3_step(insertStatement);
        } else {
            printf("[Parsel] Error preparing package binding statement: %s", sqlite3_errmsg(database));
        }
        
        sqlite3_finalize(insertStatement);
        
        dict_free(*package_);
        *package_ = dict_new();
        longDescription[0] = '\0';
        depends[0] = '\0';
    } else {
        dict_free(*package_);
        *package_ = dict_new();
        longDescription[0] = '\0';
        depends[0] = '\0';
        return true;
    }
    return false;
}

enum PARSEL_RETURN_TYPE importPackagesToDatabase(const char *path, sqlite3 *database, int repoID) {
    FILE *file = fopen(path, "r");
    if (file == NULL) {
        return PARSEL_FILENOTFOUND;
    }
    
    char line[2048];
    
    createTable(database, 1);
    sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, NULL);
    
    dict *package = dict_new();
    int safeID = repoID;
    bool longDescFlag = false;
    
    char longDescription[32768] = "";
    char depends[300] = "";
    
    while (fgets(line, sizeof(line), file)) {
        if (strlen(trim(line)) != 0) {
            if (longDescFlag && isspace(line[0])) {
                int i = 0;
                while (line[i] != '\0' && isspace(line[i])) {
                    ++i;
                }
                
                if (strlen(&line[i]) + strlen(longDescription) + 1 < 32768) {
                    strcat(longDescription, &line[i]);
                    strcat(longDescription, "\n");
                }
                
                continue;
            } else {
                longDescFlag = false;
            }
            
            char *info = strtok(line, "\n");
            info = strtok(line, "\r");
            
            multi_tok_t s = init();
            
            char *key = multi_tok(info, &s, ": ");
            char *value = multi_tok(NULL, &s, ": ");
            
            if (key == NULL || value == NULL) { // y'all suck at maintaining repos, what do you do? make the package files by hand??
                key = multi_tok(info, &s, ":");
                value = multi_tok(NULL, &s, ":");
            }
            
            if (key != NULL && value != NULL && (strcmp(key, "Depends") == 0 || strcmp(key, "Pre-Depends") == 0)) {
                size_t dependsLen = strlen(depends);
                if (dependsLen + strlen(value) + 2 < 300) {
                    if (dependsLen) {
                        strcat(depends, ", ");
                    }
                    strcat(depends, value);
                }
                continue;
            }
            
            dict_add(package, key, value);
            
            if (key != NULL && strcmp(key, "Description") == 0) { // Check for a long description
                longDescFlag = true;
            }
        } else if (dict_get(package, "Package") != 0) {
            if (bindPackage(&package, repoID, safeID, longDescription, depends, database, true, 0))
                continue;
        } else {
            dict_free(package);
            package = dict_new();
            longDescription[0] = '\0';
            depends[0] = '\0';
        }
    }
    if (dict_get(package, "Package") != 0) {
        bindPackage(&package, repoID, safeID, longDescription, depends, database, true, 0);
    }
    
    fclose(file);
    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, NULL);
    return PARSEL_OK;
}

enum PARSEL_RETURN_TYPE updatePackagesInDatabase(const char *path, sqlite3 *database, int repoID, sqlite3_int64 currentDate) {
    FILE *file = fopen(path, "r");
    if (file == NULL) {
        return PARSEL_FILENOTFOUND;
    }
    char line[2048];
    
    sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, NULL);
    char sql[64];
    snprintf(sql, sizeof(sql), "DELETE FROM PACKAGES WHERE REPOID = %d", repoID);
    sqlite3_exec(database, sql, NULL, 0, NULL);
    
    dict *package = dict_new();
    int safeID = repoID;
    bool longDescFlag = false;
    
    char longDescription[32768] = "";
    char depends[300] = "";
    
    while (fgets(line, sizeof(line), file)) {
        if (strlen(trim(line)) != 0) {
            if (longDescFlag && isspace(line[0])) {
                int i = 0;
                while (line[i] != '\0' && isspace(line[i])) {
                    ++i;
                }
                
                if (strlen(&line[i]) + strlen(longDescription) + 1 < 32768) {
                    strcat(longDescription, &line[i]);
                    strcat(longDescription, "\n");
                }
                                
                continue;
            } else {
                longDescFlag = false;
            }
            
            char *info = strtok(line, "\n");
            info = strtok(line, "\r");
            
            multi_tok_t s = init();
            
            char *key = multi_tok(info, &s, ": ");
            char *value = multi_tok(NULL, &s, ": ");
            
            if (key == NULL || value == NULL) { // y'all suck at maintaining repos, what do you do? make the package files by hand??
                key = multi_tok(info, &s, ":");
                value = multi_tok(NULL, &s, ":");
            }
            
            if (key != NULL && value != NULL && (strcmp(key, "Depends") == 0 || strcmp(key, "Pre-Depends") == 0)) {
                size_t dependsLen = strlen(depends);
                if (dependsLen + strlen(value) + 2 < 300) {
                    if (dependsLen) {
                        strcat(depends, ", ");
                    }
                    strcat(depends, value);
                }
                continue;
            }
            
            dict_add(package, key, value);
            
            if (key != NULL && strcmp(key, "Description") == 0) { // Check for a long description
                longDescFlag = true;
            }
        } else if (dict_get(package, "Package") != 0) {
            bindPackage(&package, repoID, safeID, longDescription, depends, database, false, currentDate);
        } else {
            dict_free(package);
            package = dict_new();
            longDescription[0] = '\0';
            depends[0] = '\0';
        }
    }
    if (dict_get(package, "Package") != 0) {
        bindPackage(&package, repoID, safeID, longDescription, depends, database, false, currentDate);
    }
    
    fclose(file);
    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, NULL);
    return PARSEL_OK;
}
