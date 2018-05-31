#include <memory>
#include <cstdio>

extern "C" void sys_log(const char* str, int size);

namespace ice {

inline void log(const char* str) {
  sys_log(str, -1);
}

template <typename... Args>
inline void log(const char* format, Args&&... args) {
  const auto size = std::snprintf(nullptr, 0, format, std::forward<Args>(args)...);
  const auto data = std::make_unique<char[]>(static_cast<std::size_t>(size + 1));
  std::snprintf(data.get(), static_cast<std::size_t>(size + 1), format, std::forward<Args>(args)...);
  sys_log(data.get(), size);
}

int test();

}  // namespace ice

int main() {
  ice::log("test: [-]");
  ice::log("test: [%d]", ice::test());
}
