//
//  spawn.h
//  Zebra
//
//  Created by Adam Demasi on 17/9/2022.
//  Copyright © 2022 Zebra Team. All rights reserved.
//

#include_next <spawn.h>

// References:
// https://github.com/apple-oss-distributions/xnu/blob/e7776783b89a353188416a9a346c6cdb4928faad/libsyscall/wrappers/spawn/spawn_private.h
// https://github.com/apple-oss-distributions/xnu/blob/e7776783b89a353188416a9a346c6cdb4928faad/bsd/sys/spawn_internal.h

#define POSIX_SPAWN_PERSONA_FLAGS_NONE      0x0
#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE  0x1
#define POSIX_SPAWN_PERSONA_FLAGS_VERIFY    0x2

int posix_spawnattr_set_persona_np(const posix_spawnattr_t * __restrict, uid_t, uint32_t) __API_AVAILABLE(macos(10.11), ios(9.0));
int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t * __restrict, uid_t) __API_AVAILABLE(macos(10.11), ios(9.0));
int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t * __restrict, gid_t) __API_AVAILABLE(macos(10.11), ios(9.0));
int posix_spawnattr_set_persona_groups_np(const posix_spawnattr_t * __restrict, int, gid_t * __restrict, uid_t) __API_AVAILABLE(macos(10.11), ios(9.0));
