package type.numbers

data class Digit(
    val number: Int
) {
    init {
        assert(number in 0..9)
    }
}
