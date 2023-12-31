const raylib = @import("raylib");
const KeyboardKey = raylib.KeyboardKey;

// **** KEYS ****

// CALIBRATION
pub const KEY_CALIB_RESET = KeyboardKey.KEY_SPACE;
pub const KEY_CALIB_DONE = KeyboardKey.KEY_ENTER;
pub const KEY_CALIB_DELETE = KeyboardKey.KEY_BACKSPACE;

// CAMERA
pub const KEY_DELTA_WEIGHT_DEC = KeyboardKey.KEY_J;
pub const KEY_DELTA_WEIGHT_INC = KeyboardKey.KEY_K;

// AUDIO

// Decrease/increase threshold for sound triggers
pub const KEY_AUDIO_TRIG_THRESH_DEC = KeyboardKey.KEY_Q;
pub const KEY_AUDIO_TRIG_THRESH_INC = KeyboardKey.KEY_W;

// Adjust how fast activity tracking increases/decreases
pub const KEY_TRACKING_INC_DEC = KeyboardKey.KEY_A;
pub const KEY_TRACKING_INC_INC = KeyboardKey.KEY_S;
pub const KEY_TRACKING_DEC_DEC = KeyboardKey.KEY_D;
pub const KEY_TRACKING_INC = KeyboardKey.KEY_F;

// **** GRAPHICS ****

pub const DEBUG_COLOR = raylib.GREEN;
pub const DEBUG_FONT_SIZE = 25;
pub const DEBUG_GAP = 50;

// **** AUDIO ****

// GLOBAL
pub const SR = 44100;

// TRIGGER
pub const TRIG_THRESHOLD = 100;

pub const TRIG_TRACKING_INC = 0.05;
pub const TRIG_TRACKING_DEC = 0.01;

// SYNTH
pub const N_VOICES = 16;
pub const N_PARTIALS = 8;

pub const MIN_FREQ = 100;
pub const MAX_FREQ = 10_000;

pub const ATTACK = 0.001;
pub const MIN_DECAY = 0.4;
pub const MAX_DECAY = 2;

// DELAY
pub const MAX_DEL_LENGTH = SR * 10;

pub const MIN_DEL_LPF_FREQ = 1000;
pub const MAX_DEL_LPF_FREQ = 10_000;
pub const DEL_LPF_RES = 5.0;

pub const DEL_A_MIN_DEL_TIME = 200;
pub const DEL_A_MAX_DEL_TIME = SR;
pub const DEL_A_FB = 0.85;
pub const DEL_A_MIN_VAR_TIME = SR;
pub const DEL_A_MAX_VAR_TIME = SR * 4;

pub const DEL_B_MIN_DEL_TIME = SR;
pub const DEL_B_MAX_DEL_TIME = SR * 2;
pub const DEL_B_FB = 0.75;
pub const DEL_B_MIN_VAR_TIME = SR * 4;
pub const DEL_B_MAX_VAR_TIME = SR * 16;

pub const DEL_C_MIN_DEL_TIME = SR * 4;
pub const DEL_C_MAX_DEL_TIME = SR * 10;
pub const DEL_C_FB = 0.95;
pub const DEL_C_MIN_VAR_TIME = SR * 16;
pub const DEL_C_MAX_VAR_TIME = SR * 32;
