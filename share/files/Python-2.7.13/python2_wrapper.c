#define _GNU_SOURCE

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <string.h>

#define SEP ":"
#define PYTHON_HOME "{PYTHON_HOME}"
#define PYTHON_PATH "{PYTHON_PATH}"
#define PY_EXEC "{PY_EXEC}-"
#define DEF_SUFFIX "64"

int main(int argc, char **argv) {
  char *filename;
  char *suffix;

  if(!(suffix = getenv("USE_ARCH"))) {
    suffix = DEF_SUFFIX;
  }

  filename = malloc(strlen(PY_EXEC) + strlen(suffix) + 1);
  filename[0] = '\0';
  strcat(filename, PY_EXEC);
  strcat(filename, suffix);

  char * new_python_path;
  char * old_python_path = getenv("PYTHONPATH");
  if (old_python_path == NULL) {
    new_python_path = PYTHON_PATH;
  } else {
    new_python_path=malloc(strlen(old_python_path)+strlen(SEP)+strlen(PYTHON_PATH)+1);
    new_python_path[0] = '\0';
    strcat(new_python_path,old_python_path);
    strcat(new_python_path,SEP);
    strcat(new_python_path,PYTHON_PATH);
  }
  setenv("PYTHONPATH", new_python_path, 1);

  setenv("PYTHONHOME", PYTHON_HOME, 1);

  int status = EXIT_FAILURE;
  pid_t pid = fork();

  if (pid == 0) {
    execvp(filename, argv);
    perror(filename);
  } else if (pid < 0) {
    perror(argv[0]);
  } else if (waitpid(pid, &status, 0) != pid) {
    status = EXIT_FAILURE;
    perror(argv[0]);
  } else {
    status = WEXITSTATUS(status);
  }

  return status;
}
