//
//  parsel.c
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#include "parsel.h"
#include "dict.h"

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

char* replace_char(char* str, char find, char replace){
    char *current_pos = strchr(str,find);
    while (current_pos){
        *current_pos = replace;
        current_pos = strchr(current_pos,find);
    }
    return str;
}

int isRepoSecure(const char* sourcePath, char *repoURL) {
    FILE *file = fopen(sourcePath, "r");
    if (file != NULL) {
        char line[256];
        
        char *url = strtok(repoURL, "_");
        
        while (fgets(line, sizeof(line), file) != NULL) {
            if (strcasestr(line, url) != NULL && line[8] == 's') {
                return 1;
            }
        }
        
        return 0;
    }
    else {
        return 0;
    }
}

enum PARSEL_RETURN_TYPE importRepoToDatabase(const char *sourcePath, const char *path, sqlite3 *database, int repoID) {
    FILE *file = fopen(path, "r");
    if (file == NULL) {
        return PARSEL_FILENOTFOUND;
    }
    
    char line[256];
    
    char *sql = "CREATE TABLE IF NOT EXISTS REPOS(ORIGIN STRING, DESCRIPTION STRING, BASEFILENAME STRING, BASEURL STRING, SECURE INTEGER, REPOID INTEGER, DEF INTEGER, SUITE STRING, COMPONENTS STRING, ICON BLOB);";
    sqlite3_exec(database, sql, NULL, 0, NULL);
    
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
    if(strstr(baseFilename, "dists") != NULL) {
        def = 1;
    }
    
    sqlite3_stmt *insertStatement;
    char *insertQuery = "INSERT INTO REPOS(ORIGIN, DESCRIPTION, BASEFILENAME, BASEURL, SECURE, REPOID, DEF, SUITE, COMPONENTS) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?);";
    
    if (sqlite3_prepare_v2(database, insertQuery, -1, &insertStatement, 0) == SQLITE_OK) {
        sqlite3_bind_text(insertStatement, 1, dict_get(repo, "Origin"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, dict_get(repo, "Description"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 3, dict_get(repo, "BaseFileName"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 4, dict_get(repo, "BaseURL"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(insertStatement, 5, secure);
        sqlite3_bind_int(insertStatement, 6, repoID);
        sqlite3_bind_int(insertStatement, 7, def);
        sqlite3_bind_text(insertStatement, 8, dict_get(repo, "Suite"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 9, dict_get(repo, "Components"), -1, SQLITE_TRANSIENT);
        sqlite3_step(insertStatement);
    }
    else {
        printf("sql error: %s", sqlite3_errmsg(database));
    }
    
    sqlite3_finalize(insertStatement);
    
    dict_free(repo);
    
    fclose(file);
    return PARSEL_OK;
}

enum PARSEL_RETURN_TYPE updateRepoInDatabase(const char *sourcePath, const char *path, sqlite3 *database, int repoID) {
    FILE *file = fopen(path, "r");
    if (file == NULL) {
        return PARSEL_FILENOTFOUND;
    }
    
    char line[256];
    
    char *sql = "CREATE TABLE IF NOT EXISTS REPOS(ORIGIN STRING, DESCRIPTION STRING, BASEFILENAME STRING, BASEURL STRING, SECURE INTEGER, REPOID INTEGER, DEF INTEGER, SUITE STRING, COMPONENTS STRING, ICON BLOB);";
    sqlite3_exec(database, sql, NULL, 0, NULL);
    
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
    if(strstr(baseFilename, "dists") != NULL) {
        def = 1;
    }
    
    sqlite3_stmt *insertStatement;
    char *insertQuery = "UPDATE REPOS SET (ORIGIN, DESCRIPTION, BASEFILENAME, BASEURL, SECURE, DEF, SUITE, COMPONENTS) = (?, ?, ?, ?, ?, ?, ?, ?) WHERE REPOID = ?;";
    
    if (sqlite3_prepare_v2(database, insertQuery, -1, &insertStatement, 0) == SQLITE_OK) {
        sqlite3_bind_text(insertStatement, 1, dict_get(repo, "Origin"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, dict_get(repo, "Description"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 3, dict_get(repo, "BaseFileName"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 4, dict_get(repo, "BaseURL"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(insertStatement, 5, secure);
        sqlite3_bind_int(insertStatement, 6, def);
        sqlite3_bind_text(insertStatement, 7, dict_get(repo, "Suite"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 8, dict_get(repo, "Components"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(insertStatement, 9, repoID);
        sqlite3_step(insertStatement);
    }
    else {
        printf("sql error: %s", sqlite3_errmsg(database));
    }
    
    sqlite3_finalize(insertStatement);
    
    dict_free(repo);
    
    fclose(file);
    return PARSEL_OK;
}

void createDummyRepo (const char *sourcePath, const char *path, sqlite3 *database, int repoID) {
    char *sql = "CREATE TABLE IF NOT EXISTS REPOS(ORIGIN STRING, DESCRIPTION STRING, BASEFILENAME STRING, BASEURL STRING, SECURE INTEGER, REPOID INTEGER, DEF INTEGER, SUITE STRING, COMPONENTS STRING, ICON BLOB);";
    sqlite3_exec(database, sql, NULL, 0, NULL);
    
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
    if(strstr(baseFilename, "dists") != NULL) {
        def = 1;
    }
    
    sqlite3_stmt *insertStatement;
    char *insertQuery = "INSERT INTO REPOS(ORIGIN, DESCRIPTION, BASEFILENAME, BASEURL, SECURE, REPOID, DEF, SUITE, COMPONENTS) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?);";
    
    if (sqlite3_prepare_v2(database, insertQuery, -1, &insertStatement, 0) == SQLITE_OK) {
        sqlite3_bind_text(insertStatement, 1, dict_get(repo, "Origin"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, dict_get(repo, "Description"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 3, dict_get(repo, "BaseFileName"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 4, dict_get(repo, "BaseURL"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(insertStatement, 5, secure);
        sqlite3_bind_int(insertStatement, 6, repoID);
        sqlite3_bind_int(insertStatement, 7, def);
        sqlite3_bind_text(insertStatement, 8, dict_get(repo, "Suite"), -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 9, dict_get(repo, "Components"), -1, SQLITE_TRANSIENT);
        sqlite3_step(insertStatement);
    }
    else {
        printf("sql error: %s", sqlite3_errmsg(database));
    }
    
    sqlite3_finalize(insertStatement);
    
    dict_free(repo);
}

enum PARSEL_RETURN_TYPE importPackagesToDatabase(const char *path, sqlite3 *database, int repoID) {
    FILE *file = fopen(path, "r");
    if (file == NULL) {
        return PARSEL_FILENOTFOUND;
    }
    
    char line[256];
    
    char *sql = "CREATE TABLE IF NOT EXISTS PACKAGES(PACKAGE STRING, NAME STRING, VERSION STRING, DESC STRING, SECTION STRING, DEPICTION STRING, TAG STRING, DEPENDS STRING, CONFLICTS STRING, AUTHOR STRING, PROVIDES STRING, FILENAME STRING, REPOID INTEGER);";
    sqlite3_exec(database, sql, NULL, 0, NULL);
    sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, NULL);
    
    dict *package = dict_new();
    int safeID = repoID;
    while (fgets(line, sizeof(line), file)) {
        if (strcmp(line, "\n") != 0 && strcmp(line, "") != 0) {
            char *info = strtok(line, "\n");
            info = strtok(line, "\r");
            
            multi_tok_t s = init();
            
            char *key = multi_tok(info, &s, ": ");
            char *value = multi_tok(NULL, &s, ": ");
            
            if (key == NULL || value == NULL) { //y'all suck at maintaining repos, what do you do? make the package files by hand??
                key = multi_tok(info, &s, ":");
                value = multi_tok(NULL, &s, ":");
                
                dict_add(package, key, value);
            }
            else {
                dict_add(package, key, value);
            }
        }
        else if (dict_get(package, "Package") != 0) {
            const char *packageIdentifier = dict_get(package, "Package");
            const char *tags = dict_get(package, "Tag");
            if (strcasestr(dict_get(package, "Status"), "not-installed") == NULL && strcasestr(dict_get(package, "Status"), "deinstall") == NULL) {
                if (tags != NULL && strcasestr(tags, "role::cydia") != NULL) {
                    repoID = -1;
                }
                else if (repoID == -1) {
                    repoID = safeID;
                }
                
                if (dict_get(package, "Name") == 0) {
                    dict_add(package, "Name", packageIdentifier);
                }
                
                sqlite3_stmt *insertStatement;
                char *insertQuery = "INSERT INTO PACKAGES(PACKAGE, NAME, VERSION, DESC, SECTION, DEPICTION, TAG, DEPENDS, CONFLICTS, AUTHOR, PROVIDES, FILENAME, REPOID) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";
                
                if (sqlite3_prepare_v2(database, insertQuery, -1, &insertStatement, 0) == SQLITE_OK) {
                    sqlite3_bind_text(insertStatement, 1, packageIdentifier, -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(insertStatement, 2, dict_get(package, "Name"), -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(insertStatement, 3, dict_get(package, "Version"), -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(insertStatement, 4, dict_get(package, "Description"), -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(insertStatement, 5, dict_get(package, "Section"), -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(insertStatement, 6, dict_get(package, "Depiction"), -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(insertStatement, 7, tags, -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(insertStatement, 8, dict_get(package, "Depends"), -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(insertStatement, 9, dict_get(package, "Conflicts"), -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(insertStatement, 10, dict_get(package, "Author"), -1, SQLITE_TRANSIENT);
                    sqlite3_bind_text(insertStatement, 12, dict_get(package, "Filename"), -1, SQLITE_TRANSIENT);
                    sqlite3_bind_int(insertStatement, 13, repoID);
                    sqlite3_step(insertStatement);
                }
                else {
                    printf("database error: %s", sqlite3_errmsg(database));
                }
                
                sqlite3_finalize(insertStatement);
                
                dict_free(package);
                package = dict_new();
            }
            else {
                dict_free(package);
                package = dict_new();
                continue;
            }
        }
        else {
            dict_free(package);
            package = dict_new();
            continue;
        }
    }
    
    fclose(file);
    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, NULL);
    return PARSEL_OK;
}

enum PARSEL_RETURN_TYPE updatePackagesInDatabase(const char *path, sqlite3 *database, int repoID) {
    FILE *file = fopen(path, "r");
    if (file == NULL) {
        return PARSEL_FILENOTFOUND;
    }
    char line[512];
    
    char *create = "CREATE TABLE IF NOT EXISTS PACKAGES(PACKAGE STRING, NAME STRING, VERSION STRING, DESC STRING, SECTION STRING, DEPICTION STRING, TAG STRING, DEPENDS STRING, CONFLICTS STRING, AUTHOR STRING, PROVIDES STRING, FILENAME STRING, REPOID INTEGER);";
    sqlite3_exec(database, create, NULL, 0, NULL);
    
    sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, NULL);
    char sql[64];
    sprintf(sql, "DELETE FROM PACKAGES WHERE REPOID = %d", repoID);
    sqlite3_exec(database, sql, NULL, 0, NULL);

    dict *package = dict_new();
    int safeID = repoID;
    while (fgets(line, sizeof(line), file)) {
        if (strcmp(line, "\n") != 0 && strcmp(line, "") != 0 && strcmp(line, "\r\n") != 0 && strcmp(line, "\r") != 0) {
            char *info = strtok(line, "\n");
            info = strtok(line, "\r");
            
            multi_tok_t s = init();
            
            char *key = multi_tok(info, &s, ": ");
            char *value = multi_tok(NULL, &s, ": ");
            
            if (key == NULL || value == NULL) { //y'all suck at maintaining repos, what do you do? make the package files by hand??
                key = multi_tok(info, &s, ":");
                value = multi_tok(NULL, &s, ":");
                
                dict_add(package, key, value);
            }
            else {
                dict_add(package, key, value);
            }
        }
        else if (dict_get(package, "Package") != 0) {
            const char *packageIdentifier = dict_get(package, "Package");
            const char *tags = dict_get(package, "Tag");
            if (tags != NULL && strcasestr(tags, "role::cydia") != NULL) {
                repoID = -1;
            }
            else if (repoID == -1) {
                repoID = safeID;
            }
            
            if (dict_get(package, "Name") == 0) {
                dict_add(package, "Name", packageIdentifier);
            }
            
            sqlite3_stmt *insertStatement;
            char *insertQuery = "INSERT INTO PACKAGES(PACKAGE, NAME, VERSION, DESC, SECTION, DEPICTION, TAG, DEPENDS, CONFLICTS, AUTHOR, PROVIDES, FILENAME, REPOID) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";
            
            if (sqlite3_prepare_v2(database, insertQuery, -1, &insertStatement, 0) == SQLITE_OK) {
                sqlite3_bind_text(insertStatement, 1, packageIdentifier, -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(insertStatement, 2, dict_get(package, "Name"), -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(insertStatement, 3, dict_get(package, "Version"), -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(insertStatement, 4, dict_get(package, "Description"), -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(insertStatement, 5, dict_get(package, "Section"), -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(insertStatement, 6, dict_get(package, "Depiction"), -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(insertStatement, 7, dict_get(package, "Tag"), -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(insertStatement, 8, dict_get(package, "Depends"), -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(insertStatement, 9, dict_get(package, "Conflicts"), -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(insertStatement, 10, dict_get(package, "Author"), -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(insertStatement, 11, dict_get(package, "Provides"), -1, SQLITE_TRANSIENT);
                sqlite3_bind_text(insertStatement, 12, dict_get(package, "Filename"), -1, SQLITE_TRANSIENT);
                sqlite3_bind_int(insertStatement, 13, repoID);
                sqlite3_step(insertStatement);
            }
            else {
                printf("database error: %s", sqlite3_errmsg(database));
            }
            
            sqlite3_finalize(insertStatement);
            
            dict_free(package);
            package = dict_new();
        }
        else {
            dict_free(package);
            package = dict_new();
            continue;
        }
    }
    
    fclose(file);
    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, NULL);
    return PARSEL_OK;
}
