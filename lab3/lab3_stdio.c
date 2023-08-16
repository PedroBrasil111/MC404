#include <stdio.h>

#define STDIN_FD  0
#define STDOUT_FD 1

#define pos 0
#define neg 1
#define hex 2

int representacao(char* str) {
  if (str[1] == 'x')
    return hex;
  else if (str[0] == '-')
    return neg;
  return pos;
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

char str_number[20];

char* int_to_base(int n, int base) {
  int i = 0, tmp = n, rem;
  while (tmp != 0) {
    rem = tmp % base;
    str_number[i] = symbol_from_value(rem, base);
    tmp = tmp / base;
    i++;
  }
  return str_number;
}

int decimal_to_binary(char* str, int strlen) {
  char binario[20];
  int i = 0, tmp = decimal_to_int(str, strlen);
  binario[0] = '0';
  binario[1] = 'b';
  if (str[0] == '-') {
    binario[i++] = '1';
  }

}

int main() {
  char str[20];
  /* Read up to 20 bytes from the standard input into the str buffer */
  //int n = scanf("%s", str);
  //int rep = representacao(str);
  printf("%s\n", int_to_base(10, 2));
  /*
  if (rep == pos) {

  } else if (rep == neg) {

  } else {

  }


  / Write n bytes from the str buffer to the standard output /
  write(STDOUT_FD, str, n);
  return 0;
  */
}
