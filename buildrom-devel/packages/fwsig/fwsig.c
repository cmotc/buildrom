#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <sys/stat.h>

#define FIRMWARE_SIG_OFFSET 0xffc0
#define FIRMWARE_SIG_SIZE   16

void usage(void) {
  printf("usage: <file> [sig]\n");
  printf("- Read or write the firmware signature of the file.\n");
  printf("- if no signature is provided, then read it from the file.\n");
  printf("- otherwise, write it into the file.\n");
}

int openfile(const char *filename, int flags) {

  int fd = open(filename, O_RDONLY);
  struct stat s;

  if (fd == -1) {
    printf("Couldn't open %s for reading.\n", filename);    
    return -1;
  }

  if (fstat(fd, &s)) {
    printf("Couldn't stat %s\n", filename);
    goto error;
  }

  if (s.st_size < (FIRMWARE_SIG_OFFSET + FIRMWARE_SIG_SIZE)) {
    printf("Oops - %s is too small for this operation.\n", filename);
    goto error;
  }
  
  return fd;

 error:
  close(fd);
  return -1;
}

int read_sig(const char *filename) {

  int ret;
  int fd = openfile(filename, O_RDONLY);
  char sig[FIRMWARE_SIG_SIZE + 1];

  if (fd == -1)
    return -1;

  ret = lseek(fd, FIRMWARE_SIG_OFFSET, SEEK_SET);

  if (ret == -1) {
    printf("Couldn't seek to %d in %s\n", FIRMWARE_SIG_OFFSET, filename);
    goto error;
  }

  memset(sig, 0, FIRMWARE_SIG_SIZE + 1);
  ret = read(fd, sig, FIRMWARE_SIG_SIZE);

  if (ret == 0) 
    printf("%s: \"%16s\"\n", filename, sig);
  else
    printf("Error while reading the signature.\n");

 error:
  close(fd);
  return ret;
}

int write_sig(const char *filename, const char *sig) {

  int ret;
  char temp[FIRMWARE_SIG_SIZE + 1];
  int fd = openfile(filename, O_RDONLY);
  int i;

  if (fd == -1)
    return -1;

  ret = lseek(fd, FIRMWARE_SIG_OFFSET, SEEK_SET);

  if (ret == -1) {
    printf("Couldn't seek to %d in %s\n", FIRMWARE_SIG_OFFSET, filename);
    goto error;
  }

  strncpy(temp, sig, FIRMWARE_SIG_SIZE);

  if (strlen(sig) < FIRMWARE_SIG_SIZE) {
    printf("*** WARNING - the firmware signature is less then %d bytes.\n", FIRMWARE_SIG_SIZE);
    printf("              It will be padded - this may not have the inteded effect you want.\n");


    for(i = strlen(sig); i < FIRMWARE_SIG_SIZE; i++)
      temp[i] = ' ';

    temp[i] = 0;
  }
  else if (strlen(sig) > FIRMWARE_SIG_SIZE) {
    printf("*** WARNING - the firmware signature is less then %d bytes.\n", FIRMWARE_SIG_SIZE);
    printf("              It will be truncated - this may not have the inteded effect you want.\n");
    temp[FIRMWARE_SIG_SIZE] = 0;
  }
  
  ret = write(fd, sig, FIRMWARE_SIG_SIZE);

  if (ret)
    printf("Error while writing the signature.\n");

 error:
  close(fd);
  return ret;
}
  
int main(int argc, char **argv) {

  int ret = 1;

  if (argc < 2) 
    usage();
  else if (argc == 2) 
    ret = read_sig(argv[1]);
  else 
    ret = write_sig(argv[1], argv[2]);
  
  return ret;
}

  
