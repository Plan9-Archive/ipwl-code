FMT_8BIT_MONO_STREAM	:= array [] of {byte 16r00, byte 16r00, byte 16r10, byte 16r10};
FMT_16BIT_MONO_STREAM	:= array [] of {byte 16r00, byte 16r00, byte 16r10, byte 16r11};
FMT_8BIT_STEREO_STREAM	:= array [] of {byte 16r00, byte 16r00, byte 16r10, byte 16r20};
FMT_16BIT_STEREO_STREAM	:= array [] of {byte 16r00, byte 16r00, byte 16r10, byte 16r21};

OPCODE_INIT		:= array [] of {byte 0, byte 0, byte 0, byte 0};
OPCODE_STREAM		:= array [] of {byte 0, byte 0, byte 0, byte 3};
OPCODE_RESPONSE		:= array [] of {byte 0, byte 0, byte 0, byte 1};

RATE_44100		:= array [] of {byte ((44100>>24)&16rFF),
				byte ((44100>>16)&16rFF),
				byte ((44100>>8)&16rFF),
				byte ((44100>>0)&16rFF)};

RATE_22050		:= array [] of {byte ((22050>>24)&16rFF),
				byte ((22050>>16)&16rFF),
				byte ((22050>>8)&16rFF),
				byte ((22050>>0)&16rFF)};

ESD_KEY			:= array [16] of {* => byte 0};
ESD_ENDIAN		:= array [] of {byte 'E', byte 'N', byte 'D', byte 'N'};
ESD_NAME		:= array [128] of {* => byte 0};

ESD_ENDIAN_LEN		: con 4;
ESD_FMT_LEN		: con 4;
ESD_KEY_LEN		: con 16;
ESD_NAME_LEN		: con 128;
ESD_OPCODE_LEN		: con 4;
ESD_RATE_LEN		: con 4;

ESD_PORT		: con 16001;
