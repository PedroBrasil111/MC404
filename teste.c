#include <stdio.h>

int main() {
    int x = (~8) + 1;
    
    printf("%d %x\n", x, x);
    // 00545648
    // 48565400
}