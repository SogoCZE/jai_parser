// This is comment.

// This is directive. Directives is used in Jai to provide metaprogramming.
#DirectiveName,param1,param2

#import "Basic"; // This import code from module "Basic". Its directive.

// This describe variables in Jai.
foo := "Bar"; // This variable is named "foo" and has string value of "Bar".
foo: string = "Bar"; // This variable is named "foo" and has string value of "Bar".

// This defined struct with two members "name" and "age". Name has type of string and age have type of int.
Person :: struct {
    name: string;
    age: int;
}

// This defines enum with three options.
Gender :: enum {
    MALE;
    FEMALE = 1;
    OTHER;
}

Programmer :: struct {
    favorite_programming_language: string = "Jai"; // This defines struct member "favorite_programming_language" with type of string and default value of "Jai".
    using person: Person; // This infers all members of sturct "Person" to the current struct. So struct "Programmer" now have also name and age as Person.
}

// This defines function that returns formatted string from one input param.
say_hello :: (name: string) -> string {
    return sprintf("Hello % how are you?\n", name);
} 

is_adult :: (age: int) -> bool {
    // This is if statment that check if variable age is bigger or same as 18. If so returns true.
    if age >= 18 {
        return true;
    }

    return false;
}

say_hello_with_gender_in_mind :: (gender: Gender) -> string {
    // This defines switch statment that formats string by specific gender and returns it.
    if gender == {
        case Gender.MALE;
            return sprintf("Hello male!\n");
        case .FEMALE;
            return sprintf("Hello female!\n");
        case .OTHER;
            return sprintf("Hello other!\n");
    }
}

set_variable_foo_to_new_value :: () {
    // this sets variable "foo" to new value of "Hello".
    foo = "Hello";
}

