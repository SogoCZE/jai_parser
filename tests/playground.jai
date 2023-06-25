operator [] :: (a: Bit_Array, i: int) -> bool {
    assert(i < a.count);
    return cast(bool) (a.slots[i >> 6] & (1 << (i & 63)));
}

operator []= :: inline (a: *Bit_Array, i: int, value: bool) {
    inline set_bit_to(a, i, value);
}