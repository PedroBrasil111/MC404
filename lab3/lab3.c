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
  // desloca
  for (i = num_len - 1; i >= 0; i--)
    num[qtd_bytes - num_len + i] = num[i];
  // adiciona zeros
  for (int j = 0; j < qtd_bytes - num_len; j++)
    num[j] = '0';
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

int complemento_base(char *num, int num_len, int base) {
  int max_base = simbolo_do_valor(base - 1, base);
  // inverte
  for (int i = 0; i < num_len; i++)
    num[i] = simbolo_do_valor(base - 1 - valor_do_simbolo(num[i]), base);
  // soma 1
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

int base_para_decimal(char* num, int num_len, int base) {
  int decimal = 0;
  for (int i = 0; i < num_len; i++) 
    decimal = base * decimal + valor_do_simbolo(num[i]);
  return decimal;
}

int hexa_para_decimal(char* hexa, int hexa_len, int sinalizado) {
  long decimal = 0;
  int sinal = 1;
  if (sinalizado && valor_do_simbolo(hexa[0]) >= 8) {
    hexa_len = complemento_base(hexa, hexa_len, 16);
    sinal = -1;
  }
  for (int i = 0; i < hexa_len; i++)
    decimal = 16 * decimal + valor_do_simbolo(hexa[i]);
  if (sinal == -1)
    hexa_len = complemento_base(hexa, hexa_len, 16);
  return sinal * decimal;
}

int decimal_para_hexa(char* hexa, int decimal) {
  int hexa_len;
  if (decimal < 0)
    hexa_len = int_para_base(hexa, -decimal, 16);
  else
    hexa_len = int_para_base(hexa, decimal, 16);
  hexa_len = completar_zeros(hexa, hexa_len, 8);
  if (decimal < 0)
    hexa_len = complemento_base(hexa, hexa_len, 16);
  return hexa_len;
}

#define MAX_DEC 18

void write_decimal(int decimal) {
  char str_num[MAX_DEC];
  int i = MAX_DEC - 2;
  str_num[MAX_DEC - 1] = '\n';
  // negativo
  if (decimal < 0) {
    write(STDOUT_FD, "-", 1);
    decimal *= -1;
  }
  // positivo
  while (decimal > 0) {
    str_num[i] = '0' + (decimal % 10);
    decimal /= 10;
    i--;
  }
  write(STDOUT_FD, &str_num[i + 1], MAX_DEC - i);
}

void write_num(char* num, int num_len, char letra) {
  int i;
  write(STDOUT_FD, "0", 1);
  write(STDOUT_FD, &letra, 1);
  for (i = 0; num[i] == '0'; i++) ;
  write(STDOUT_FD, &num[i], num_len + 1 - i);
}

int inverte_endian(char* hexa, int hexa_len) {
  char aux;
  for (int i = 0; i < hexa_len / 2; i += 2) {
    aux = hexa[i];
    hexa[i] = hexa[hexa_len - 2 - i];
    hexa[hexa_len - 2 - i] = aux;
    aux = hexa[i + 1];
    hexa[i + 1] = hexa[hexa_len - 1 - i];
    hexa[hexa_len - 1 - i] = aux;
  }
  return hexa_para_decimal(hexa, hexa_len, 0);
}

int formatar_input_hexa(char* input, int input_len) {
  if (input[1] == 'x')
    input_len = remover_prefixo(input, input_len);
  return completar_zeros(input, input_len, 8);
}

int extrair_input_decimal(char* input, int input_len) {
  if (input[0] == '-')
    return -1 * base_para_decimal(&input[1], input_len - 1, 10);
  return base_para_decimal(input, input_len, 10);
}

int main() {
  char str[33], *hexa, binario[33];
  int n;
  /*
  n = remover_prefixo(str, n);
  write(STDOUT_FD, str, n + 1);

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
  n = complemento_base(str, 8, 16);
  write(STDOUT_FD, str, n + 1);

  // 11111111111111111111010101000100
  n = complemento_base(binario, 32, 2);
  write(STDOUT_FD, binario, n + 1);

  write_decimal(10);

  write_decimal(123415);

  // -2748
  int decimal = hexa_para_decimal("fffff544", 8, 1);
  write_decimal(decimal);

  decimal = hexa_para_decimal("80000000", 8, 1);
  write_decimal(decimal);
  
  // 0xabc
  write_num("00000abc\n", 8, 'x');

  // 0b101010111100
  write_num("00000000000000000000101010111100\n", 32, 'b');

  // 0xfffff544
  n = decimal_para_hexa(str, -2748);
  write_num(str, n, 'x');

  // 1213617152
  decimal = inverte_endian("00545648", 8);
  write_decimal(decimal);

  // 12345
  decimal = base_para_decimal("12345", 5, 10);
  write_decimal(decimal);
  */

  int decimal;
  int hexa_len;
  int input_len = read(STDIN_FD, str, 20) - 1;
  write(STDIN_FD, "\n", 1);
  if (str[1] == 'x') {
    hexa_len = formatar_input_hexa(str, input_len);
    hexa = str;
    int bin_len = hexa_para_binario(binario, hexa, hexa_len);
    write_num(binario, bin_len, 'b');
    write_decimal(hexa_para_decimal(hexa, hexa_len, 1));
  } else {
    decimal = extrair_input_decimal(str, input_len);
    hexa_len = decimal_para_hexa(str, decimal);
    hexa = str;
    int bin_len = hexa_para_binario(binario, hexa, hexa_len);
    write_num(binario, bin_len, 'b');
    write_decimal(decimal);
  }
  write_num(hexa, hexa_len, 'x');
  write_decimal(inverte_endian(hexa, hexa_len));

  return 0;
}

