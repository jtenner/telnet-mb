#include <stdint.h>
#include <string.h>
#include <moonbit.h>

MOONBIT_FFI_EXPORT
int32_t moonbit_telnet_find_byte(moonbit_bytes_t bytes, int32_t start, int32_t length, int32_t needle) {
  if (length <= 0) {
    return -1;
  }
  const void *found = memchr((const void *)(bytes + start), needle & 0xff, (size_t)length);
  if (found == NULL) {
    return -1;
  }
  return (int32_t)((const uint8_t *)found - (bytes + start));
}
