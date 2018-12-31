//
//  Parsel.c
//  Zebra
//
//  Created by Wilson Styres on 11/30/18.
//  Copyright © 2018 Wilson Styres. All rights reserved.
//

#include "Parsel.h"

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

int isRepoSecure(char *repoURL) {
    FILE *file = fopen("/var/lib/zebra/sources.list", "r");
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

void importRepoToDatabase(const char *path, sqlite3 *database, int repoID) {
    FILE *file = fopen(path, "r");
    char line[256];
    
    char *sql = "CREATE TABLE IF NOT EXISTS REPOS(ORIGIN STRING, DESCRIPTION STRING, BASEFILENAME STRING, BASEURL STRING, SECURE INTEGER, REPOID INTEGER);";
    sqlite3_exec(database, sql, NULL, 0, NULL);
    
    char repo[4][256];
    while (fgets(line, sizeof(line), file) != NULL) {
        char *info = strtok(line, "\n");
        
        multi_tok_t s = init();
        
        char *key = multi_tok(info, &s, ": ");
        
        if (strcmp(key, "Origin") == 0) {
            char *value = multi_tok(NULL, &s, ": ");
            strcpy(repo[0], value);
        }
        else if (strcmp(key, "Description") == 0) {
            char *value = multi_tok(NULL, &s, ": ");
            strcpy(repo[1], value);
        }
    }
    
    multi_tok_t t = init();
    char *fullfilename = basename((char *)path);
    char *baseFilename = multi_tok(fullfilename, &t, "_Release");
    strcpy(repo[2], baseFilename);
    int secure = isRepoSecure( baseFilename);
    
//    if (strstr(baseFilename, "_dists_") != NULL) {
//        multi_tok_t u = init();
//        char *baseURL = multi_tok(baseFilename, &u, "_dists");
//
//        replace_char(baseURL, '_', '/');
//
//        strcpy(repo[3], baseURL);
//    }
//    else {
        //char *baseURL = strtok(baseFilename, "_");
        
        replace_char(baseFilename, '_', '/');
        
        strcpy(repo[3], baseFilename);
//    }
    
    char insertStatement[2048];
#warning should be using sqlite_bind
    sprintf(insertStatement, "INSERT INTO REPOS(ORIGIN, DESCRIPTION, BASEFILENAME, BASEURL, SECURE, REPOID) VALUES('%s', '%s', '%s', '%s', %d, %d);", repo[0], repo[1], repo[2], repo[3], secure, repoID);
    
    repo[0][0] = 0;
    repo[1][0] = 0;
    repo[2][0] = 0;
    repo[3][0] = 0;
    sqlite3_exec(database, insertStatement, NULL, 0, NULL);
    
    fclose(file);
}

void importPackagesToDatabase(const char *path, sqlite3 *database, int repoID) {
    FILE *file = fopen(path, "r");
    char line[256];
    
    char *sql = "CREATE TABLE IF NOT EXISTS PACKAGES(PACKAGE STRING, NAME STRING, REPOID INTEGER);";//, VERSION STRING, DESCRIPTION STRING, SECTION STRING, DEPICTION STRING);";
    sqlite3_exec(database, sql, NULL, 0, NULL);
    sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, NULL);
    
    char package[2][256];
    while (fgets(line, sizeof(line), file)) {
        if (strcmp(line, "\n") != 0) {
            char *info = strtok(line, "\n");

            multi_tok_t s = init();
            
            char *key = multi_tok(info, &s, ": ");
            
            if (strcmp(key, "Package") == 0) {
                char *value = multi_tok(NULL, &s, ": ");
                strcpy(package[0], value);
                
            }
            else if (strcmp(key, "Name") == 0) {
                char *value = multi_tok(NULL, &s, ": ");
                strcpy(package[1], value);
            }
//            else if (strcmp(key, "Version") == 0) {
//                char *value = multi_tok(NULL, &s, ": ");
//                strcpy(package[2], value);
//            }
//            else if (strcmp(key, "Description") == 0) {
//                char *value = multi_tok(NULL, &s, ": ");
//                strcpy(package[3], value);
//            }
//            else if (strcmp(key, "Section") == 0) {
//                char *value = multi_tok(NULL, &s, ": ");
//                strcpy(package[4], value);
//            }
//            else if (strcmp(key, "Depiction") == 0) {
//                char *value = multi_tok(NULL, &s, ": ");
//                strcpy(package[5], value);
//            }
            
        }
        else {
            char insertStatement[1024];
            
            if (strcasestr(package[0], "saffron-jailbreak") == NULL && strcasestr(package[0], "gsc") == NULL && strcasestr(package[0], "cy+") == NULL) {
                if (package[1][0] == 0) {
                    strcpy(package[1], package[0]);
                }
                
                #warning should be using sqlite_bind
                sprintf(insertStatement, "INSERT INTO PACKAGES(PACKAGE, NAME, REPOID) VALUES('%s', '%s', %d);", package[0], package[1], repoID);
                
                package[0][0] = 0;
                package[1][0] = 0;
                
                sqlite3_exec(database, insertStatement, NULL, 0, NULL);
            }
            else {
                continue;
            }
        }
    }
    
    fclose(file);
    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, NULL);
}
