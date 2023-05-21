foo :: (a: string, b: int) -> string {
    return "";
}

Gender :: enum {
    MALE;
    FEMALE;
    OTHER;
}

Person :: struct {
    name: string;
    age: int;
    gender: Gender;
    
    friends: []*Person;
}

PI :: 3.13;

main :: () {
    percentage: int;
    result := foo("bar", 100);
}