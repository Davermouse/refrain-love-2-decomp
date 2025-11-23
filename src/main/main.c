#include "common.h"

const char SECTION(".rodata") s_out_of_memory[] = "out of memory";

const char SECTION(".sdata") s_boot[] = "_BOOT";

const s16 SECTION(".sdata") initial_global_data[] = {
    0xe58e,
    0x6c90,
    0xf68c
};

/*

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
    
*/

INCLUDE_ASM("asm/main/nonmatchings/main", main);

INCLUDE_ASM("asm/main/nonmatchings/main", gs_sync_callback);

INCLUDE_ASM("asm/main/nonmatchings/main", update_cached_input);

INCLUDE_ASM("asm/main/nonmatchings/main", func_80012A18);

INCLUDE_ASM("asm/main/nonmatchings/main", func_80012A50);

INCLUDE_ASM("asm/main/nonmatchings/main", set_gs_callback);
