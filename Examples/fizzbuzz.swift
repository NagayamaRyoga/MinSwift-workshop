func fizzbuzz(_ n: Double) -> Double {
    if n > 1 {
        fizzbuzz(n - 1)
    };
    if n % 3 == 0 {
        printFizz()
    };
    if n % 5 == 0 {
        printBuzz()
    };
    if (n % 3 != 0) * (n % 5 != 0) {
        printDoubleAsInt(n)
    };
    printNewLine()
}
