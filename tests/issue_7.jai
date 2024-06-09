if (get_parent_vessel(lookup(components.*[i])) != get_thandle(new_vessel)){
    array_unordered_remove(components, i);
    i -= 1;
}
