//
//  dict.h
//  Zebra
//
//  Created by Wilson Styres on 3/25/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#ifndef dictionary_h
#define dictionary_h

#include <stdio.h>

typedef struct {
    char *key;
    char *value;
} pair;

typedef struct dict_t {
    pair *head;
    struct dict_t *next;
} dict;

dict* dict_new(void);
void dict_add(dict *dictionary, const char *key, const char *value);
int dict_has(dict *dictionary, const char *key);
const char *dict_get(dict *dictionary, const char *key);
void dict_remove(dict *dictionary, const char *key);
void dict_free(dict *dictionary);

#endif /* dictionary_h */
