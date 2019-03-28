#include <stdio.h>

// Defined in MinSwift
void fizzbuzz(double);

// Call from MinSwift
double printNewLine(void) {
    puts("");
    return 0.;
}
double printDoubleAsInt(double x) {
    printf("%d", (int)x);
    return x;
}

double printFizz(void) {
    printf("Fizz");
    return 0.;
}

double printBuzz(void) {
    printf("Buzz");
    return 0.;
}

int main(void) {
    fizzbuzz(50.);
    return 0;
}
