#import "Basic";
#import "String";

Character_Iterator :: struct {
    line := 1;
    column := 0;
    buffer: string;
    file_path: string;
}

create_character_iterator :: (source: string, file_path: string) -> Character_Iterator {
    iterator:  Character_Iterator;
    iterator.buffer = source;
    iterator.file_path = file_path;
    return iterator;
}

next :: (using iterator: *Character_Iterator) -> u8 {
    assert(buffer.count != 0);

    char := buffer[0];
    advance(*buffer);

    if char == #char "\n" {
        line += 1;
        column = 0;
    } else {
        column += 1;
    }

    return char;
}

peek :: (using iterator: *Character_Iterator) -> u8 {
    assert(buffer.count != 0);
    return buffer[0];
}

end :: (using iterator: *Character_Iterator) -> bool {
    return buffer.count == 0;
}

error :: (using iterator: *Character_Iterator, message: string) {
    print("%:%:%: Error: %\n", file_path, line, column, message);
}