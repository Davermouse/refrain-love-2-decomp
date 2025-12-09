#include "common.h"

#include <psyq/malloc.h>

extern ulong* g_heap_start; 

void DoInitHeap() {
    long length = 0x113b70;
    InitHeap2((ulong *)&g_heap_start, length);
}
