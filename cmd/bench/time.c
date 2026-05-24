#include <stdint.h>
#include <moonbit.h>

#ifdef _WIN32
#include <windows.h>

MOONBIT_FFI_EXPORT
int64_t moonbit_telnet_bench_now_us(void) {
  static LARGE_INTEGER frequency;
  static int initialized = 0;
  LARGE_INTEGER counter;
  if (!initialized) {
    QueryPerformanceFrequency(&frequency);
    initialized = 1;
  }
  QueryPerformanceCounter(&counter);
  return (int64_t)((counter.QuadPart * 1000000) / frequency.QuadPart);
}
#else
#include <time.h>

MOONBIT_FFI_EXPORT
int64_t moonbit_telnet_bench_now_us(void) {
  struct timespec ts;
#if defined(CLOCK_MONOTONIC)
  clock_gettime(CLOCK_MONOTONIC, &ts);
#else
  clock_gettime(CLOCK_REALTIME, &ts);
#endif
  return (int64_t)ts.tv_sec * 1000000 + (int64_t)ts.tv_nsec / 1000;
}
#endif
