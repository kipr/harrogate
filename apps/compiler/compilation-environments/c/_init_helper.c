/* Add initializer functions */

/* based on http://stackoverflow.com/questions/1113409/attribute-constructor-equivalent-in-vc */

#include <stdio.h>

#ifdef _MSC_VER

#pragma section(".CRT$XCU",read)
#define INITIALIZER(f) \
   static void __cdecl f(void); \
   __declspec(allocate(".CRT$XCU")) void (__cdecl*f##_)(void) = f; \
   static void __cdecl f(void)

#elif defined(__GNUC__)

#define INITIALIZER(f) \
   static void f(void) __attribute__((constructor)); \
   static void f(void)

#endif

INITIALIZER(initialize)
{
  /* Disable the stdout buffer
   * --> http://stackoverflow.com/questions/15339379/node-js-spawning-a-child-process-interactively-with-separate-stdout-and-stderr-s
   * --> https://github.com/joyent/node/issues/2754
   */
  setbuf(stdout, NULL);
}
