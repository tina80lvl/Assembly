#include <cstdio>
#include <iostream>
#include <nmmintrin.h>
#include <emmintrin.h>
#include <tmmintrin.h>
#include <cassert>
#include <cstdlib>
#include <cstring>
#include <x86intrin.h>
 
using namespace std;

const __m128i BLANK_MASK = _mm_set1_epi8((char) 32);
const __m128i ONE_MASK = _mm_set1_epi8((char) 1);
 
int simple_count(char *src, int size) {
    int result = 0;
    bool word = false;
    for (int i = 0; i < size; i++) {
        if (src[i] != ' ') {
            word = true;
        }
        if (src[i] == ' ' && word) {
            word = false;
            result++;
        }
    }
    if (src[size - 1] != ' ') {
        result++;
    }
    return result;
}
 
int bit_count(__m128i &cur_mask, int &count_l, int &count_r) {
    __m128i value = cur_mask;
    long long int l = (long long int) (reinterpret_cast<uint64_t *> (&value)[0]);
    long long int r = (long long int) (reinterpret_cast< uint64_t *> (&value)[1]);
    count_l += __builtin_popcountll(l);
    count_r += __builtin_popcountll(r);
    cur_mask = _mm_setzero_si128();
    return count_l + count_r;
}

int fast_count(char *src, int size) {
    int tmp_size = size;
    if (size < 32) {
        return simple_count(src, size);
    }
    int result = 0;
    int cycle = size / 16;
    int remainder = size % 16;
    for (int i = 0, offset = 0; i < cycle; i++, offset = i * 16) {
        int l = 0, r = 0;
        __m128i left = _mm_and_si128(_mm_cmpgt_epi8(_mm_loadu_si128((__m128i *) (src + offset - 1)), BLANK_MASK), ONE_MASK);
        __m128i right = _mm_and_si128(_mm_cmpgt_epi8(_mm_loadu_si128((__m128i *) (src + offset)), BLANK_MASK),ONE_MASK);
        __m128i xor_sum = _mm_xor_si128(left, right);
        int cur_space = bit_count(xor_sum, l, r);
        result += (l + r);
    }
    src += (cycle * 16);
    if (src[0] == ' ' && src[-1] != ' ') {
        result += 1;
    }
    result /= 2;
    result += simple_count(src, remainder);
 
    src -= (tmp_size - remainder);
    return result;
}
 #define size 1000000
void simple_Test() {
    char src[] = "mama mila ramu";
    size_t counted = simple_count(src, sizeof src);
    assert(counted == 3);
}
 
void simple_a_lot_of_spaces_Test() {
    char src[] = "        mama          mila       ramu               ";
    size_t counted = simple_count(src, sizeof src);
    assert(counted == 3);
}
 
void fast_Test() {
    char src[] = "mama mila ramu";
    size_t counted = fast_count(src, sizeof src);
    assert(counted == 3);
}
 
void fast_a_lot_of_spaces_Test() {
    char src[] = "                              baq  mq  pmq papp  e           lxdakix p q iwa   mtwi  gcdvvv s   p f  rae g ma pu q g clviu r  kv ntf  sc       ";
    size_t counted = fast_count(src, sizeof src);
    assert(counted == simple_count(src, sizeof src));
}
 
void fast_a_with_lot_of_spaces_Test() {
    char src[] = "               aaaaaaaaaaaaaaa                ";
    size_t counted = fast_count(src, sizeof src);
    assert(counted == 1);
}
 
void fast_a_with_lot_of_spaces_and_shifted_Test() {
    char src[] = "               aaaaaaaaaaaaaaa                ";
    size_t counted = fast_count(src + 1, sizeof src - 1);
    assert(counted == 1);
}
 
void fast_18_a_with_lot_of_spaces_Test() {
    char src[] = "              aaaaaaaaaaaaaaaaa               ";
    size_t counted = fast_count(src, sizeof src);
    assert(counted == 1);
}
 
void fast_rand_Test() {
    srand(time(0));
    char src[size + 1];
    for (int i = 0; i < size; ++i) {
        int space = rand() % 100;
        if (space < 60) {
            src[i] = char(rand() % ('z' - 'a') + 'a');
        } else {
            src[i] = ' ';
        }
 
    }
    src[size] = '\0';
 
    size_t counted = fast_count(src, sizeof src);
 
    assert(counted == simple_count(src, sizeof src));
}
 
void fast_burn_Test() {
    srand(time(0));
 
    for (int i = 0; i < 100; ++i) {
        char src[size + 1];
        for (int i = 0; i < size; ++i) {
            int space = rand() % 100;
            if (space < 60) {
                src[i] = char(rand() % ('z' - 'a') + 'a');
            } else {
                src[i] = ' ';
            }
 
        }
        src[size] = '\0';
        // printf("%s\n", src);
        size_t counted_fast = fast_count(src, sizeof src);
 
        size_t counted_simple = simple_count(src, sizeof src);
        assert(counted_fast == counted_simple);
    }
}


// void test1() {
//     string a = "Will you ever come back? ";
//     for (int i = 0; i < 13; i++) {
//         a += "yes ";
//         a += "oh no ";
//     }
//     cout << a << "\n";
//     char *aa = (char *) a.c_str();
//     cout << simple_count(aa, a.size()) << " " << fast_count(aa, a.size()) << "\n";
// }
 
// void test2() {
//     string a = "I will leave the light on! ";
//     for (int i = 0; i < 59; i++) {
//         a += "pam pararam pam ";
//         a += "tam ";
//     }
//     cout << a << "\n";
//     char *aa = (char *) a.c_str();
//     cout << simple_count(aa, a.size()) << " " << fast_count(aa, a.size()) << "\n";
// }
 
// void test3() {
//     string a = "";
//     for (int i = 0; i < 228; i++) {
//         a += "o";
//     }
//     cout << a << "\n";
//     char *aa = (char *) a.c_str();
//     cout << simple_count(aa, a.size()) << " " << fast_count(aa, a.size()) << "\n";
// }

// void test_rand() {
//     string a = "";
//     for (int i = 0; i < 228; i++) {
//         a += "i";
//         if (rand() % 17 == 5) 
//             a += " ";
//     }
//     cout << a << "\n";
//     char *aa = (char *) a.c_str();
//     cout << simple_count(aa, a.size()) << " " << fast_count(aa, a.size()) << "\n";
// }

// void user_test() {
//     string a;
//     getline(cin, a);
//     char *aa = (char *) a.c_str();
//     cout << simple_count(aa, a.size()) << " " << fast_count(aa, a.size()) << "\n";
// }

int main(int argc, char **argv) {
    // test1();
    // test2();
    // test3();
    // test_rand();
    // user_test();

    fast_burn_Test();
    fast_rand_Test();
    fast_18_a_with_lot_of_spaces_Test();
    fast_a_with_lot_of_spaces_Test();
    fast_a_with_lot_of_spaces_and_shifted_Test();
    fast_a_lot_of_spaces_Test();
    fast_Test();
    simple_Test();
    simple_a_lot_of_spaces_Test();

    return 0;
}