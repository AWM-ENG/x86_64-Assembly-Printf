#include <stdio.h>

// Declare the external assembly function
extern int custom_printf(const char *format, ...);

int main(void) {
    custom_printf("System V ABI Test:\nString: %s\nInteger: %d\nNewline check\n", "Low-Level Engineering", 2026);
    return 0;
}
