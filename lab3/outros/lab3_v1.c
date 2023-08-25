int read(int __fd, const void *__buf, int __n) {
    int ret_val;
  __asm__ __volatile__(
    "mv a0, %1           # file descriptor\n"
    "mv a1, %2           # buffer \n"
    "mv a2, %3           # size \n"
    "li a7, 63           # syscall write code (63) \n"
    "ecall               # invoke syscall \n"
    "mv %0, a0           # move return value to ret_val\n"
    : "=r"(ret_val)  // Output list
    : "r"(__fd), "r"(__buf), "r"(__n)    // Input list
    : "a0", "a1", "a2", "a7"
  );
  return ret_val;
}

void write(int __fd, const void *__buf, int __n) {
    __asm__ __volatile__(
    "mv a0, %0           # file descriptor\n"
    "mv a1, %1           # buffer \n"
    "mv a2, %2           # size \n"
    "li a7, 64           # syscall write (64) \n"
    "ecall"
    :   // Output list
    :"r"(__fd), "r"(__buf), "r"(__n)    // Input list
    : "a0", "a1", "a2", "a7"
  );
}

void exit(int code) {
  __asm__ __volatile__(
    "mv a0, %0           # return code\n"
    "li a7, 93           # syscall exit (64) \n"
    "ecall"
    :   // Output list
    :"r"(code)    // Input list
    : "a0", "a7"
  );
}

void _start() {
  int ret_code = main();
  exit(ret_code);
}

#define STDIN_FD  0
#define STDOUT_FD 1

#define pos 0
#define neg 1
#define hex 2
/*
int representacao(char* str) {
  if (str[1] == 'x')
    return hex;
  else if (str[0] == '-')
    return NEG;
  return POS;
}

int decimal_to_int(char* str, int strlen) {
  int ret = 0, i = 0, sinal = 1;
  if (str[0] == '-') {
    i++;
    sinal = -1;
  }
  for (int i; i < strlen; i++) {
    ret = ret * 10 + str[i] - '0';
  }
  return ret * sinal;
}

char symbol_from_value(int value, int base) {
  if (value >= 0 && value <= 9)
    return '0' + value;
  return 'a' + value - 10;
}

char* int_to_base(int n, int base) {
  int i = 0, tmp = n, rem;
  char* str_number[20];
  while (tmp != 0) {
    rem = tmp % base;
    str_number[i] = symbol_from_value(rem, base);
    tmp = tmp / base;
    i++;
  }
  return str_number;
}

int decimal_to_binary(char* str, int strlen) {
  char* binario[20];
  int i = 0, tmp = decimal_to_int(str, strlen);
  binario[0] = '0';
  binario[1] = 'b';
  if (str[0] == '-') {
    binario[i++] = '1';
  }

}
*/

int main() {
  char str[20];
  /* Read up to 20 bytes from the standard input into the str buffer */
  int n = read(STDIN_FD, str, 20);
  str[0] = n + '0';
  /* Write n bytes from the str buffer to the standard output */
  write(STDOUT_FD, str, n);
  return 0;
}
