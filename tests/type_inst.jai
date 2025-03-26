a: int = 5;
a1: int: 5;

c: #run generate_type(a);
c1: #run generate_type(b) = 20;
c2: #run generate_type(s=2) : 20;

MAX_STAMINA :: 10;
MAX_HEALTH: int: 10;

a, b: int, float;
a, b := 10, 20;

some :: (a: int, b: int = 10, c := 20) -> r: float, r2: s64 {

}

UNLEN :: 256;
buffer : [UNLEN+1]u16 = .[];
count : u32 = xx buffer.count;

a: Struct.Kind;
a: Struct.Kind = .FIRST;

a: #run -> Type.Test {
    result: Type = int;
    return result;
}

a: #run generate_type() = 20;
