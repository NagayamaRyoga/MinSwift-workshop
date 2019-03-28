func fizzbuzz(_ n: Double) {
    for i in 1 ... n {
        if i % 3 == 0 {
            printFizz()
        };
        if i % 5 == 0 {
            printBuzz()
        };
        if (i % 3 != 0) * (i % 5 != 0) {
            printDoubleAsInt(i)
        };
        printNewLine()
    }
}
