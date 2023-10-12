pub fn step(v: u3) void {
    const rule = switch (v) {
        0b100...0b111 => return,
        0b010...0b011 => return,
        0b001 => return,
        0b000 => return,
    };
    _ = rule;
}
