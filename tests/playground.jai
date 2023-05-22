#if OS == .WINDOWS {
    #scope_file;

    test: int;
    test2 :: 20;

} else #if (OS == .LINUX || OS == .MACOS) {

    #scope_file;

    #import "POSIX";

    APOLLO_TIME_FOR_JAN_1_1970 :: Apollo_Time.{low=0xdbd87f0edb7c8000, high=0x300};

    libc :: #system_library "libc";
    timelocal :: (timeptr: *tm) -> time_t #foreign libc;
    timegm    :: (timeptr: *tm) -> time_t #foreign libc;
    
    #scope_export;
    
    current_time_consensus :: () -> Apollo_Time {
        ts: timespec;
        clock_gettime(CLOCK_REALTIME, *ts);

        apollo := timespec_to_apollo(ts);
        return apollo;
    }

}

test :: 10;