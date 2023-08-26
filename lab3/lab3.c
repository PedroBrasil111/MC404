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
#define MAX_DEC 11  // MAX_INT em 32 bits possui 10 caracteres
#define MAX_BIN 35  // "0b" + 32 bits + "\n"
#define MAX_HEXA 11 // "0x" + 8 bits + "\n"

/* Retorna o caractere que representa o valor */
char simbolo_do_valor(int valor) {
  if (valor >= 0 && valor <= 9)
    return '0' + valor;
  return 'a' + valor - 10; // no caso, 'a' <= simbolo <= 'f'
}

/* Retorna o valor representado pelo simbolo */
int valor_do_simbolo(char simbolo) {
  if (simbolo >= '0' && simbolo <= '9')
    return simbolo - '0';
  return simbolo - 'a' + 10; 
}
/* Remove os 2 primeiros caracteres da string num, de tamanho num_len e retorna o novo tamanho */
int remover_prefixo(char* num, int num_len) {
  int i;
  for (i = 2; i < num_len; i++) {
    num[i - 2] = num[i];
  }
  num[i - 2] = '\n';
  return i - 2;
}

/* Completa a string num, de tamnho num_len, com char '0' no inicio
 * ate ela ter tamanho igual a qtd_bytes, retorna o novo tamanho */
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

/* Converte o numero n para sua forma na base passada como argumento
 * e guarda no vetor str_num como string. Retorna o tamanho desse vetor. */
int int_para_base(char* str_num, int n, int base) {
  int i = 0, tmp = n, rem;
  char aux;
  // converte com char menos significativo no comeco
  while (tmp != 0) {
    rem = tmp % base;
    str_num[i] = simbolo_do_valor(rem);
    tmp = tmp / base;
    i++;
  }
  // inverte
  for (int j = 0; j < i / 2; j++) {
    aux = str_num[j];
    str_num[j] = str_num[i - 1 - j];
    str_num[i - 1 - j] = aux;
  }
  str_num[i] = '\n';
  return i;
}

/* Realiza o complemento de base do numero na forma de string no vetor num,
 * de tamanho num_len, na base indicada, e retorna o novo tamanho da string. */
int complemento_base(char *num, int num_len, int base) {
  int max_base = simbolo_do_valor(base - 1);
  // inverte
  for (int i = 0; i < num_len; i++)
    num[i] = simbolo_do_valor(base - 1 - valor_do_simbolo(num[i]));
  // soma 1
  for (int i = num_len - 1; i >= 0; i--) {
    if (num[i] != max_base) {
      num[i] = simbolo_do_valor(valor_do_simbolo(num[i]) + 1);
      break;
    } else {
      num[i] = '0';
    }
  }
  return num_len;
}

/* Converte o numero na forma de string em hexa, de tamanho hexa_len,
 * para binario e retorna o tamanho do binario. */
int hexa_para_binario(char* binario, char* hexa, int hexa_len) {
  char bits[5];
  int i = 0, valor, num_bits;
  for (int j = 0; j < hexa_len; j++) {
    valor = valor_do_simbolo(hexa[j]);
    num_bits = int_para_base(bits, valor, 2);
    // completa com '0' a esquerda
    for (int k = 0; k < 4 - num_bits; k++)
      binario[i++] = '0';
    // escreve o numero binario na sequencia
    for (int k = 0; k < num_bits; k++)
      binario[i++] = bits[k];
  }
  binario[32] = '\n';
  return i;
}

/* Converte o numero na forma de string no vetor num, de tamanho num_len,
 * para decimal, de acordo com a base indicada. */
unsigned int base_para_decimal(char* num, int num_len, int base) {
  int unsigned decimal = 0; // unsigned para evitar overflow
  for (int i = 0; i < num_len; i++) 
    decimal = base * decimal + valor_do_simbolo(num[i]);
  return decimal;
}

/* Converte o numero na base 16 em formato de string no vetor hexa, de tamanho hexa_len,
 * para a base decimal e o retorna. Guarda o sinal do numero no endereco sinal.
 * Se sinalizado == 1, considera representacao com sinal. Caso contrario, sem sinal. */
unsigned int hexa_para_decimal(char* hexa, int* sinal, int hexa_len, int sinalizado) {
  unsigned int decimal = 0;
  *sinal = 1;
  // faz complemento de base antes se hexa for negativo
  if (sinalizado && valor_do_simbolo(hexa[0]) >= 8) {
    hexa_len = complemento_base(hexa, hexa_len, 16);
    *sinal = -1;
  }
  decimal = base_para_decimal(hexa, hexa_len, 16);
  // retorna hexa ao valor original
  if (*sinal == -1)
    hexa_len = complemento_base(hexa, hexa_len, 16);
  return decimal;
}

/* Converte o numero decimal com sinal indicado para a base 16,
 * e guarda o resultado em formato de string no vetor hex. Retorna o tamanho do vetor. */
int decimal_para_hexa(char* hexa, unsigned int decimal, int sinal) {
  int hexa_len = int_para_base(hexa, decimal, 16); // converte sem sinal
  hexa_len = completar_zeros(hexa, hexa_len, 8);
  if (sinal < 0) // negativo
    hexa_len = complemento_base(hexa, hexa_len, 16); 
  return hexa_len;
}

// padrao de comentario trocado por conta da pressa

/*
 * Inverte o endian de um numero hexadecimal e retorna o equivalente em decimal
 * - hexa: vetor que guarda a string do numero hexadecimal
 * - hexa_len: tamanho de hexa
 * - sinal: endereco para o sinal do decimal
 */
int inverte_endian(char* hexa, int hexa_len, int* sinal) {
  char aux;
  for (int i = 0; i < hexa_len / 2; i += 2) {
    // inverte [0] e [1] com [6] e [7], respectivamente
    aux = hexa[i];
    hexa[i] = hexa[hexa_len - 2 - i];
    hexa[hexa_len - 2 - i] = aux;
    // inverte [2] e [3] com [4] e [5], respec.
    aux = hexa[i + 1];
    hexa[i + 1] = hexa[hexa_len - 1 - i];
    hexa[hexa_len - 1 - i] = aux;
  }
  return hexa_para_decimal(hexa, sinal, hexa_len, 0); // 0 para indicar unsigned
}

/*
 * Formata o numero hexadecimal de uma string, retorna o tamanho da string
 * - input: vetor que guarda a string
 * - input_len: tamanho de input
 */
int formatar_input_hexa(char* input, int input_len) {
  if (input[1] == 'x')
    input_len = remover_prefixo(input, input_len); // remove o "0x"
  return completar_zeros(input, input_len, 8); // adiciona 0's ate ter 8 caracteres
}

/*
 * Extrai e retorna o numero decimal de uma string
 * - input: vetor que guarda a string
 * - sinal: endereco para o sinal do decimal
 * - input_len: tamanho de input
 */
unsigned int extrair_input_decimal(char* input, int* sinal, int input_len) {
  if (input[0] == '-') {
    *sinal = -1;
    return base_para_decimal(&input[1], input_len - 1, 10);
  }
  return base_para_decimal(input, input_len, 10);
}

/* 
 * Imprime um numero (em string) no formato '0{letra}num'
 * - num: vetor onde esta a string
 * - num_len: tamanho do vetor
 * - letra: letra que deve ser impressa para indicar a base
 */
void write_num(char* num, int num_len, char letra) {
  int i;
  write(STDOUT_FD, "0", 1);
  write(STDOUT_FD, &letra, 1);
  for (i = 0; num[i] == '0'; i++) ;
  write(STDOUT_FD, &num[i], num_len + 1 - i);
}

/* 
 * Imprime um numero inteiro
 * - decimal: o numero a ser impresso
 * - sinal: o sinal do numero (-1 ou +1)
 */
void write_decimal(unsigned int decimal, int sinal) {
  char str_num[MAX_DEC];
  int i = MAX_DEC - 2;
  str_num[MAX_DEC - 1] = '\n';
  // negativo
  if (sinal < 0)
    write(STDOUT_FD, "-", 1);
  // positivo
  while (decimal > 0) {
    str_num[i] = '0' + (decimal % 10);
    decimal /= 10;
    i--;
  }
  write(STDOUT_FD, &str_num[i + 1], MAX_DEC - i - 1);
}

int main() {
  char input[MAX_HEXA], *hexa, binario[MAX_BIN]; // representacoes em string dos numeros
  int sinal, hexa_len, input_len, bin_len;
  unsigned int decimal; // unsigned para evitar overflow, sinal guardado separadamente
  input_len = read(STDIN_FD, input, 20) - 1;
  write(STDIN_FD, "\n", 1);
  // Input hexadecimal
  if (input[1] == 'x') {
    hexa_len = formatar_input_hexa(input, input_len);
    hexa = input;
    bin_len = hexa_para_binario(binario, hexa, hexa_len);
    decimal = hexa_para_decimal(hexa, &sinal, hexa_len, 1);
  // Input decimal
  } else {
    decimal = extrair_input_decimal(input, &sinal, input_len); // transforma em int
    hexa_len = decimal_para_hexa(input, decimal, sinal); // converte em hexa e guarda em input
    hexa = input;
    bin_len = hexa_para_binario(binario, hexa, hexa_len);
  }
  write_num(binario, bin_len, 'b'); // impressao do binario
  write_decimal(decimal, sinal); // impressao do decimal
  write_num(hexa, hexa_len, 'x'); // impressao do hexadecimal
  decimal = inverte_endian(hexa, hexa_len, &sinal);
  write_decimal(decimal, sinal); // impressao com endianness invertido
  return 0;
}
