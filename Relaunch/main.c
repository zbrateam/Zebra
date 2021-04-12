#include <time.h>
#include <spawn.h>
#include <sys/wait.h>

#include <stdlib.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <stdbool.h>
#include <string.h>
#include <errno.h>
#include <signal.h>

extern int proc_pidpath(pid_t pid, void * buffer, uint32_t  buffersize);

// returns true if the process exists
bool get_zebra_pid(pid_t *pid) {

  // get maximum number of processes
  static int maxproc;

  int mib1[2];
  size_t len;

  mib1[0] = CTL_KERN;
  mib1[1] = KERN_MAXPROC;
  len = sizeof(maxproc);
  sysctl(mib1, 2, &maxproc, &len, NULL, 0);


  struct kinfo_proc *kp = NULL;

  // get buffer size
  size_t alloc_size = maxproc * sizeof(struct kinfo_proc);
	size_t bufSize = 0;
  kp = (struct kinfo_proc *)malloc(alloc_size);
  static int mib2[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
  if (kp == NULL) {
    if (sysctl(mib2, 4, NULL, &alloc_size, NULL, 0) < 0) {
      return false;
    }
    alloc_size *= 2;
    kp = (struct kinfo_proc *)malloc(alloc_size);
  }
  bufSize = alloc_size;

	// get process list
	int ret = sysctl(mib2, 4, kp, &bufSize, NULL, 0);
	if (ret) {
    free(kp);
    kp = NULL;
    return false;
  }

  // search for Zebra process
  bool found = false;
  size_t count = bufSize / sizeof(struct kinfo_proc);
  for (int i = 0; i < count; i++) {
    pid_t _pid = kp[i].kp_proc.p_pid;
    char path[MAXPATHLEN];

    if (proc_pidpath(_pid, path, sizeof(path))) {
      if (strcmp(path, "/Applications/Zebra.app/Zebra") == 0) {
        *pid = _pid;
        found = true;
        break;
      }
    }
  }

  free(kp);
  kp = NULL;

  return found;
}

int main() {
  pid_t zebra_pid;
  if (get_zebra_pid(&zebra_pid)) {

    int milli_nanoseconds = 1000000;

    int delay_ms = 750;
    const struct timespec delay = {.tv_sec = 0, .tv_nsec = milli_nanoseconds * delay_ms};
    nanosleep(&delay, NULL);

    int interval_ms = 150;
    const struct timespec interval = {.tv_sec = 0, .tv_nsec = (milli_nanoseconds * interval_ms)};

    errno = 0;
    while (kill(zebra_pid, 0) != -1 && errno != ESRCH) {
      errno = 0;
      nanosleep(&interval, NULL);
    }
  }

  // oh no the Zebra has been poached

  // get a new one no one will notice
  pid_t pid;
  extern char **environ;

  char *argv[] = {"/usr/bin/uiopen", "zbra://home", NULL};

  posix_spawn(&pid, argv[0], NULL, NULL, argv, environ);
  waitpid(pid, NULL, 0);

  return 0;
}
