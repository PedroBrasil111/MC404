#include <stdio.h>
#include <stdlib.h>

void reverse(char str[], int length) {
    int start = 0;
    int end = length - 1;
    while (start < end) {
        char temp = str[start];
        str[start] = str[end];
        str[end] = temp;
        start++;
        end--;
    }
}

char* itoa(int val, char* buffer, int base) {
    // Handle 0 explicitly, otherwise, an empty string is printed
    if (val == 0) {
        buffer[0] = '0';
        buffer[1] = '\0';
        return buffer;
    }

    int i = 0;
    int isNegative = 0;

    // Handle negative numbers for bases 10 and 16
    if (val < 0 && (base == 10 || base == 16)) {
        isNegative = 1;
        val = -val;
    }

    // Process individual digits
    while (val != 0) {
        int rem = val % base;
        buffer[i++] = (rem > 9) ? (rem - 10) + 'a' : rem + '0';
        val = val / base;
    }

    // Append negative sign for base 10
    if (isNegative && base == 10) {
        buffer[i++] = '-';
    }

    buffer[i] = '\0'; // Null-terminate string

    // Reverse the string
    reverse(buffer, i);

    return buffer;
}

int main() {
    int num = -1;
    char buffer[32]; // Assuming 32-bit integers

    printf("%d in base 10: %s\n", num, itoa(num, buffer, 10));
    printf("%d in base 16: %s\n", num, itoa(num, buffer, 16));

    return 0;
}
