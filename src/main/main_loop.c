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
