#include <stdio.h>

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

int base_to_decimal(char* str_num, int base, int start_index) {
  int dec_num = 0;
  for (int i = start_index; str_num[i] != '\n'; i++)
    dec_num = dec_num * base + value_from_symbol(str_num[i]);
  return dec_num;
}
int decimal_to_base(char* str_num, int dec_num, int base) {
  int i = 2, tmp = dec_num, rem;
  char aux;
  str_num[0] = '0';
  if (base == 2)
    str_num[1] = 'b';
  else if (base == 16)
    str_num[1] = 'x';
  while (tmp != 0) {
    rem = tmp % base;
    str_num[i] = symbol_from_value(rem, base);
    tmp = tmp / base;
    i++;
  }
  for (int j = 2; j < i / 2 + 1; j++) {
    aux = str_num[j];
    str_num[j] = str_num[i + 1 - j];
    str_num[i + 1 - j] = aux;
  }
  return i;
}

void decimal_to_binary(char* str_num, int dec_num) {
  int strlen;
  if (dec_num >= 0) {
    strlen = decimal_to_base(str_num, dec_num, 2);
  } else {
    strlen = decimal_to_base(str_num, -dec_num - 1, 2);
    str_num[strlen + 1] = '\n';
    for (int i = strlen - 1; i >= 2; i--)
      str_num[i + 1] = '1' - (str_num[i] - '0');
    str_num[2] = '1';
  }
}

int main() {
  char input[35], binary[35], hexa[35];
  int dec_num, dec_2_complement, aux = 0;
  /* Read up to 20 bytes from the standard input into the str buffer */
  fgets(input, 35, stdin);
  if (input[0] == '0') {
    dec_num = base_to_decimal(input, 16, 2);
    if (input[2] == '1')
      aux = 1;
    dec_2_complement = -base_to_decimal(input, 16, 2 + aux);
  } else if (input[0] == '-') {
    dec_num = dec_2_complement = -1 * base_to_decimal(input, 10, 1);
  } else {
    dec_num = base_to_decimal(input, 10, 0);
    if (input[0] == '1')
      aux = 1;
    dec_2_complement = -base_to_decimal(input, 16, aux);
  }
  decimal_to_binary(binary, dec_num);
  printf("%s\n", input);
  printf("%d\n", dec_2_complement);
  
  

  printf("%s\n", input);
  /*
  if (rep == POS) {

  } else if (rep == neg) {

  } else {

  }


  / Write n bytes from the str buffer to the standard output /
  write(STDOUT_FD, str, n);
  return 0;
  */
}
