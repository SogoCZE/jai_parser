#import "Basic";
#import "String";

Iterator :: struct {
    line := 1;
    column := 0;
    buffer: string;
    file_path: string;
}

create_iterator :: (source: string, file_path: string) -> Iterator {
    iterator:  Iterator;
    iterator.buffer = source;
    iterator.file_path = file_path;
    return iterator;
}

next :: (using iterator: *Iterator) -> u8 {
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

peek :: (using iterator: *Iterator, to := 1) -> u8 {
    assert(buffer.count > to-1);
    return buffer[to-1];
}

end :: (using iterator: *Iterator) -> bool {
    return buffer.count == 0;
}

error :: (using iterator: *Iterator, message: string) {
    print("%:%:%: Error: %\n", file_path, line, column, message);
}