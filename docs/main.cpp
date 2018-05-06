#include <cstdio>

extern "C" int test();

namespace ice {

int test();

}  // namespace ice

int main() {
  std::printf("test: %d\n", test());
  std::fprintf(stderr, "ice::test: %d\n", ice::test());
}
