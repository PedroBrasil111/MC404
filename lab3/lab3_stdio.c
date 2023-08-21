#include <stdio.h>

#define STDIN_FD  0
#define STDOUT_FD 1

#define POS 0
#define NEG 1
#define HEX 2

int representacao(char* str) {
  if (str[1] == 'x')
    return HEX;
  else if (str[0] == '-')
    return NEG;
  return POS;
}
/*
int base_to_int(char* str, int strlen, int base) {
  for (int i = 0)
}
*/

int decimal_to_int(char* str, int strlen) {
  int ret = 0, i = 0, sinal = 1;
  if (str[0] == '-') {
    i++;
    sinal = -1;
  }
  for (i; i < strlen; i++) {
    ret = ret * 10 + str[i] - '0';
  }
  return ret * sinal;
}

char symbol_from_value(int value, int base) {
  if (value >= 0 && value <= 9)
    return '0' + value;
  return 'a' + value - 10;
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
  return i;
}

int decimal_to_binary(char* str, char *binario, int strlen) {
  int i = 0, tmp = decimal_to_int(str, strlen), len;
  binario[0] = '0';
  binario[1] = 'b';
  len = int_to_base(binario, tmp, 2);
  printf("%d\n", binario);
  if (str[0] == '-') {
    for (i = len; i > 0; i--) {
      binario[i] = '1' - binario[i - 1] + '0';
    }
    binario[0] = '1';
  }
  return len;
}

int main() {
  char str[20] = {"1024"}, binario[20];
  char buffer[20];
  /* Read up to 20 bytes from the standard input into the str buffer */
  //int n = scanf("%s", str);
  //int rep = representacao(str);
  fgets(buffer, sizeof(buffer), stdin);
  decimal_to_binary(str, binario, 4);
  printf("%s\n", binario);
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
