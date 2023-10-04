#include <stdio.h>
#include <time.h>

void print_mat(int mat[][8], int lin, int col) {
    for (int i = 0; i < lin; i++) {
        for (int j = 0; j < col; j++) {
            printf("%d ", mat[i][j]);
        }
        printf("\n");
    }
}

int main() {
    clock_t start_time = clock();

    int filtro[3][3] = {
        {-1, -1, -1},
        {-1,  8, -1},
        {-1, -1, -1}
    };
    int mat[10][8] = {
        {0, 1, 2, 3, 4, 5, 6, 7},
        {0, 1, 255, 032, 123, 5, 6, 7},
        {0, 1, 2, 3, 243, 5, 6, 7},
        {0, 143, 213, 123, 4,  5, 6, 7},
        {0, 1, 312, 3, 4, 5, 6, 7},
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
                for (int q = -1; q < 2; q++) {
                    soma += mat[i + k][j + q] * filtro[k + 1][q + 1];
                }
            }
            filtrado[i][j] = soma;
            printf("%d ", filtrado[i][j]);
            if (filtrado[i][j] < 0)
                filtrado[i][j] = 0;
            if (filtrado[i][j] > 255)
                filtrado[i][j] = 255;
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

    // Record the end time
    clock_t end_time = clock();

    // Calculate the runtime in seconds (elapsed time)
    double runtime = (double)(end_time - start_time) / CLOCKS_PER_SEC;

    // Print the runtime
    printf("Runtime: %.2f seconds\n", runtime);

    return 0;
}