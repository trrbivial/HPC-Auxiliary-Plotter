#include <inttypes.h>
#include <stdio.h>
#include <sys/time.h>
#include <unistd.h>

static int64_t rdtsc(void) {
  unsigned int i, j;
  asm volatile(" rdtsc" : "=a"(i), "=d"(j) :);
  return ((int64_t)j << 32) + (int64_t)i;
}
int main() {
  int64_t tsc_start, tsc_end;
  struct timeval tv_start, tv_end;
  int usec_delay;

  tsc_start = rdtsc();
  gettimeofday(&tv_start, NULL);
  usleep(100000);
  tsc_end = rdtsc();
  gettimeofday(&tv_end, NULL);

  usec_delay = 1000000 * (tv_end.tv_sec - tv_start.tv_sec) +
               (tv_end.tv_usec - tv_start.tv_usec);

  printf(" cpu MHz\t\t: %.3f\n", (double)(tsc_end - tsc_start) / usec_delay);
}

