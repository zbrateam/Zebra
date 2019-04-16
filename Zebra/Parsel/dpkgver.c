/*
 * libdpkg - Debian packaging suite library routines
 * vercmp.c - comparison of version numbers
 *
 * Copyright © 1995 Ian Jackson <ian@chiark.greenend.org.uk>
 *
 * This is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2,
 * or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with dpkg; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <string.h>
#include <ctype.h>
#include "dpkgver.h"

#define order(x) ((x) == '~' ? -1 \
: isdigit((x)) ? 0 \
: !(x) ? 0 \
: isalpha((x)) ? (x) \
: (x) + 256)

int verrevcmp(const char *val, const char *ref) {
    if (!val) val= "";
    if (!ref) ref= "";
    
    //Custom, not included in dpkg source, merely a cheap hack to deal with epochs in jailbreak packages, erica utils
    //is the only package that has an epoch that i've seen so if a version has an epoch version, it is probably greater
    //than the other ones. deer is dumb.
    if (strchr(val, ':') != NULL && strchr(ref, ':') != NULL) { //Both packages contain epochs, why? idk.
        const char *newVal = strtok((char *)val, ":");
        newVal = strtok(NULL, ":");
        
        const char *newRef = strtok((char *)ref, ":");
        newRef = strtok(NULL, ":");
        
        if (newVal != NULL && newRef != NULL) {
            return verrevcmp(newVal, newRef);
        }
    }
    else if (strchr(val, ':') != NULL) { //first version contains epoch, it is greater
        return 1;
    }
    else if (strchr(ref, ':') != NULL) { //second version contains epoch, it is greater
        return -1;
    }
    
    while (*val || *ref) {
        int first_diff= 0;
        
        while ( (*val && !isdigit(*val)) || (*ref && !isdigit(*ref)) ) {
            int vc= order(*val), rc= order(*ref);
            if (vc != rc) return vc - rc;
            val++; ref++;
        }
        
        while ( *val == '0' ) val++;
        while ( *ref == '0' ) ref++;
        while (isdigit(*val) && isdigit(*ref)) {
            if (!first_diff) first_diff= *val - *ref;
            val++; ref++;
        }
        if (isdigit(*val)) return 1;
        if (isdigit(*ref)) return -1;
        if (first_diff) return first_diff;
    }
    return 0;
}
