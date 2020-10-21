--
--------------------------------------------------------------------------------
--  FILE:  map_encoder.lua
--  DESCRIPTION:  protoc-gen-lua
--      Google's Protocol Buffers project, ported to lua.
--      https://code.google.com/p/protoc-gen-lua/
--
--      Copyright (c) 2010 , 林卓毅 (Zhuoyi Lin) netsnail@gmail.com
--      All rights reserved.
--
--      Use, modification and distribution are subject to the "New BSD License"
--      as listed at <url: http://www.opensource.org/licenses/bsd-license.php >.
--
--  COMPANY:  NetEase
--  CREATED:  2010年07月29日 19时30分46秒 CST
--------------------------------------------------------------------------------
--
package.path = package.path .. ';../protobuf/?.lua'
package.cpath = package.cpath .. ';../protobuf/?.so'


local string = string
local table = table
local ipairs = ipairs
local pairs = pairs
local assert =assert
local print = print


local pb = require "pb"
local wire_format = require "wire_format"
local descriptor = require "descriptor"
local FieldDescriptor = descriptor.FieldDescriptor

local map_encoder = {}
setmetatable(map_encoder,{__index = _G})
local _ENV = map_encoder


function _MapVarintSize(value)
    if value <= 0x7f then return 1 end
    if value <= 0x3fff then return 2 end
    if value <= 0x1fffff then return 3 end
    if value <= 0xfffffff then return 4 end
    if value <= 0x7ffffffff then return 5 end
    if value <= 0x3ffffffffff then return 6 end
    if value <= 0x1ffffffffffff then return 7 end
    if value <= 0xffffffffffffff then return 8 end
    if value <= 0x7fffffffffffffff then return 9 end
    return 10
end

function _MapSignedVarintSize(value)
    if value < 0 then return 10 end
    if value <= 0x7f then return 1 end
    if value <= 0x3fff then return 2 end
    if value <= 0x1fffff then return 3 end
    if value <= 0xfffffff then return 4 end
    if value <= 0x7ffffffff then return 5 end
    if value <= 0x3ffffffffff then return 6 end
    if value <= 0x1ffffffffffff then return 7 end
    if value <= 0xffffffffffffff then return 8 end
    if value <= 0x7fffffffffffffff then return 9 end
    return 10
end
------------------------ map element --------------------------
function _SimpleMapElemetSizer(compute_value_size)
    return function(value)
            return compute_value_size(value)
    end
end

function _ModifiedMapElementSizer(compute_value_size, modify_value)
    return function (value)
        return compute_value_size(modify_value(value))
    end
end

function _FixedMapElementSizer(value_size)
    return function(value)
        return value_size
    end
end

Int32MapSizer = _SimpleMapElemetSizer(_MapSignedVarintSize)
Int64MapSizer = Int32MapSizer
EnumMapSizer = Int32MapSizer

UInt32MapSizer = _SimpleMapElemetSizer(_MapVarintSize)
UInt64MapSizer = UInt32MapSizer 

SInt32MapSizer = _ModifiedMapElementSizer(_MapSignedVarintSize, wire_format.ZigZagEncode)
SInt64MapSizer = SInt32MapSizer

Fixed32MapSizer = _FixedMapElementSizer(4) 
SFixed32MapSizer = Fixed32MapSizer
FloatMapSizer = Fixed32MapSizer

Fixed64MapSizer = _FixedMapElementSizer(8) 
SFixed64MapSizer = Fixed64MapSizer
DoubleMapSizer = Fixed64MapSizer

BoolMapSizer = _FixedMapElementSizer(1)

EN_CODER_TYPE_TO_MAP_SIZER = {
    [FieldDescriptor.TYPE_DOUBLE] = DoubleMapSizer,
    [FieldDescriptor.TYPE_FLOAT] = FloatMapSizer,
    [FieldDescriptor.TYPE_INT64] = Int64MapSizer,
    [FieldDescriptor.TYPE_UINT64] = UInt64MapSizer,
    [FieldDescriptor.TYPE_INT32] = Int32MapSizer,
    [FieldDescriptor.TYPE_FIXED64] = Fixed64MapSizer,
    [FieldDescriptor.TYPE_FIXED32] = Fixed32MapSizer,
    [FieldDescriptor.TYPE_BOOL] = BoolMapSizer,
    [FieldDescriptor.TYPE_STRING] = StringMapSizer,
    [FieldDescriptor.TYPE_GROUP] = GroupMapSizer,
    [FieldDescriptor.TYPE_MESSAGE] = MessageMapSizer,
    [FieldDescriptor.TYPE_BYTES] = BytesMapSizer,
    [FieldDescriptor.TYPE_UINT32] = UInt32MapSizer,
    [FieldDescriptor.TYPE_ENUM] = EnumMapSizer,
    [FieldDescriptor.TYPE_SFIXED32] = SFixed32MapSizer,
    [FieldDescriptor.TYPE_SFIXED64] = SFixed64MapSizer,
    [FieldDescriptor.TYPE_SINT32] = SInt32MapSizer,
    [FieldDescriptor.TYPE_SINT64] = SInt64MapSizer
}




------------------------ map element --------------------------

function StringMapSizer(field_number, is_repeated, is_packed)
    return function(value)
        local l = #value
        local result = result + VarintSize(l) + l
        return result
    end
end

function BytesMapSizer(field_number, is_repeated, is_packed)
    return function (value)
            local l = #value
            local result = result + VarintSize(l) + l
        return result
    end
end


-- ====================================================================
--  Encoders!

local _EncodeVarint = pb.varint_encoder
local _EncodeSignedVarint = pb.signed_varint_encoder


function _VarintMapBytes(value)
    local out = {}
    local write = function(value)
        out[#out + 1 ] = value
    end
    _EncodeSignedVarint(write, value)
    return table.concat(out)
end

function TagMapBytes(field_number, wire_type)
  return _VarintMapBytes(wire_format.PackTag(field_number, wire_type))
end

function _SimpleMapEncoder(wire_type, encode_value, compute_value_size)
    return function(field_number, is_repeated, is_packed)
        local tag_bytes = TagMapBytes(field_number, wire_type)
        return function(write, value)
            write(tag_bytes)
            encode_value(write, value)
        end
    end
end

function _ModifiedMapEncoder(wire_type, encode_value, compute_value_size, modify_value)
    return function (field_number, is_repeated, is_packed)
        local tag_bytes = TagMapBytes(field_number, wire_type)
        return function (write, value)
            write(tag_bytes)
            encode_value(write, modify_value(value))
        end
    end
end

function _StructPackMapEncoder(wire_type, value_size, format)
    return function(field_number, is_repeated, is_packed)
        local struct_pack = pb.struct_pack
        local tag_bytes = TagMapBytes(field_number, wire_type)
        return function (write, value)
            write(tag_bytes)
            struct_pack(write, format, value)
        end
    end
end

Int32MapEncoder = _SimpleMapEncoder(wire_format.WIRETYPE_VARINT, _EncodeSignedVarint, _SignedMapVarintSize)
Int64MapEncoder = Int32MapEncoder
EnumMapEncoder = Int32MapEncoder

UInt32MapEncoder = _SimpleMapEncoder(wire_format.WIRETYPE_VARINT, _EncodeVarint, _VarintSize)
UInt64MapEncoder = UInt32MapEncoder

SInt32MapEncoder = _ModifiedMapEncoder(
    wire_format.WIRETYPE_VARINT, _EncodeVarint, _VarintSize,
    wire_format.ZigZagEncode32)

SInt64MapEncoder = _ModifiedMapEncoder(
    wire_format.WIRETYPE_VARINT, _EncodeVarint, _VarintSize,
    wire_format.ZigZagEncode64)

Fixed32MapEncoder  = _StructPackMapEncoder(wire_format.WIRETYPE_FIXED32, 4, string.byte('I'))
Fixed64MapEncoder  = _StructPackMapEncoder(wire_format.WIRETYPE_FIXED64, 8, string.byte('Q'))
SFixed32MapEncoder = _StructPackMapEncoder(wire_format.WIRETYPE_FIXED32, 4, string.byte('i'))
SFixed64MapEncoder = _StructPackMapEncoder(wire_format.WIRETYPE_FIXED64, 8, string.byte('q'))
FloatMapEncoder    = _StructPackMapEncoder(wire_format.WIRETYPE_FIXED32, 4, string.byte('f'))
DoubleMapEncoder   = _StructPackMapEncoder(wire_format.WIRETYPE_FIXED64, 8, string.byte('d'))


function BoolMapEncoder(field_number, is_repeated, is_packed)
    local false_byte = '\0'
    local true_byte = '\1'
 
    local tag_bytes = TagMapBytes(field_number, wire_format.WIRETYPE_VARINT)
    return function (write, value)
        write(tag_bytes)
        if value then
            return write(true_byte)
        end
        return write(false_byte)
    end

end

function StringMapEncoder(field_number, is_repeated, is_packed)
    local tag = TagMapBytes(field_number, wire_format.WIRETYPE_LENGTH_DELIMITED)
    local EncodeVarint = _EncodeVarint

    return function (write, value)
--            local encoded = value.encode('utf-8')
        write(tag)
        EncodeVarint(write, #value)
        return write(value)
    end

end

function BytesMapEncoder(field_number, is_repeated, is_packed)
    local tag = TagMapBytes(field_number, wire_format.WIRETYPE_LENGTH_DELIMITED)
    local EncodeVarint = _EncodeVarint
    assert(not is_packed)
    return function(write, value)
        write(tag)
        EncodeVarint(write, #value)
        return write(value)
    end
end


function MessageMapEncoder(field_number, is_repeated, is_packed)
    local tag = TagBytes(field_number, wire_format.WIRETYPE_LENGTH_DELIMITED)
    local EncodeVarint = _EncodeVarint
    assert(not is_packed)
    error("map key and value filed Can not be map")
end

TYPE_TO_MAP_ENCODER = {
    [FieldDescriptor.TYPE_DOUBLE] = DoubleMapEncoder,
    [FieldDescriptor.TYPE_FLOAT] = FloatMapEncoder,
    [FieldDescriptor.TYPE_INT64] = Int64MapEncoder,
    [FieldDescriptor.TYPE_UINT64] = UInt64MapEncoder,
    [FieldDescriptor.TYPE_INT32] = Int32MapEncoder,
    [FieldDescriptor.TYPE_FIXED64] = Fixed64MapEncoder,
    [FieldDescriptor.TYPE_FIXED32] = Fixed32MapEncoder,
    [FieldDescriptor.TYPE_BOOL] = BoolMapEncoder,
    [FieldDescriptor.TYPE_STRING] = StringMapEncoder,
    [FieldDescriptor.TYPE_GROUP] = GroupMapEncoder,
    [FieldDescriptor.TYPE_MESSAGE] = MessageMapEncoder,
    [FieldDescriptor.TYPE_BYTES] = BytesMapEncoder,
    [FieldDescriptor.TYPE_UINT32] = UInt32MapEncoder,
    [FieldDescriptor.TYPE_ENUM] = EnumMapEncoder,
    [FieldDescriptor.TYPE_SFIXED32] = SFixed32MapEncoder,
    [FieldDescriptor.TYPE_SFIXED64] = SFixed64MapEncoder,
    [FieldDescriptor.TYPE_SINT32] = SInt32MapEncoder,
    [FieldDescriptor.TYPE_SINT64] = SInt64MapEncoder
}

return map_encoder
