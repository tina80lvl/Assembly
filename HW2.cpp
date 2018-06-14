#include <stdio.h>

// by 1 byte
void memcpy1(char *from, char *to, int size) {
    if (size <= 0) {
        return;
    }
    int tmp = size;
    //0 - from, 1 - to, 2- tmp size, 3 - static size
    asm volatile(
    "loop1:\n\t"
            "mov (%0), %%al\n\t"
            "mov %%al, (%1)\n\t"
            "inc %0\n\t"
            "inc %1\n\t"
            "dec %2\n\t"
            "jnz loop1\n\t"
    :"+r"(from), "+r"(to), "+r"(tmp)
    : 
    :"cc", "memory", "rax"
    );
    from -= size;
    to -= size;
}
 
//by 8 byte
void memcpy8(char *from, char *to, int size) {
    if (size <= 0) {
        return;
    }
 
    int old_size = size;
 
    int tmp = size / 8;
    int ost = size % 8;//scolco nado eshe scopirovat
    if (ost != 0) {
        memcpy1(from, to, ost);
    }
    if (tmp <= 0) {
        return;
    }
    size -= ost;
    from += ost;
    to += ost;
 
    asm volatile(
    "loop8:\n\t"
            "mov (%0), %%rax\n\t"
            "mov %%rax, (%1)\n\t"
            "add $8,%0\n\t"
            "add $8,%1\n\t"
            "dec %2\n\t"
            "jnz loop8\n\t"
    :"+r"(from), "+r"(to), "+r"(tmp)
    :
    :"cc", "memory", "rax"
    );
    from -= old_size;
    to -= old_size;
}
 
//by 16
void memcpy_16_simple(char *from, char *to, int size) {
    if (size <= 0) {
        return;
    }
    int old_size = size;
    int tmp = size / 16;
    int ost = size % 16;
    if (ost != 0) {
        memcpy8(from, to, ost);
    }
    if (tmp <= 0) {
        return;
    }
    size -= ost;
    from += ost;
    to += ost;
    //0 - from, 1 - to, 2- tmp size, 3 - static size
    asm volatile(
    "loop16s:\n\t"
            "movdqu (%0), %%xmm1\n\t"
            "movdqu %%xmm1, (%1)\n\t"
            "add $16,%0\n\t"
            "add $16,%1\n\t"
            "dec %2\n\t"
            "jnz loop16s\n\t"
    :"+r"(from), "+r"(to), "+r"(tmp)
    :
    :"cc", "memory", "xmm1"
    );
    from -= old_size;
    to -= old_size;
}
 
 
void memcpy_16_hard(char *from, char *to, int size) {
    if (size <= 0) {
        return;
    }
 
    int old_size = size;
    int ss = (int &) (from);
    int offset = ss % 16;
    if (offset != 0) {
        offset = 16 - offset;
        memcpy8(from, to, offset);
        from += offset;
        to += offset;
        size -= offset;
    }
    int tmp = size / 16;
    int ost = size % 16;
    if (tmp > 0) {
        //0 - from, 1 - to, 2- tmp size, 3 - static size
        asm volatile(
        "loop16_:\n\t"
                "movdqa (%0), %%xmm1\n\t"
                "movdqu %%xmm1, (%1)\n\t"
                "add $16,%0\n\t"
                "add $16,%1\n\t"
                "dec %2\n\t"
                "jnz loop16_\n\t"
        :"+r"(from), "+r"(to), "+r"(tmp)
        :
        :"cc", "memory", "xmm1"
        );
        //from -= old_size;
        //to -= old_size;
    }
    if (ost != 0) {
        memcpy8(from, to, ost);
    }
    size -= ost;
    from += old_size;
    to += old_size;
}
 
int N = 123;
 
int main(int argc, char **argv) {
    char *src = new char[N];
    char *dst = new char[N];
    for (int i = 0; i < N; i++) {
        src[i] = (char) (49 + i);
        dst[i] = 0;
    }
    int qqq = 0;
    memcpy_16_hard(src + 1, dst, N);
    for (int i = 0; i < N; i++) {
        printf("%c %c %d\n", src[i + 1], dst[i], src[i + 1] == dst[i]);
    }
    
    return 0;
}