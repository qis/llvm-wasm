#include <iostream>
#include <sstream>
#include <cstdio>

extern "C" int test();

namespace ice {

int test();

}  // namespace ice

int main() {
  // Requires projects/libcxx/include/streambuf to declare
  //   basic_streambuf<_CharT, _Traits>::seekpos(pos_type, ios_base::openmode) and
  //   basic_streambuf<_CharT, _Traits>::seekoff(off_type, ios_base::seekdir, ios_base::openmode)
  // as inline, then it crashes at during WebAssembly execution with a memory access violation.
  //std::cout << "cout test: " << test() << std::endl;

  std::ostringstream oss;
  oss << "ostringstream test: " << test() << std::endl;
  std::puts(oss.str().data());

  std::printf("printf test: %d\n", test());

  std::fprintf(stderr, "stderr ice::test: %d\n", ice::test());
}
