const std = @import("std");

const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const AudioProcessor = @import("audio.zig").AudioProcessor;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (.leak == gpa.deinit()) {
        std.debug.print("leak detected!\n", .{});
    };

    if (c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_AUDIO) != 0) {
        c.SDL_Log("Init failed: %s", c.SDL_GetError());
        return;
    }
    defer c.SDL_Quit();

    const screen = c.SDL_CreateWindow("colours", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, 100, 100, c.SDL_WINDOW_OPENGL) orelse {
        c.SDL_Log("Screen failed: %s", c.SDL_GetError());
        return;
    };
    defer c.SDL_DestroyWindow(screen);

    const renderer = c.SDL_CreateRenderer(screen, -1, 0) orelse {
        c.SDL_Log("Renderer failed: %s", c.SDL_GetError());
        return;
    };
    defer c.SDL_DestroyRenderer(renderer);

    var audio_processor = AudioProcessor.init();
    defer audio_processor.deinit();
    audio_processor.play();
    
    var quit = false;
    while (!quit) {
        try audio_processor.update();
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }
        _ = c.SDL_RenderClear(renderer);
        c.SDL_RenderPresent(renderer);
        c.SDL_Delay(17);
    }
}
