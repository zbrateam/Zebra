#include <unistd.h>
#include <dlfcn.h>
#include <stdio.h>
#include <sysexits.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <limits.h>
#include <string.h>

int proc_pidpath(int pid, void *buffer, uint32_t buffersize);

/* Set platform binary flag */
#define FLAG_PLATFORMIZE (1 << 1)

void patch_setuidandplatformize() {
  void *handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
  if (!handle) return;

  // Reset errors
  dlerror();

  typedef void (*fix_setuid_prt_t)(pid_t pid);
  fix_setuid_prt_t setuidptr = (fix_setuid_prt_t)dlsym(handle, "jb_oneshot_fix_setuid_now");

  typedef void (*fix_entitle_prt_t)(pid_t pid, uint32_t what);
  fix_entitle_prt_t entitleptr = (fix_entitle_prt_t)dlsym(handle, "jb_oneshot_entitle_now");

  setuidptr(getpid());

  setuid(0);

  const char *dlsym_error = dlerror();
  if (dlsym_error) {
    return;
  }

  entitleptr(getpid(), FLAG_PLATFORMIZE);
}

int main(int argc, char ** argv) {
  patch_setuidandplatformize();

  struct stat template;
  if (lstat("/Applications/Zebra.app/Zebra", &template) == -1) {
    printf("THE TRUE AND NEO CHAOS!\n");
    fflush(stdout);
    return EX_NOPERM;
  }
  else {
    pid_t pid = getppid();

    char buffer[PATH_MAX];
    int ret = proc_pidpath(pid, buffer, sizeof(buffer)); 

    struct stat response;
    stat(buffer, &response);

    if (ret < 1 || (template.st_dev != response.st_dev || template.st_ino != response.st_ino)) {
      printf("CHAOS, CHAOS!\n");
      fflush(stdout);
      return EX_NOPERM;
    }
    else {
      setuid(0);
      setgid(0);

      if (getuid() != 0 || getgid() != 0) {
        printf("WHO KEEPS SPINNING THE WORLD AROUND?\n");
        fflush(stdout);
        return EX_NOPERM;
      }

      int result = execvp(argv[1], &argv[1]);

      return result;
    }
  }
}