#include <cstdio>

extern "C" int test();

namespace ice {

int test();

}  // namespace ice

int main() {
  std::printf("test: %d\nice::test: %d\n", test(), ice::test());
  std::fprintf(stderr, "test: %d\nice::test: %d\n", test(), ice::test());
  return 1;
}
