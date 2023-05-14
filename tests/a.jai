#asm SYSCALL_SYSRET {
    mov.q call:  gpr === a,  SYS_write;

    mov.q fd:    gpr === di, STDOUT_FILENO;
    mov.q buf:   gpr === si, msg;
    mov.q count: gpr === d,  msglen;

    // t1 and t2 let us reserve rcx and r11, the rest are the args we need to pass and can be any gpr.
    syscall t1:, t2:, call, fd, buf, count;
}