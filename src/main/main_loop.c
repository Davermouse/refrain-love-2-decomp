#include "common.h"

void main_loop() {
    do
    {
        swap_gfx_buffers();
        run_event_loop_and_loop_fn();
        update_display();
        swap_clear_ots();
    } while (true);
}
