//
//  dict.c
//  Zebra
//
//  Created by Wilson Styres on 3/25/19.
//  Copyright © 2019 Wilson Styres. All rights reserved.
//

#include "dict.h"
#include <assert.h>
#include <string.h>
#include <stdlib.h>

dict* dict_new() {
    dict *dictionary = (dict *)malloc(sizeof(dict));
    assert(dictionary != NULL);
    dictionary->head = NULL;
    dictionary->tail = NULL;
    return dictionary;
}

void dict_add(dict *dictionary, const char *key, const char *value) {
    if (value != NULL) {
        if(dict_has(dictionary, key))
            dict_remove(dictionary, key);
        if (dictionary->head != NULL) {
            while(dictionary->tail != NULL) {
                dictionary = dictionary->tail;
            }
            dict *next = dict_new();
            dictionary->tail = next;
            dictionary = dictionary->tail;
        }
        int key_length = (int)strlen(key) + 1;
        int value_length = (int)strlen(value) + 1;
        dictionary->head = (pair *)malloc(sizeof(pair));
        assert(dictionary->head != NULL);
        dictionary->head->key = (char *)malloc(key_length * sizeof(char));
        dictionary->head->value = (char *)malloc(value_length * sizeof(char));
        assert(dictionary->head->key != NULL);
        strcpy(dictionary->head->key, key);
        assert(dictionary->head->value != NULL);
        strcpy(dictionary->head->value, value);
    }
}

int dict_has(dict *dictionary, const char *key) {
    if (dictionary->head == NULL)
        return 0;
    while(dictionary != NULL) {
        if(strcmp(dictionary->head->key, key) == 0)
            return 1;
        dictionary = dictionary->tail;
    }
    return 0;
}

const char *dict_get(dict *dictionary, const char *key) {
    if (dictionary->head == NULL)
        return 0;
    while(dictionary != NULL) {
        if(strcmp(dictionary->head->key, key) == 0)
            return dictionary->head->value;
        dictionary = dictionary->tail;
    }
    return 0;
}

void dict_remove(dict *dictionary, const char *key) {
    if (dictionary->head == NULL)
        return;
    dict *previous = NULL;
    while(dictionary != NULL) {
        if(strcmp(dictionary->head->key, key) == 0) {
            if(previous == NULL) {
                free(dictionary->head->key);
                dictionary->head->key = NULL;
                if (dictionary->tail != NULL) {
                    dict *toremove = dictionary->tail;
                    dictionary->head->key = toremove->head->key;
                    dictionary->tail = toremove->tail;
                    free(toremove->head);
                    free(toremove);
                    return;
                }
            }
            else {
                previous->tail = dictionary->tail;
            }
            free(dictionary->head->key);
            free(dictionary->head);
            free(dictionary);
            return;
        }
        previous = dictionary;
        dictionary = dictionary->tail;
    }
}

void dict_free(dict *dictionary) {
    if(dictionary == NULL)
        return;
    
    if (dictionary->head == NULL) {
        dict *tail = dictionary->tail;
        free(dictionary);
        dict_free(tail);
        return;
    }
    
    free(dictionary->head->key);
    free(dictionary->head);
    dict *tail = dictionary->tail;
    free(dictionary);
    dict_free(tail);
}
