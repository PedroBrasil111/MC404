#include <stdio.h>

void print_mat(int mat[][8], int lin, int col) {
    for (int i = 0; i < lin; i++) {
        for (int j = 0; j < col; j++) {
            printf("%d ", mat[i][j]);
        }
        printf("\n");
    }
}

int main() {
    int filtro[3][3] = {
        {-1, -1, -1},
        {-1,  8, -1},
        {-1, -1, -1}
    };
    int mat[10][8] = {
        {0, 1, 2, 3, 4, 5, 6, 7},
        {0, 1, 2, 3, 4, 5, 6, 7},
        {0, 1, 2, 3, 4, 5, 6, 7},
        {0, 1, 2, 3, 4,  5, 6, 7},
        {0, 1, 2, 3, 4, 5, 6, 7},
        {0, 1, 2, 3, 4, 5, 6, 7},
        {0, 1, 2, 3, 4, 5, 6, 7},
        {0, 1, 2, 3, 4, 5, 6, 7},
        {0, 1, 2, 3, 4, 5, 6, 7},
        {0, 1, 2, 3, 4, 5, 6, 7}
    };
    int filtrado[10][8];
    int lin = 10, col = 8;
    for (int i = 1; i < lin - 1; i++) {
        for (int j = 1; j < col - 1; j++) {
            int soma = 0;
            for (int k = -1; k < 2; k++) {
                for (int l = -1; l < 2; l++) {
                    soma += mat[i + k][j + l] * filtro[k][l];
                }
            }
            filtrado[i][j] = soma;
        }
    }
    for (int j = 0; j < col; j++) {
        filtrado[0][j] = -1;
        filtrado[lin - 1][j] = -1;
    }
    for (int i  = 1; i < lin - 1; i++) {
        filtrado[i][0] = -1;
        filtrado[i][col - 1] = -1;
    }
    print_mat(filtrado, lin, col);
}