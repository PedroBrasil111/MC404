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

/* Imprime o inteiro val em representacao hexadecimal */
void hex_code(int val){
  char hex[11];
  unsigned int uval = (unsigned int) val, aux;
  hex[0] = '0';
  hex[1] = 'x';
  hex[10] = '\n';
  for (int i = 9; i > 1; i--){
    aux = uval % 16;
    if (aux >= 10)
      hex[i] = aux - 10 + 'A';
    else
      hex[i] = aux + '0';
    uval = uval / 16;
  }
  write(1, hex, 11);
}

/* Retorna a mascara com o numero de bits */
int mask_bits(int bits) {
  // 0b000111...111
  //      '---v---'
  //      bits vezes
  // '0' (32 - bits) vezes antes da sequencia de '1'
  int mask = 0;
  for (int j = 0; j < bits; j++)
    mask = (mask << 1) + 1;
  return mask;
}

/* Faz o packing do input */
void pack(int input, int start_bit, int end_bit, int *val) {
  int mask = mask_bits(end_bit - start_bit);
  input &= mask; // sobram os bits desejados 
  *val |= (input << start_bit); // desloca e faz a uniao
}

/* Retorna o valor binario empacotado, dados os valores (values) inputados */
int binary_packed_value(int* values) {
  int num_bits[5] = {3, 8, 5, 5, 11};
  int ret = 0, start_bit = 0;
  for (int i = 0; i < 5; i++) {
    pack(values[i], start_bit, start_bit + num_bits[i], &ret);
    start_bit += num_bits[i];
  }
  return ret;
}

/* Extrai o (val_len + 1)-esimo numero do input e o atribui a values[val_len] */
void extract_value(int* values, int val_len, char* input) {
  int num = 0, str_start = 6 * val_len, str_end = str_start + 5;
  // conversao de string para inteiro
  for (int i = str_start + 1; i < str_end; i++)
    num = num * 10 + input[i] - '0';
  // atribuicao -- trata o caso negativo
  values[val_len] = (input[str_start] == '-') ? -num : num;
}

/* Constroi o array de inteiros values a partir do input */
void build_array(int* values, char* input) {
  for (int i = 0; i < 5; i++)
    extract_value(values, i, input);
}

int main() {
  char input[30];
  int values[5];
  int input_len = read(STDIN_FD, input, 30);
  build_array(values, input);
  hex_code(binary_packed_value(values));
}