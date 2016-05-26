from libc.stdint cimport *
from libc.string cimport *

cdef char * read_stream(object input, int size):
    return input.read(size)

cdef int32_t get_varint32(object input):
    """
    Deserialize a protobuf varint read from input stream; update
    offset based on number of bytes consumed.
    """
    cdef int32_t value = 0
    cdef int32_t base = 1
    cdef int index = 0
    cdef int val_byte

    while True:
        val_byte = read_stream(input, 1)[0]
        value += (val_byte & 0x7F) * base
        if (val_byte & 0x80):
            base *= 128
            index += 1
        else:
            input.add_offset(index + 1)
            return value


cdef int64_t get_varint64(object input):
    """
    Deserialize a protobuf varint read from input stream; update
    offset based on number of bytes consumed.
    """
    cdef int64_t value = 0
    cdef int64_t base = 1
    cdef int index = 0
    cdef int val_byte

    while True:
        val_byte = read_stream(input, 1)[0]
        value += (val_byte & 0x7F) * base
        if (val_byte & 0x80):
            base *= 128
            index += 1
        else:
            input.add_offset(index + 1)
            return value


cdef int32_t get_signed_varint32(object input):
    """
    Deserialize a signed protobuf varint read from input stream;
    update offset based on number of bytes consumed.
    """
    cdef uint32_t value = 0
    cdef int32_t base = 1
    cdef int index = 0
    cdef int val_byte

    while True:
        val_byte = read_stream(input, 1)[0]
        value += (val_byte & 0x7F) * base
        if (val_byte & 0x80):
            base *= 128
            index += 1
        else:
            input.add_offset(index + 1)
            return <int32_t>((value >> 1) ^ (-(value & 1))) # zigzag decoding


cdef int64_t get_signed_varint64(object input):
    """
    Deserialize a signed protobuf varint read from input stream;
    update offset based on number of bytes consumed.
    """
    cdef uint64_t value = 0
    cdef int64_t base = 1
    cdef int index = 0
    cdef int val_byte

    while True:
        val_byte = read_stream(input, 1)[0]
        value += (val_byte & 0x7F) * base
        if (val_byte & 0x80):
            base *= 128
            index += 1
        else:
            input.add_offset(index + 1)
            return <int64_t>((value >> 1) ^ (-(value & 1))) # zigzag decoding


cdef int set_varint32(int32_t varint, bytearray buf):
    """
    Serialize an integer into a protobuf varint; return the number of bytes
    serialized.
    """

	# Negative numbers are always 10 bytes, so we need a uint64_t to
    # facilitate encoding
    cdef uint64_t enc = varint
    bits = enc & 0x7f
    enc >>= 7
    cdef int idx = 1
    while enc:
        buf.append(<unsigned char>(0x80|bits))
        bits = enc & 0x7f
        enc >>= 7
        idx += 1
    buf.append(<unsigned char>bits)
    return idx + 1

cdef int set_varint64(int64_t varint, bytearray buf):
    """
    Serialize an integer into a protobuf varint; return the number of bytes
    serialized.
    """

    # Negative numbers are always 10 bytes, so we need a uint64_t to
    # facilitate encoding
    cdef uint64_t enc = varint
    bits = enc & 0x7f
    enc >>= 7
    cdef int idx = 1
    while enc:
        buf.append(<unsigned char>(0x80|bits))
        bits = enc & 0x7f
        enc >>= 7
        idx += 1
    buf.append(<unsigned char>bits)
    return idx + 1

def to_varint(varint):
    buf = bytearray()
    set_varint64(varint, buf)
    return buf


cdef int set_signed_varint32(int32_t varint, bytearray buf):
    """
    Serialize an integer into a signed protobuf varint; return the number of
    bytes serialized.
    """
    cdef uint32_t enc
    cdef int idx = 1

    enc = (varint << 1) ^ (varint >> 31) # zigzag encoding
    bits = enc & 0x7f
    enc >>= 7
    while enc:
        buf.append(<unsigned char>(bits | 0x80))
        bits = enc & 0x7f
        enc >>= 7
        idx += 1

    buf.append(<unsigned char>bits)
    return idx + 1


cdef int set_signed_varint64(int64_t varint, bytearray buf):
    """
    Serialize an integer into a signed protobuf varint; return the number of
    bytes serialized.
    """
    cdef uint64_t enc
    cdef int idx = 1

    enc = (varint << 1) ^ (varint >> 63) # zigzag encoding
    bits = enc & 0x7f
    enc >>= 7
    while enc:
        buf.append(<unsigned char>(bits | 0x80))
        bits = enc & 0x7f
        enc >>= 7
        idx += 1

    buf.append(<unsigned char>bits)
    return idx + 1


def to_signed_varint(varint):
    buf = bytearray()
    set_signed_varint64(varint, buf)
    return buf