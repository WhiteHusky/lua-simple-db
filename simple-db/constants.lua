local NULL = 0x0

local COLUMN_TYPE = {
    BOOLEAN         = 0x1,
    SIGNED_BYTE     = 0x2,
    UNSIGNED_BYTE   = 0x3,
    SIGNED_SHORT    = 0x4,
    UNSIGNED_SHORT  = 0x5,
    SIGNED_LONG     = 0x6,
    UNSIGNED_LONG   = 0x7,
    FLOAT           = 0x8,
    DOUBLE          = 0x9,
    CHAR_STRING     = 0xA,
    SHORT_STRING    = 0xB,
    LONG_STRING     = 0xC
}

local RECORD_ID_TYPE = {
    SHORT_RECORD_ID = COLUMN_TYPE.UNSIGNED_SHORT,
    LONG_RECORD_ID  = COLUMN_TYPE.UNSIGNED_LONG
}

local RECORD_TYPE = {
    NULL = NULL
}

return {
    NULL            = NULL,
    COLUMN_TYPE     = COLUMN_TYPE,
    RECORD_ID_TYPE  = RECORD_ID_TYPE,
    RECORD_TYPE     = RECORD_TYPE
}