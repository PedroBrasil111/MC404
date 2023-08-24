#include <stdio.h>

int formatar_hexa(char* hexa, char* input, int input_len) {
  hexa[8] = '\0';
  for (int i = 0; i < 10 - input_len; i++) {
    hexa[i] = '0';
  }
  for (int i = 2; i < input_len; i++) {
    printf("%c %d\n", input[i], i);
    hexa[8 - input_len + i] = input[i];
  }
  return 8;
}
char symbol_from_value(int value, int base) {
  if (value >= 0 && value <= 9)
    return '0' + value;
  return 'a' + value - 10;
}
int completar_hexa(char* hexa, int hexa_len) {
  for (int i = 0; i < hexa_len; i++) {
    hexa[7 - i] = hexa[hexa_len - 1 - i];
    hexa[hexa_len - i] = '0';
  }
  hexa[0] = '0';
  return 8;
}
int value_from_symbol(char symbol) {
  if (symbol >= '0' && symbol <= '9')
    return symbol - '0';
  return symbol - 'a' + 10; 
}
int int_to_base(char* str_number, int n, int base) {
  int i = 0, tmp = n, rem;
  char aux;
  while (tmp != 0) {
    rem = tmp % base;
    str_number[i] = symbol_from_value(rem, base);
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

int hexa_to_binary(char* binary, char* hexa, int hexa_len) {
  char bits[4];
  int i = 0, value, num_bits;
  for (int j = 0; j < hexa_len; j++) {
    value = value_from_symbol(hexa[j]);
    num_bits = int_to_base(bits, value, 2);
    for (int k = 0; k < 4 - num_bits; k++)
      binary[i++] = '0';
    for (int k = 0; k < num_bits; k++)
      binary[i++] = bits[k];
  }
  binary[32] = '\n';
  return i;
}
void print_num(char* str_num, int str_len, char letra) {
  int i;
  printf("0%c", letra);
  for (i = 0; str_num[i] != '0'; i++) ;
  printf("%d\n", str_len - i);
  for (i = i + 1; i < str_len; i++) {
    printf("%c", str_num[i]);
  }
  printf("\n");
}
int main() {
    char hexa[20] = "00545648", bin[20];
    int hexa_len = 8;
    int n = hexa_to_binary(bin, hexa, hexa_len);
    print_num(hexa, hexa_len, 'x');
    printf("%s\n", bin);
}