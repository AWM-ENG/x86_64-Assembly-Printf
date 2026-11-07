# x86_64 Assembly `custom_printf`

A lightweight, bare-metal implementation of the standard C `printf` variadic function written entirely from scratch in **x86_64 Assembly**, conforming strictly to the **System V AMD64 ABI**.

---

## 🏛 Architectural Overview

This project bypasses standard C library abstractions to interact directly with Linux system calls and manage low-level memory layouts.

### Key Architectural Mechanisms:
* **System V ABI Compliance:** Respects register-passing conventions for arguments (`RDI` for format string; `RSI`, `RDX`, `RCX`, `R8`, `R9` for arguments 2 through 6).
* **Variadic Argument Staging & Spilling:** Traverses arguments dynamically—fetching the first 6 arguments from local stack frames mapped from registers, and handling arguments 7 and above directly via stack offset traversal (`[RBP + 16]` upwards).
* **Base Conversion Engine (`itoa`):** Converts raw binary integer values into ASCII representations via repeated division by 10 (`div r9`), leveraging the stack as a LIFO buffer to reorder digits correctly.
* **Direct System Calls:** Drives output directly through `sys_write` (`rax = 1`, `stdout = 1`), optimizing performance by utilizing a default-first 1-byte length optimization.

---

## 🛠 Supported Format Specifiers & Escape Sequences

| Specifier / Escape | Description | Handling Mechanism |
| :---: | :--- | :--- |
| `%d` | Signed Decimal Integer | Fetches raw binary value, converts via custom `itoa`, and prints. |
| `%s` | Null-Terminated String | Computes string length dynamically and prints via `sys_write`. |
| `\n` | Newline Escape | Writes newline byte (`0x0A`) directly to standard output. |
| `%%` | Literal Percent Sign | Emits literal `%` character (`0x25`). |

---

## ⚙️ How to Build and Run on Linux

Follow these steps to assemble, package into a static library, and link your assembly function with a C test program.

### Step 1: Assemble the Source File
Compile the assembly source file into an object file using an assembler like `as` (GAS):

```bash
as -o custom_printf.o custom_printf.s

```
Step 2: Create a Static Library (custom_printf.a)
Package the object file into an archive (static library) so it can be easily linked:

```bash
ar rcs custom_printf.a custom_printf.o

```

Step 3: Write a C Test Driver (main.c)
Create a standard C file to test the assembly implementation:

use the 'C' test file

Step 4: Compile and Link
Compile your C driver and link it directly against your assembly object file:

```bash
gcc main.c custom_printf.a -o test_runner -no-pie

```

Step 5: Execute
Run the compiled binary:

```bash
./test_runner
