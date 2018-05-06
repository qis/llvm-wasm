#include "wasm.h"
#include <iostream>

#ifdef __wasm__
__attribute__((visibility("default")))
#endif

int main() {
  std::printf("test: %d\n", test());
}
