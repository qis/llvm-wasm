#include <sstream>
#include <cstdio>

int main() {
  std::ostringstream oss;
  oss << "test" << std::endl;
  std::puts(oss.str().data());
}

extern "C" {

void __init_libc(char** envp, char* pn);
void __libc_start_init(void);

__attribute__((visibility("default")))
int start() {
  static char value = '\0';
  static char* envp[41] = {};
  for (size_t i = 0; i < 41; i++) {
    envp[i] = &value;
  }
  __init_libc(envp, envp[40]);
  __libc_start_init();
  return main();
}

}  // extern "C"
