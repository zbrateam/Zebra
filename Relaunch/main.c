#include <time.h>
#include <spawn.h>
#include <sys/wait.h>

int main() {
  int sec = 1;
  int ms = 150;
  int nanosec = (long)1000000L * ms;

  nanosleep((const struct timespec[]){{sec, nanosec}}, NULL);


  pid_t pid;
  extern char **environ;
  
  char *argv[] = {"/usr/bin/uiopen", "zbra://home", NULL};

  posix_spawn(&pid, argv[0], NULL, NULL, argv, environ);
  waitpid(pid, NULL, 0);

  return 0;
}
