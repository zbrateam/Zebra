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

void importRepoToDatabase(const char *path, sqlite3 *database, int repoID) {
    FILE *file = fopen(path, "r");
    char line[256];
    
    char *sql = "CREATE TABLE IF NOT EXISTS REPOS(ORIGIN STRING, DESCRIPTION STRING, REPOID INTEGER);";
    sqlite3_exec(database, sql, NULL, 0, NULL);
    
    char repo[2][256];
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
    
    char insertStatement[1024];
#warning should be using sqlite_bind
    sprintf(insertStatement, "INSERT INTO REPOS(ORIGIN, DESCRIPTION, REPOID) VALUES('%s', '%s', %d);", repo[0], repo[1], repoID);
    
    repo[0][0] = 0;
    repo[1][0] = 0;
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
            
#warning should be using sqlite_bind
            sprintf(insertStatement, "INSERT INTO PACKAGES(PACKAGE, NAME, REPOID) VALUES('%s', '%s', %d);", package[0], package[1], repoID);

            package[0][0] = 0;
            package[1][0] = 0;
            sqlite3_exec(database, insertStatement, NULL, 0, NULL);
        }
    }
    
    fclose(file);
    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, NULL);
    sqlite3_close(database);
}
