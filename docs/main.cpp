#include <sstream>
#include <cstdio>

#ifdef __wasm__
__attribute__((visibility("default")))
#endif

int main() {
  std::ostringstream oss;
  oss << "test" << std::endl;
  std::puts(oss.str().data());
}
