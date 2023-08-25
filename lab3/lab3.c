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

char simbolo_do_valor(int value, int base) {
  if (value >= 0 && value <= 9)
    return '0' + value;
  return 'a' + value - 10;
}

int valor_do_simbolo(char symbol) {
  if (symbol >= '0' && symbol <= '9')
    return symbol - '0';
  return symbol - 'a' + 10; 
}

int remover_prefixo(char* num, int num_len) {
  int i;
  for (i = 2; i < num_len; i++) {
    num[i - 2] = num[i];
  }
  num[i - 2] = '\n';
  return i - 2;
}

int completar_zeros(char* num, int num_len, int qtd_bytes) {
  int i;
  num[qtd_bytes] = '\n';
  for (i = num_len - 1; i >= 0; i--) {
    num[qtd_bytes - num_len + i] = num[i];
  }
  for (int j = 0; j < qtd_bytes - num_len; j++) {
    num[j] = '0';
  }
  return qtd_bytes;
}

int int_para_base(char* str_num, int n, int base) {
  int i = 0, tmp = n, rem;
  char aux;
  while (tmp != 0) {
    rem = tmp % base;
    str_num[i] = simbolo_do_valor(rem, base);
    tmp = tmp / base;
    i++;
  }
  for (int j = 0; j < i / 2; j++) {
    aux = str_num[j];
    str_num[j] = str_num[i - 1 - j];
    str_num[i - 1 - j] = aux;
  }
  str_num[i] = '\n';
  return i;
}

int complemento_de_base(char *num, int num_len, int base) {
  int max_base = simbolo_do_valor(base - 1, base);
  for (int i = 0; i < num_len; i++)
    num[i] = simbolo_do_valor(base - 1 - valor_do_simbolo(num[i]), base);
  for (int i = num_len - 1; i >= 0; i--) {
    if (num[i] != max_base) {
      num[i] = simbolo_do_valor(valor_do_simbolo(num[i]) + 1, base);
      break;
    } else {
      num[i] = '0';
    }
  }
  return num_len;
}

/*
int complemento_base(char* num, int num_len, int base) {
  // inverte
  //printf("ANTES DE INVERTER: %s\n", num);
  for (int i = 0; i < num_len; i++)
    num[i] = symbol_from_value(base - 1 - valor_do_simbolo(num[i]), base);
  //printf("DEPOIS DE INVERTER %s\n", num);
  // soma 1
  for (int i = num_len - 1; i >= 0; i--) {
    if (num[i] != symbol_from_value(base - 1, base)) {
      num[i] = symbol_from_value(valor_do_simbolo(num[i]) + 1, base);
      break;
    } else {
      num[i] = '0';
    }
    //printf("%s\n", num);
  }
  return num_len;
}
*/

int hexa_para_binario(char* binario, char* hexa, int hexa_len) {
  char bits[5];
  int i = 0, valor, num_bits;
  for (int j = 0; j < hexa_len; j++) {
    valor = valor_do_simbolo(hexa[j]);
    num_bits = int_para_base(bits, valor, 2);
    for (int k = 0; k < 4 - num_bits; k++)
      binario[i++] = '0';
    for (int k = 0; k < num_bits; k++)
      binario[i++] = bits[k];
  }
  binario[32] = '\n';
  return i;
}

int hexa_para_decimal() {
  
}


int main() {
  char str[33], hexa[11], binario[33];

  int n = read(STDIN_FD, str, 20) - 1;

  n = remover_prefixo(str, n);
  write(STDOUT_FD, str, n + 1);

  /*
  char x = '0' + n;
  write(STDOUT_FD, &x, 1);
  */

  // 00000abc
  n = completar_zeros(str, n, 8);
  write(STDOUT_FD, str, n + 1);

  // 00000000000000000000000000000abc
  n = completar_zeros(str, n, 32);
  write(STDOUT_FD, str, n + 1);

  // 1000000
  n = int_para_base(str, 64, 2);
  write(STDOUT_FD, str, n + 1);

  // 00000abc
  n = int_para_base(str, 16 * 16 * 10 + 16 * 11 + 12, 16);
  n = completar_zeros(str, n, 8);
  write(STDOUT_FD, str, n + 1);
  
  // 00000000000000000000101010111100
  n = hexa_para_binario(binario, "00000abc", 8);
  write(STDOUT_FD, binario, n + 1);

  // fffff544
  n = complemento_de_base(str, 8, 16);
  write(STDOUT_FD, str, n + 1);

  // 11111111111111111111010101000100
  n = complemento_de_base(binario, 32, 2);
  write(STDOUT_FD, binario, n + 1);


  return 0;
}

