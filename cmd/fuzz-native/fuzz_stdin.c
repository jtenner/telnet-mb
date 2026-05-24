#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <moonbit.h>

MOONBIT_FFI_EXPORT
moonbit_bytes_t moonbit_telnet_fuzz_read_stdin(int32_t max_bytes) {
  if (max_bytes <= 0) {
    return moonbit_make_bytes_raw(0);
  }

  uint8_t *buffer = (uint8_t *)malloc((size_t)max_bytes);
  if (buffer == NULL) {
    return moonbit_make_bytes_raw(0);
  }

  size_t length = 0;
  size_t capacity = (size_t)max_bytes;
  while (length < capacity) {
    size_t n = fread(buffer + length, 1, capacity - length, stdin);
    if (n > 0) {
      length += n;
      continue;
    }
    break;
  }

  moonbit_bytes_t out = moonbit_make_bytes_raw((int32_t)length);
  if (length > 0) {
    memcpy(out, buffer, length);
  }
  free(buffer);
  return out;
}
