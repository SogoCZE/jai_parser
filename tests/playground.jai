dummy_filename :: "(@Incomplete: We don't provide the filename and line number yet. My sincerest apologies.)";
dummy_l0 :: 0;
dummy_c0 :: 0;

pre_check_members :: ($T: Type)
#modify {
    info := cast(*Type_Info) T;
    return info.type == .STRUCT, "Type passed to parse_arguments is not a struct!";
}
{
    info := type_info(T);

    for * member: info.members {
        if should_skip(member) continue;
        // :ConstantSourceCodeLocation

        if member.type.type == .ARRAY {
            tia := cast(*Type_Info_Array) member.type;
            if tia.array_count == -1 {
                compiler_report(dummy_filename, dummy_l0, dummy_c0, tprint("Member '%' is an array of undetermined size; this is not yet handled in argument parsing (if it will ever be).", member.name));
            }
        }
    }
}