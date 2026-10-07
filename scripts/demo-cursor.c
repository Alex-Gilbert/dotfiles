// Read-only cursor telemetry for the selected output; no surfaces or input grabs.
#define _POSIX_C_SOURCE 200809L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <wayland-client.h>
#include "ext-image-capture-source-v1.h"
#include "ext-image-copy-capture-v1.h"

static const char *output_name;
static struct wl_output *output;
static struct wl_seat *seat;
static struct wl_pointer *pointer;
static struct ext_output_image_capture_source_manager_v1 *sources;
static struct ext_image_copy_capture_manager_v1 *captures;
static uint32_t output_id, seat_id;

static double now(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1e9;
}

static void enter(void *data, struct ext_image_copy_capture_cursor_session_v1 *session) {}
static void leave(void *data, struct ext_image_copy_capture_cursor_session_v1 *session) {
    printf("{\"time\":%.9f,\"leave\":true}\n", now());
}
static void position(void *data, struct ext_image_copy_capture_cursor_session_v1 *session,
                     int32_t x, int32_t y) {
    printf("{\"time\":%.9f,\"x\":%d,\"y\":%d}\n", now(), x, y);
}
static void hotspot(void *data, struct ext_image_copy_capture_cursor_session_v1 *session,
                    int32_t x, int32_t y) {}
static const struct ext_image_copy_capture_cursor_session_v1_listener cursor_listener = {
    .enter = enter, .leave = leave, .position = position, .hotspot = hotspot,
};

static void geometry(void *data, struct wl_output *obj, int32_t x, int32_t y,
                     int32_t pw, int32_t ph, int32_t subpixel, const char *make,
                     const char *model, int32_t transform) {}
static void mode(void *data, struct wl_output *obj, uint32_t flags,
                 int32_t width, int32_t height, int32_t refresh) {}
static void done(void *data, struct wl_output *obj) {}
static void scale(void *data, struct wl_output *obj, int32_t factor) {}
static void name(void *data, struct wl_output *obj, const char *value) {
    if (!strcmp(value, output_name)) {
        output = obj;
        output_id = (uint32_t)(uintptr_t)data;
    }
}
static void description(void *data, struct wl_output *obj, const char *value) {}
static const struct wl_output_listener output_listener = {
    .geometry = geometry, .mode = mode, .done = done, .scale = scale,
    .name = name, .description = description,
};
static void capabilities(void *data, struct wl_seat *obj, uint32_t caps) {
    if ((caps & WL_SEAT_CAPABILITY_POINTER) && !pointer) pointer = wl_seat_get_pointer(obj);
}
static void seat_name(void *data, struct wl_seat *obj, const char *value) {}
static const struct wl_seat_listener seat_listener = {
    .capabilities = capabilities, .name = seat_name,
};

static void global(void *data, struct wl_registry *registry, uint32_t id,
                   const char *interface, uint32_t version) {
    if (!strcmp(interface, "wl_output") && version >= 4) {
        struct wl_output *obj = wl_registry_bind(registry, id, &wl_output_interface, 4);
        wl_output_add_listener(obj, &output_listener, (void *)(uintptr_t)id);
    } else if (!strcmp(interface, "wl_seat") && !seat) {
        seat = wl_registry_bind(registry, id, &wl_seat_interface, version < 5 ? version : 5);
        seat_id = id;
        wl_seat_add_listener(seat, &seat_listener, NULL);
    } else if (!strcmp(interface, "ext_output_image_capture_source_manager_v1")) {
        sources = wl_registry_bind(registry, id, &ext_output_image_capture_source_manager_v1_interface, 1);
    } else if (!strcmp(interface, "ext_image_copy_capture_manager_v1")) {
        captures = wl_registry_bind(registry, id, &ext_image_copy_capture_manager_v1_interface, 1);
    }
}
static void removed(void *data, struct wl_registry *registry, uint32_t id) {
    if (id == output_id || id == seat_id) {
        fprintf(stderr, "Capture output or pointer seat disconnected\n");
        exit(1);
    }
}
static const struct wl_registry_listener registry_listener = {
    .global = global, .global_remove = removed,
};

int main(int argc, char **argv) {
    if (argc != 2) { fprintf(stderr, "Usage: demo-cursor OUTPUT\n"); return 2; }
    output_name = argv[1];
    setvbuf(stdout, NULL, _IOLBF, 0);
    struct wl_display *display = wl_display_connect(NULL);
    if (!display) { fprintf(stderr, "Cannot connect to Wayland\n"); return 1; }
    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);
    if (wl_display_roundtrip(display) < 0 || wl_display_roundtrip(display) < 0 ||
        !output || !pointer || !sources || !captures) {
        fprintf(stderr, "Cursor capture requires a pointer, the selected output, and Sway's ext-image-copy-capture protocol\n");
        wl_display_disconnect(display);
        return 1;
    }
    struct ext_image_capture_source_v1 *source =
        ext_output_image_capture_source_manager_v1_create_source(sources, output);
    struct ext_image_copy_capture_cursor_session_v1 *cursor =
        ext_image_copy_capture_manager_v1_create_pointer_cursor_session(captures, source, pointer);
    ext_image_copy_capture_cursor_session_v1_add_listener(cursor, &cursor_listener, NULL);
    if (wl_display_roundtrip(display) < 0) { wl_display_disconnect(display); return 1; }
    puts("{\"ready\":true}");
    while (wl_display_dispatch(display) >= 0) {}
    fprintf(stderr, "Cursor capture disconnected\n");
    wl_display_disconnect(display);
    return 1;
}
