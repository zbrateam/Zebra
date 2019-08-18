//Modified version of https://github.com/Debian/apt/blob/master/apt-pkg/deb/debversion.cc to fit in C instead of C++

#include <string.h>
#include <ctype.h>
#include "vercmp.h"

static int order(char c) {
    if (isdigit(c))
        return 0;
    if (isalpha(c))
        return c;
    if (c == '~')
        return -1;
    if (c)
        return c + 256;
    return 0;
}

int compareFragment(const char *A, const char *AEnd, const char *B, const char *BEnd) {
    /* Iterate over the whole string
     What this does is to split the whole string into groups of
     numeric and non numeric portions. For instance:
     a67bhgs89
     Has 4 portions 'a', '67', 'bhgs', '89'. A more normal:
     2.7.2-linux-1
     Has '2', '.', '7', '.' ,'-linux-','1' */
    const char *lhs = A;
    const char *rhs = B;
    while (lhs != AEnd && rhs != BEnd) {
        int first_diff = 0;
        
        while (lhs != AEnd && rhs != BEnd && (!isdigit(*lhs) || !isdigit(*rhs))) {
            int vc = order(*lhs);
            int rc = order(*rhs);
            if (vc != rc)
                return vc - rc;
            ++lhs; ++rhs;
        }
        
        while (*lhs == '0')
            ++lhs;
        while (*rhs == '0')
            ++rhs;
        while (isdigit(*lhs) && isdigit(*rhs)) {
            if (!first_diff)
                first_diff = *lhs - *rhs;
            ++lhs;
            ++rhs;
        }
        
        if (isdigit(*lhs))
            return 1;
        if (isdigit(*rhs))
            return -1;
        if (first_diff)
            return first_diff;
    }
    
    // The strings must be equal
    if (lhs == AEnd && rhs == BEnd)
        return 0;
    
    // lhs is shorter
    if (lhs == AEnd || strcmp(lhs, "") == 0) {
        if (*rhs == '~') return 1;
        return -1;
    }
    
    // rhs is shorter
    if (rhs == BEnd || strcmp(rhs, "") == 0) {
        if (*lhs == '~') return -1;
        return 1;
    }
    
    // Shouldn't happen
    return 1;
}

int compareVersion(const char *A, const char *AEnd, const char *B, const char *BEnd) {
    // Strip off the epoch and compare it
    const char *lhs = (const char*) memchr(A, ':', AEnd - A);
    const char *rhs = (const char*) memchr(B, ':', BEnd - B);
    if (lhs == NULL)
        lhs = A;
    if (rhs == NULL)
        rhs = B;
    
    // Special case: a zero epoch is the same as no epoch,
    // so remove it.
    if (lhs != A) {
        for (; *A == '0'; ++A);
        if (A == lhs) {
            ++A;
            ++lhs;
        }
    }
    if (rhs != B) {
        for (; *B == '0'; ++B);
        if (B == rhs) {
            ++B;
            ++rhs;
        }
    }
    
    // Compare the epoch
    int Res = compareFragment(A, lhs, B, rhs);
    if (Res != 0)
        return Res;
    
    // Skip the :
    if (lhs != A)
        lhs++;
    if (rhs != B)
        rhs++;
    
    // Find the last -
    const char *dlhs = (const char*) strrchr(lhs, '-');
    const char *drhs = (const char*) strrchr(rhs, '-');
    if (dlhs == NULL)
        dlhs = AEnd;
    if (drhs == NULL)
        drhs = BEnd;
    
    // Compare the main version
    Res = compareFragment(lhs, dlhs, rhs, drhs);
    if (Res != 0)
        return Res;
    
    // Skip the -
    if (dlhs != lhs)
        dlhs++;
    if (drhs != rhs)
        drhs++;
    
    // no debian revision need to be treated like -0
    if (*(dlhs-1) == '-' && *(drhs-1) == '-')
        return compareFragment(dlhs, AEnd, drhs, BEnd);
    if (*(dlhs-1) == '-') {
        const char* null = "0";
        return compareFragment(dlhs, AEnd, null, null + 1);
    }
    if (*(drhs-1) == '-') {
        const char* null = "0";
        return compareFragment(null, null + 1, drhs, BEnd);
    }
    return 0;
}

int compare(const char *A, const char *B) {
    const char* AEnd = &A[strlen(A)];
    const char* BEnd = &B[strlen(B)];
    return compareVersion(A, AEnd, B, BEnd);
}
