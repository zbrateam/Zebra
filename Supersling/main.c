#include <unistd.h>
#include <stdio.h>
#include <sysexits.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <limits.h>
#include <string.h>

#include <sys/syslog.h>

int proc_pidpath(int pid, void *buffer, uint32_t buffersize);

int main(int argc, char ** argv) {
  char appPath[PATH_MAX];
  sprintf(appPath, "/Applications/%s.app/%s", APP_NAME, APP_NAME);
  syslog(LOG_WARNING, "[Supersling] App Path: %s.", appPath);

  struct stat template;
  if (lstat(appPath, &template) == -1) {
    syslog(LOG_ERR, "[Supersling] THE TRUE AND NEO CHAOS!\n");
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
      syslog(LOG_ERR, "[Supersling] CHAOS, CHAOS!\n");
      fflush(stdout);
      return EX_NOPERM;
    }
    else {
      setuid(0);
      setgid(0);

      if (getuid() != 0 || getgid() != 0) {
        syslog(LOG_ERR, "[Supersling] WHO KEEPS SPINNING THE WORLD AROUND?\n");
        fflush(stdout);
        return EX_NOPERM;
      }

      if (argc < 2 || argv[1][0] != '/') {
        argv[0] = "/usr/bin/dpkg";
      }
      else {
        argc--;
        argv++;
      }

      syslog(LOG_WARNING, "[Supersling] su/sling called with args:");
      for (int i = 0; i < argc; i++) {
        syslog(LOG_WARNING, "[Supersling] %s", argv[i]);
      }

      int result = execvp(argv[0], argv);

      return result;
    }
  }
}