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

dict *dict_new() {
    dict *dictionary = malloc(sizeof(dict));
    assert(dictionary != NULL);
    dictionary->head = NULL;
    dictionary->next = NULL;
    return dictionary;
}

void dict_add(dict *dictionary, const char *key, const char *value) {
    if (value != NULL) {
        dict *start = dictionary;
        dict *last = NULL;
        while (dictionary->head != NULL) {
            if (dictionary->head->key != NULL && strcmp(key, dictionary->head->key) == 0) {
                if (dictionary->head->value)
                    free(dictionary->head->value);
                dictionary->head->value = malloc((strlen(value) + 1) * sizeof(char));
                assert(dictionary->head->value != NULL);
                strcpy(dictionary->head->value, value);
                return;
            }
            if (dictionary->next == NULL) {
                last = dictionary;
                break;
            }
            dictionary = dictionary->next;
        }
        dict *next = start;
        if (last != NULL) {
            next = dict_new();
            last->next = next;
        }
        next->head = malloc(sizeof(pair));
        assert(next->head != NULL);
        next->head->key = malloc((strlen(key) + 1) * sizeof(char));
        assert(next->head->key != NULL);
        strcpy(next->head->key, key);
        next->head->value = malloc((strlen(value) + 1) * sizeof(char));
        assert(next->head->value != NULL);
        strcpy(next->head->value, value);
    }
}

int dict_has(dict *dictionary, const char *key) {
    if (dictionary->head == NULL)
        return 0;
    while (dictionary != NULL) {
        if (strcmp(dictionary->head->key, key) == 0)
            return 1;
        dictionary = dictionary->next;
    }
    return 0;
}

const char *dict_get(dict *dictionary, const char *key) {
    if (dictionary->head == NULL)
        return 0;
    while (dictionary != NULL) {
        if (strcmp(dictionary->head->key, key) == 0)
            return dictionary->head->value;
        dictionary = dictionary->next;
    }
    return 0;
}

void dict_remove(dict *dictionary, const char *key) {
    if (dictionary->head == NULL)
        return;
    dict *previous = NULL;
    while (dictionary != NULL) {
        if (strcmp(dictionary->head->key, key) == 0) {
            if (previous == NULL) {
                free(dictionary->head->key);
                dictionary->head->key = NULL;
                if (dictionary->next != NULL) {
                    dict *toremove = dictionary->next;
                    dictionary->head->key = toremove->head->key;
                    dictionary->next = toremove->next;
                    free(toremove->head->key);
                    free(toremove->head->value);
                    free(toremove->head);
                    free(toremove->next);
                    free(toremove);
                    return;
                }
            } else {
                previous->next = dictionary->next;
            }
            free(dictionary->head->key);
            free(dictionary->head->value);
            free(dictionary->head);
            free(dictionary);
            return;
        }
        previous = dictionary;
        dictionary = dictionary->next;
    }
}

void dict_free(dict *dictionary) {
    if (dictionary == NULL)
        return;
    
    if (dictionary->head == NULL) {
        dict *next = dictionary->next;
        free(dictionary);
        dict_free(next);
        return;
    }
    
    free(dictionary->head->key);
    free(dictionary->head->value);
    free(dictionary->head);
    dict *next = dictionary->next;
    free(dictionary);
    dict_free(next);
}
