#include "common.h"

#include <psyq/libetc.h>

void set_vsync_callback(void (*f)()) {
    VsyncCallback(f);
}