#include <unistd.h>
#include <dlfcn.h>
#include <stdio.h>
#include <sysexits.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <launch.h>
#include <limits.h>
#include <string.h>

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

void validator(launch_data_t value, const char *key, void *ctx) {
  launch_data_t jobPID = launch_data_dict_lookup(value, LAUNCH_JOBKEY_PID);
  if (jobPID == NULL || launch_data_get_type(jobPID) != LAUNCH_DATA_INTEGER) return;
  
  pid_t parentProcessID = getppid(); //Get parent process ID
  long long launchDataPID = launch_data_get_integer(jobPID); //Get the process ID from the launch data
  if (parentProcessID != launchDataPID) return; //Filter to exclude process IDs that are not equal to our parent's

  launch_data_t program = launch_data_dict_lookup(value, LAUNCH_JOBKEY_PROGRAM); //Lookup our program
  if (program == NULL || launch_data_get_type(program) != LAUNCH_DATA_STRING) { //If we can't find it, use the program arguemnts to find the executable path
    launch_data_t array = launch_data_dict_lookup(value, LAUNCH_JOBKEY_PROGRAMARGUMENTS);
    if (array == NULL || launch_data_get_type(array) != LAUNCH_DATA_ARRAY || launch_data_array_get_count(array) == 0) return;

    program = launch_data_array_get_index(array, 0); //First member of the array is our executable path
    if (program == NULL || launch_data_get_type(program) != LAUNCH_DATA_STRING) return;
  }

  const char *executablePath = launch_data_get_string(program); //Get our executable path from the launch data
  if (executablePath == NULL) return;

  struct stat *check = ctx;
  lstat(executablePath, check); //Call stat on the executable path
}

int main(int argc, char **argv) {
  struct stat template;
  if (lstat("/Applications/Zebra.app/Zebra", &template) == -1) {
    printf("THE TRUE AND NEO CHAOS!\n");
    fflush(stdout);
    return EX_NOPERM;
  }

  //Get all jobs from launchd
  launch_data_t request = launch_data_new_string(LAUNCH_KEY_GETJOBS);
  launch_data_t message = launch_msg(request);
  launch_data_free(request);

  //If our response is no good, there is no reason to continue
  if (message != NULL && launch_data_get_type(message) == LAUNCH_DATA_DICTIONARY) {
    struct stat response;
    launch_data_dict_iterate(message, validator, &response); //Check to see if this root request is sent from a valid Zebra binary
    if (template.st_dev == response.st_dev && template.st_ino == response.st_ino) { //If it is, go ahead and setuid
      patch_setuidandplatformize(); //Patch setuid

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
    else {
      printf("CHAOS, CHAOS!\n");
      return EX_NOPERM;
    }
  }

  return EX_NOPERM;
}