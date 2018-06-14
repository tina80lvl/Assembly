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
    int result = simple_count(src, 16);
    size -= 16;
    src += 16;
 
    int cycle = size / 16;
    int remainder = size % 16;
    for (int i = 0, offset = 0; i < cycle; i++, offset = i * 16) {
        int l = 0, r = 0;
        __m128i left = _mm_and_si128(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *) (src + offset - 1)), BLANK_MASK), ONE_MASK);
        __m128i right = _mm_and_si128(_mm_cmpeq_epi8(_mm_loadu_si128((__m128i *) (src + offset)), BLANK_MASK),ONE_MASK);
        __m128i xor_sum = _mm_xor_si128(left, right);
        if (src[offset + 7] != ' ' && src[offset + 6] == ' ') {
            l++;
        }
        if (src[offset + 15] != ' ' && src[offset + 14] == ' ') {
            r++;
        }
        int cur_space = bit_count(xor_sum, l, r);
        result += (l / 2 + r / 2);
    }
    src += (cycle * 16);
    if (src[0] != ' ' && src[-1] != ' ') {
        result -= 1;
    }
    result += simple_count(src, remainder);
 
    src -= (tmp_size - remainder);
    return result;
}
 
void test1() {
    string a = "Will you ever come back? ";
    for (int i = 0; i < 13; i++) {
        a += "yes ";
        a += "oh no ";
    }
    cout << a << "\n";
    char *aa = (char *) a.c_str();
    cout << simple_count(aa, a.size()) << " " << fast_count(aa, a.size()) << "\n";
}
 
void test2() {
    string a = "I will leave the light on! ";
    for (int i = 0; i < 59; i++) {
        a += "pam pararam pam ";
        a += "tam ";
    }
    cout << a << "\n";
    char *aa = (char *) a.c_str();
    cout << simple_count(aa, a.size()) << " " << fast_count(aa, a.size()) << "\n";
}
 
 
void test3() {
    string a = "";
    for (int i = 0; i < 228; i++) {
        a += "o";
    }
    cout << a << "\n";
    char *aa = (char *) a.c_str();
    cout << simple_count(aa, a.size()) << " " << fast_count(aa, a.size()) << "\n";
}

void test_rand() {
    string a = "";
    for (int i = 0; i < 228; i++) {
        a += rand() % 288;
        if (rand() % 2) 
            a += " ";
    }
    cout << a << "\n";
    char *aa = (char *) a.c_str();
    cout << simple_count(aa, a.size()) << " " << fast_count(aa, a.size()) << "\n";
}

int main(int argc, char **argv) {
    test1();
    test2();
    test3();
    test_rand();

    return 0;
}