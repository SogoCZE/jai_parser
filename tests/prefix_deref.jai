p: *int;
(.*)p;

a: *int;
b := (.*)a + 1;

c: *int;
d := (.*)c;

p: *u64;
(.*) cast(*u64) p;

q: **void;
val := (.*) cast(**void) q;

x: *u32;
y := (.*)x + 2;

arr: *[]int;
val2 := (.*)arr[0];

pp: **int;
pp_val := (.*)pp.*;

S :: struct { a: int; }
sp: *S;
fa := (.*)sp.a;

a_ptr: *int;
par := (.*)(a_ptr);
