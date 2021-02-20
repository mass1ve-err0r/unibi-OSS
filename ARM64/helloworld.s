.data           /* define any data structures here */
msg:
    .ascii        "Hello World with arm64!\n"
len = . - msg   /* set 'len' to the length of the variable msg */


.text           /* instructions follow in this section */
.globl _start   /* define entrypoint label, usually _start */

_start:         /* this is our entrypoint's label, execution starts here! */
    /* syscall write(int fd, const void *buf, size_t count) */
    mov     x0, #1      /* set fd to stdoput */
    ldr     x1, =msg    /* buffer to use points to our message  */
    ldr     x2, =len    /* size of the buffer */
    mov     x8, #64     /* sys_write() is at 64 in the kernel functions table */
    svc     #0          /* make syscall */

    /* syscall exit(int status) */
    mov     x0, #0      /* exit with code, here 0 because no error */
    mov     x8, #93     /* exit is at 93 in the table */
    svc     #0          /* syscall */
