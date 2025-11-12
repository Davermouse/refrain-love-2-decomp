#include <psyq/libetc.h>
#include <psyq/libgpu.h>

#include "common.h"

void main_loop() {
    do
    {
        swap_gfx_buffers();
        func_80013F84();
        func_80020360();
        func_80026C34();
    } while (true);
    
}

int main() {
    s16 v1;
    s16* gfx_state;

    __main();
    ResetCallback();

    DoInitHeap();

    VSync(0);
    ResetGraph(0);

    VSync(0);
    SetDispMask(0);

    VSync(0);
    SetGraphDebug(0);
    PadInit(0);
    
    InitEventsInput();
    EnableEvents();

    func_8002946c(1, 0x1e00, 7, 1);
}

//INCLUDE_ASM("asm/main/nonmatchings/main", main);

INCLUDE_ASM("asm/main/nonmatchings/main", func_80012700);

INCLUDE_ASM("asm/main/nonmatchings/main", update_cached_input);

INCLUDE_ASM("asm/main/nonmatchings/main", func_80012A18);

INCLUDE_ASM("asm/main/nonmatchings/main", func_80012A50);

INCLUDE_ASM("asm/main/nonmatchings/main", func_80012A64);
