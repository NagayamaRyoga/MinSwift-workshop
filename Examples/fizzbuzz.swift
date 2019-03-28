func fizzbuzz(_ n: Double) -> Double {
    let _0: Double = if n > 1 {
        fizzbuzz(n - 1)
    };
    let _2: Double = if n % 3 == 0 {
        printFizz()
    };
    let _3: Double = if n % 5 == 0 {
        printBuzz()
    };
    let _4: Double = if (n % 3 != 0) * (n % 5 != 0) {
        printDoubleAsInt(n)
    };
    printNewLine()
}
