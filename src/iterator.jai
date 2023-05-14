#import "Basic";
#import "String";

Iterator :: struct {
    line := 1;
    column := 1;
    buffer: string;
    file: string;
}

create_iterator :: (source: string, file: string) -> Iterator {
    iterator:  Iterator;
    iterator.file = file;
    iterator.buffer = source;
    return iterator;
}

next :: (using iterator: *Iterator) -> u8 {
    if buffer.count == 0 return 0;
    // assert(buffer.count != 0);

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

peek :: (using iterator: *Iterator, to := 1) -> u8 {
    if buffer.count <= to-1 return 0;
    // assert(buffer.count > to-1);
    return buffer[to-1];
}

end :: (using iterator: *Iterator) -> bool {
    return buffer.count == 0;
}