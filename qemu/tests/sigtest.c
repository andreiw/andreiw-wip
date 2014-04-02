#include <stdio.h>
#define __USE_GNU
#include <stdlib.h>
#include <signal.h>
#include <sys/types.h>
#include <string.h>
#include <inttypes.h>
#include <sys/mman.h>
#include <execinfo.h>

uint8_t p[4096] __attribute__ ((aligned(4096)));

void fill_buffer(uint8_t *p)
{
#ifdef __aarch64__
    {
      uint32_t *t = (uint32_t *) p;
      *t++ = 0xd45c0020; /* hlt #xxxx */
      *t++ = 0xd65f03c0; /* ret */
    }
#elif defined(__x86_64__) || defined(__i386__)
    {
      uint8_t *t = (uint8_t *) p;
      *t++ = 0x0f; 
      *t++ = 0x0b; /* ud2 */
      *t++ = 0xc3; /* ret */
    }
#endif
}

void
handler(int signum, siginfo_t *siginfo, void *ctx)
{
  ucontext_t *uctx = ctx;

  fprintf(stderr, "got sig %d\n", signum);

  if (signum == SIGILL) {
    munmap(&p, 4096);

    /*
     * Skip the undef instruction and make
     * sure we get a back-to-back SIGSEGV.
     */
#ifdef __aarch64__
    uctx->uc_mcontext.pc += 4;
#elif defined(__x86_64__)
    uctx->uc_mcontext.gregs[REG_RIP] += 2;
#elif defined(__i386__)
    uctx->uc_mcontext.gregs[REG_EIP] += 2;
#else
#error unsupported arch
#endif
  } else {
    mmap(&p, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);

    fill_buffer(p);

    mprotect(&p, 4096, PROT_EXEC);
  }
}


int
main(int argc, char **argv)
{
  static struct sigaction action;
  typedef void (*entry_t)(void);
  entry_t entry;

  memset(&action, 0, sizeof(action));
  action.sa_sigaction = handler;
  sigemptyset(&action.sa_mask);
  action.sa_flags = SA_RESTART | SA_SIGINFO;;
  sigaction(SIGSEGV, &action, NULL);
  sigaction(SIGILL, &action, NULL);


  if (argc == 1 || strcmp(argv[1], "-2")) {
    fprintf(stderr, "SIGSEGV first\n");
    munmap(&p, 4096);
  } else {
    fprintf(stderr, "SIGILL first\n");
    fill_buffer(p);
    mprotect(&p, 4096, PROT_EXEC);
  }

  entry = (void *) p;
  entry();
  fprintf(stderr, "done :)\n");
  return 0;
}
