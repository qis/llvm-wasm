#include <sstream>
#include <cstdio>

__attribute__((visibility("default")))
int main() {
  std::ostringstream oss;
  oss << "test" << std::endl;
  std::puts(oss.str().data());
}
