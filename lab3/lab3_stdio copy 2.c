#include <stdio.h>
#include <string.h>
#include <strings.h>

char symbol_from_value(int value, int base) {
  if (value >= 0 && value <= 9)
    return '0' + value;
  return 'a' + value - 10;
}

int value_from_symbol(char symbol) {
  if (symbol >= '0' && symbol <= '9')
    return symbol - '0';
  return symbol - 'a' + 10; 
}

void copiar_str(char* str, char* copia, int strlen) {
  for (int i = 0; i < strlen; i++)
    copia[i] = str[i];
  copia[strlen] = '\0';
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
  str_number[i] = '\0';
  return i;
}

int complemento_base(char* num, int num_len, int base) {
  // inverte
  //printf("ANTES DE INVERTER: %s\n", num);
  for (int i = 0; i < num_len; i++)
    num[i] = symbol_from_value(base - 1 - value_from_symbol(num[i]), base);
  //printf("DEPOIS DE INVERTER %s\n", num);
  // soma 1
  for (int i = num_len - 1; i >= 0; i--) {
    if (num[i] != symbol_from_value(base - 1, base)) {
      num[i] = symbol_from_value(value_from_symbol(num[i]) + 1, base);
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
    value = value_from_symbol(hexa[j]);
    num_bits = int_to_base(bits, value, 2);
    for (int k = 0; k < 4 - num_bits; k++)
      binary[i++] = '0';
    for (int k = 0; k < num_bits; k++)
      binary[i++] = bits[k];
  }
  binary[32] = '\0';
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
  if (sign && value_from_symbol(hexa[0]) >= 8) {
    copiar_str(hexa, complemento, hexa_len);
    hexa_len = complemento_base(complemento, hexa_len, 16);
    hexa = complemento;
    sinal = -1;
  }
  for (int i = 0; i < hexa_len; i++) {
    decimal = 16 * decimal + value_from_symbol(hexa[i]);
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

void formatar_entrada(char* input, int input_len) {
  for (int i = 0; i < input_len - 1; i++) {
    input[i] = input[i + 2];
  }
}

int decimal_to_str(char* str, int decimal) {
  int len = int_to_base(str, decimal, 10);
}

void print_decimal(char* str, int decimal) {
  int len;
  if (decimal < 0) {
    printf("-");
    decimal *= -1;
  }
  len = int_to_base(str, decimal, 10);
  printf("%s\n", str);
}

void print_num(char* str_num, int str_len, char letra) {
  int soh_zero = 1;
  printf("0%c", letra);
  for (int i = 0; i < str_len; i++) {
    if (str_num[i] != 0 && soh_zero)
      soh_zero = 0;
    if (! soh_zero)
      printf("%c", str_num[i]);
  }
  printf("\n");
}

int main() {
  char binary[33], hexa[9], input[20];
  int decimal, hexa_len, bin_len;
  scanf("%s", input);
  if (input[1] == 'x') {
    formatar_entrada(input, strlen(input));
    copiar_str(input, hexa, strlen(input));
    printf("HEXA: %s\n", hexa);
    hexa_len = completar_hexa(hexa, strlen(input));
    printf("HEXA: %s\n", hexa);
    decimal = hexa_to_decimal(hexa, hexa_len, 1);
    bin_len = hexa_to_binary(binary, hexa, hexa_len);
    print_num(binary, bin_len, 'b');
    print_decimal(input, decimal);
    print_num(hexa, hexa_len, 'x');
    //print_decimal(input, inverte_endian(hexa, hexa_len));
    printf("%d\n", inverte_endian(hexa, hexa_len));
  } else {
    printf("L");
  }
}
