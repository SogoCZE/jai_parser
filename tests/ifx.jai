main :: () {
    x := 10;
    y := ifx x > 5 "x > 5" else "x < 5";
    write_string(y);
}