Point :: struct { x, y: int; }
Kind :: enum { A; B; }
N :: 3;

sum :: (values: [] int) -> int { return 0; }

values: [] int = [1, 4, 9];
grid: [] [] int = [[1], [2, 3], []];
points: [] Point = [{1, 2}, .{3, 4}, Point.{5, 6}];

make :: () -> [] int {
    return [1, 2];
}

main :: () {
    x := 2;
    single: [] int = [x];
    empty: [] int = [];
    trailing: [] int = [x, ];
    kinds: [] Kind = [.A, .B];
    one_kind: [] Kind = [.A];
    computed: [] int = [x + 1, x * 2];
    casted: [] int = [cast(int) 1.0];
    sum([1, 2]);
    sum([]);
    sum([x]) + 1;
    a := cast([2] int) [1, 2];
    single = [3];

    // Types
    T :: [N] float;
    U :: [2] [3] int;
    P :: [2] *int;
    V :: [] int;
    R :: [..] int;
    S :: [N] struct { q: int; };
    size := size_of([4] int);
    nested: [2] [2] int = [[1, 2], [3, 4]];

    #asm,no_barrier { nop; }
    #asm { nop; }
}
