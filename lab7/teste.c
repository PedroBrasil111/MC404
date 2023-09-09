#include <stdio.h>
#include <string.h>

// Function to calculate Hamming(7, 4) parity bits
void calculateParityBits(char input[5], char encoded[8]) {
    encoded[0] = (((input[0] ^ input[1]) + '0') ^ input[3]) + '0';
    printf("%c\n", encoded[2]);
    encoded[1] = (((input[0] ^ input[2]) + '0') ^ input[3]) + '0';
    printf("%c\n", encoded[4]);
    encoded[3] = (((input[1] ^ input[2]) + '0') ^ input[3]) + '0';
    printf("%c\n", encoded[5]);
}

int main() {
    char input[5];
    char encoded[8];

    // Input a 4-bit binary number as a string
    printf("Enter a 4-bit binary number (e.g., 1010): ");
    scanf("%4s", input);

    // Check if the input is exactly 4 characters long
    if (strlen(input) != 4) {
        printf("Invalid input. Please enter a 4-bit binary number.\n");
        return 1;
    }

    // Calculate and set parity bits
    calculateParityBits(input, encoded);

    // Copy input bits to encoded bits
    encoded[2] = input[0];
    encoded[4] = input[1];
    encoded[5] = input[2];
    encoded[6] = input[3];

    // Null-terminate the encoded string
    encoded[7] = '\0';

    // Print the encoded Hamming code
    printf("Hamming(7, 4) encoded: %s\n", encoded);

    return 0;
}
