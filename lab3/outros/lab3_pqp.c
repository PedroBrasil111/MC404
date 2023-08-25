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

void copiar_str(char* str, char* copia, int strlen) {
  for (int i = 0; i < strlen; i++)
    copia[i] = str[i];
  copia[strlen] = '\n';
}

int completar_hexa(char* hexa, int hexa_len) {
  for (int i = 0; i < hexa_len; i++) {
    hexa[7 - i] = hexa[hexa_len - 1 - i];
    hexa[hexa_len - i] = '0';
  }
  hexa[0] = '0';
  return 8;
}

int int_to_base(char* str_number, int n, int base) {
  int i = 0, tmp = n, rem;
  char aux;
  while (tmp != 0) {
    rem = tmp % base;
    str_number[i] = simbolo_do_valor(rem, base);
    tmp = tmp / base;
    i++;
  }
  for (int j = 0; j < i / 2; j++) {
    aux = str_number[j];
    str_number[j] = str_number[i - 1 - j];
    str_number[i - 1 - j] = aux;
  }
  if (base == 16)
    i = completar_hexa(str_number, i);
  str_number[i] = '\n';
  return i;
}

int complemento_base(char* num, int num_len, int base) {
  // inverte
  //printf("ANTES DE INVERTER: %s\n", num);
  for (int i = 0; i < num_len; i++)
    num[i] = simbolo_do_valor(base - 1 - valor_do_simbolo(num[i]), base);
  //printf("DEPOIS DE INVERTER %s\n", num);
  // soma 1
  for (int i = num_len - 1; i >= 0; i--) {
    if (num[i] != simbolo_do_valor(base - 1, base)) {
      num[i] = simbolo_do_valor(valor_do_simbolo(num[i]) + 1, base);
      break;
    } else {
      num[i] = '0';
    }
    //printf("%s\n", num);
  }
  return num_len;
}

int hexa_to_binary(char* binary, char* hexa, int hexa_len) {
  char bits[4];
  int i = 0, value, num_bits;
  for (int j = 0; j < hexa_len; j++) {
    value = valor_do_simbolo(hexa[j]);
    num_bits = int_to_base(bits, value, 2);
    for (int k = 0; k < 4 - num_bits; k++)
      binary[i++] = '0';
    for (int k = 0; k < num_bits; k++)
      binary[i++] = bits[k];
  }
  binary[32] = '\n';
  return i;
}

int decimal_to_hexa(int decimal, char *hexa) {
  int hexa_len;
  if (decimal < 0) {
    hexa_len = int_to_base(hexa, -decimal, 16);
    hexa_len = complemento_base(hexa, hexa_len, 16);
  } else {
    hexa_len = int_to_base(hexa, decimal, 16);
  }
  return hexa_len;
}

int hexa_to_decimal(char* hexa, int hexa_len, int sign) {
  long int decimal = 0;
  int sinal = 1;
  char complemento[35];
  if (sign && valor_do_simbolo(hexa[0]) >= 8) {
    copiar_str(hexa, complemento, hexa_len);
    hexa_len = complemento_base(complemento, hexa_len, 16);
    hexa = complemento;
    sinal = -1;
  }
  for (int i = 0; i < hexa_len; i++) {
    decimal = 16 * decimal + valor_do_simbolo(hexa[i]);
  }
  return sinal * decimal;
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
  return hexa_to_decimal(hexa, hexa_len, 0);
}

int formatar_hexa(char* hexa, char* input, int input_len) {
  hexa[8] = '\n';
  for (int i = 0; i < 10 - input_len; i++) {
    hexa[i] = '0';
  }
  for (int i = 2; i < input_len; i++) {
    hexa[8 - input_len + i] = input[i];
  }
  return 8;
}

int decimal_to_str(char* str, int decimal) {
  int len = int_to_base(str, decimal, 10);
}

void print_decimal(char* str, int decimal) {
  int aux;
  if (decimal < 0) {
    write(STDOUT_FD, "-", 1);
    write(STDOUT_FD, str, decimal_to_str(str, -decimal) + 1);
  } else {
    write(STDOUT_FD, str, decimal_to_str(str, decimal) + 1);
  }
}

void print_num(char* str_num, int str_len, char* letra) {
  int i;
  write(STDOUT_FD, "0", 1);
  write(STDOUT_FD, letra, 1);
  for (i = 0; str_num[i] != '0'; i++) ;
  write(STDOUT_FD, str_num[i + 1], str_len - i);
}

int main2() {
  /*
  char binary[33], hexa[9], input[20];
  int decimal, hexa_len, bin_len;
  scanf("%s", input);
  if (input[1] == 'x') {
    formatar_hexa(input, strlen(input));
    copiar_str(input, hexa, strlen(input));
    //printf("HEXA: %s\n", hexa);
    hexa_len = completar_hexa(hexa, strlen(input));
    //printf("HEXA: %s\n", hexa);
    decimal = hexa_to_decimal(hexa, hexa_len, 1);
    bin_len = hexa_to_binary(binary, hexa, hexa_len);
    print_num(binary, bin_len, 'b');
    print_decimal(input, decimal);
    print_num(hexa, hexa_len, 'x');
    //print_decimal(input, inverte_endian(hexa, hexa_len));
    //printf("%d\n", inverte_endian(hexa, hexa_len));
  } else {
    //printf("L");
  }
  */
}

int main() {
  char str[20], hexa[20], binario[20];
  int n = read(STDIN_FD, str, 20) - 1;
  int hexa_len, bin_len;
  if (str[1] == 'x') {
    hexa_len = formatar_hexa(hexa, str, n);
    write(STDOUT_FD, hexa, hexa_len + 1);
    print_num(hexa, hexa_len, "x");
    bin_len = hexa_to_binary(binario, hexa, hexa_len);
    write(STDOUT_FD, binario, bin_len + 1);
    print_decimal(str, hexa_to_decimal(hexa, hexa_len, 1));
    print_decimal(str, inverte_endian(hexa, hexa_len));
  }
  // write(STDOUT_FD, str, n);
  return 0;
}