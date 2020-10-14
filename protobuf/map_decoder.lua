--
--------------------------------------------------------------------------------
--  FILE:  decoder.lua
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
--  CREATED:  2010年07月29日 19时30分51秒 CST
--------------------------------------------------------------------------------
--

package.path = package.path .. ';../protobuf/?.lua'
package.cpath = package.cpath .. ';../protobuf/?.so'

local string = string
local table = table
local assert = assert
local ipairs = ipairs
local error = error
local print = print

local pb = require "pb"
local encoder = require "encoder"
local wire_format = require "wire_format"

local descriptor = require "descriptor"
local FieldDescriptor = descriptor.FieldDescriptor


local base = _ENV
local map_decoder = {}
local _ENV = map_decoder

local _DecodeVarint = pb.varint_decoder
local _DecodeSignedVarint = pb.signed_varint_decoder

local _DecodeVarint32 = pb.varint_decoder
local _DecodeSignedVarint32 = pb.signed_varint_decoder

ReadTag = pb.read_tag

local function _SimpleMapDecoder(wire_type, decode_value)
    return function(field_number, is_repeated, is_packed, key, new_default)
        local tag_bytes = encoder.TagBytes(field_number, wire_type)
        local tag_len = #tag_bytes
        local sub = string.sub
        return function(buffer, pos, pend, message, field_dict)
                local element, new_pos = decode_value(buffer, pos)
                if sub(buffer, new_pos+1, pos) ~= tag_bytes or new_pos >= pend then
                    if new_pos > pend then
                        error('Truncated message.')
                    end
                    return element, new_pos
                end
        end
    end
end

local function _ModifiedMapDecoder(wire_type, decode_value, modify_value)
    local InnerDecode = function (buffer, pos)
        local result, new_pos = decode_value(buffer, pos)
        return modify_value(result), new_pos
    end
    return _SimpleMapDecoder(wire_type, InnerDecode)
end

local function _StructPackMapDecoder(wire_type, value_size, format)
    local struct_unpack = pb.struct_unpack

    function InnerDecode(buffer, pos)
        local new_pos = pos + value_size
        local result = struct_unpack(format, buffer, pos)
        return result, new_pos
    end
    return _SimpleMapDecoder(wire_type, InnerDecode)
end

local function _Boolean(value)
    return value ~= 0
end

Int32MapDecoder = _SimpleMapDecoder(wire_format.WIRETYPE_VARINT, _DecodeSignedVarint32)
EnumMapDecoder = Int32MapDecoder

Int64MapDecoder = _SimpleMapDecoder(wire_format.WIRETYPE_VARINT, _DecodeSignedVarint)

UInt32MapDecoder = _SimpleMapDecoder(wire_format.WIRETYPE_VARINT, _DecodeVarint32)
UInt64MapDecoder = _SimpleMapDecoder(wire_format.WIRETYPE_VARINT, _DecodeVarint)

SInt32MapDecoder = _ModifiedMapDecoder(wire_format.WIRETYPE_VARINT, _DecodeVarint32, wire_format.ZigZagDecode32)
SInt64MapDecoder = _ModifiedMapDecoder(wire_format.WIRETYPE_VARINT, _DecodeVarint, wire_format.ZigZagDecode64)

Fixed32MapDecoder  = _StructPackMapDecoder(wire_format.WIRETYPE_FIXED32, 4, string.byte('I'))
Fixed64MapDecoder  = _StructPackMapDecoder(wire_format.WIRETYPE_FIXED64, 8, string.byte('Q'))
SFixed32MapDecoder = _StructPackMapDecoder(wire_format.WIRETYPE_FIXED32, 4, string.byte('i'))
SFixed64MapDecoder = _StructPackMapDecoder(wire_format.WIRETYPE_FIXED64, 8, string.byte('q'))
FloatMapDecoder    = _StructPackMapDecoder(wire_format.WIRETYPE_FIXED32, 4, string.byte('f'))
DoubleMapDecoder   = _StructPackMapDecoder(wire_format.WIRETYPE_FIXED64, 8, string.byte('d'))


BoolMapDecoder = _ModifiedMapDecoder(wire_format.WIRETYPE_VARINT, _DecodeVarint, _Boolean)


function StringMapDecoder(field_number, is_repeated, is_packed, key, new_default)
    local DecodeVarint = _DecodeVarint
    local sub = string.sub
    --    local unicode = unicode
    assert(not is_packed)
    local tag_bytes = encoder.TagBytes(field_number, wire_format.WIRETYPE_LENGTH_DELIMITED)
    local tag_len = #tag_bytes
    return function (buffer, pos, pend, message, field_dict)
        local value = field_dict[key]
        if value == nil then
            value = new_default(message)
            field_dict[key] = value
        end
        while 1 do
            local size, new_pos
            size, pos = DecodeVarint(buffer, pos)
            new_pos = pos + size
            if new_pos > pend then
                error('Truncated string.')
            end
            value:append(sub(buffer, pos+1, new_pos))
            pos = new_pos + tag_len
            if sub(buffer, new_pos + 1, pos) ~= tag_bytes or new_pos == pend then
                return new_pos
            end
        end
    end
end

function BytesMapDecoder(field_number, is_repeated, is_packed, key, new_default)
    local DecodeVarint = _DecodeVarint
    local sub = string.sub
    assert(not is_packed)
    local tag_bytes = encoder.TagBytes(field_number, wire_format.WIRETYPE_LENGTH_DELIMITED)
    local tag_len = #tag_bytes
    return function (buffer, pos, pend, message, field_dict)
        local value = field_dict[key]
        if value == nil then
            value = new_default(message)
            field_dict[key] = value
        end
        while 1 do
            local size, new_pos
            size, pos = DecodeVarint(buffer, pos)
            new_pos = pos + size
            if new_pos > pend then
                error('Truncated string.')
            end
            value:append(sub(buffer, pos + 1, new_pos))
            pos = new_pos + tag_len
            if sub(buffer, new_pos + 1, pos) ~= tag_bytes or new_pos == pend then
                return new_pos
            end
        end
    end
end

function MessageMapDecoder(field_number, is_repeated, is_packed, key, new_default)
    local DecodeVarint = _DecodeVarint
    local sub = string.sub
    local is_map = key["is_map"]

    assert(not is_packed)

	if is_map == true then
		local tag_bytes = encoder.TagBytes(field_number, wire_format.WIRETYPE_LENGTH_DELIMITED)
        local tag_len = #tag_bytes
        return function (buffer, pos, pend, message, field_dict)
            local value = field_dict[key]
            if value == nil then
                value = new_default(message)
                field_dict[key] = value
            end
            while 1 do
                local size, new_pos
                size, pos = DecodeVarint(buffer, pos)
                new_pos = pos + size
                if new_pos > pend then
                    error('Truncated message.')
                end
                if value:add():_InternalParse(buffer, pos, new_pos) ~= new_pos then
                    error('Unexpected end-group tag.')
                end
                pos = new_pos + tag_len
                if sub(buffer, new_pos + 1, pos) ~= tag_bytes or new_pos == pend then
                    return new_pos
                end
            end
        end
    end
end

function _SkipVarint(buffer, pos, pend)
    local value
    value, pos = _DecodeVarint(buffer, pos)
    return pos
end

function _SkipFixed64(buffer, pos, pend)
    pos = pos + 8
    if pos > pend then 
        error('Truncated message.')
    end
    return pos
end

function _SkipLengthDelimited(buffer, pos, pend)
    local size
    size, pos = _DecodeVarint(buffer, pos)
    pos = pos + size
    if pos > pend then
        error('Truncated message.')
    end
    return pos
end

function _SkipFixed32(buffer, pos, pend)
    pos = pos + 4
    if pos > pend then
        error('Truncated message.')
    end
    return pos
end

function _RaiseInvalidWireType(buffer, pos, pend)
    error('Tag had invalid wire type.')
end

function _FieldSkipper()
    WIRETYPE_TO_SKIPPER = {
        _SkipVarint,
        _SkipFixed64,
        _SkipLengthDelimited,
        _SkipGroup,
        _EndGroup,
        _SkipFixed32,
        _RaiseInvalidWireType,
        _RaiseInvalidWireType,
    }

--    wiretype_mask = wire_format.TAG_TYPE_MASK
    local ord = string.byte
    local sub = string.sub

    return function (buffer, pos, pend, tag_bytes)
        local wire_type = ord(sub(tag_bytes, 1, 1)) % 8 + 1
        return WIRETYPE_TO_SKIPPER[wire_type](buffer, pos, pend)
    end
end

SkipField = _FieldSkipper()



TYPE_TO_MAP_DECODER = {
    [FieldDescriptor.TYPE_DOUBLE] = DoubleMapDecoder,
    [FieldDescriptor.TYPE_FLOAT] = FloatMapDecoder,
    [FieldDescriptor.TYPE_INT64] = Int64MapDecoder,
    [FieldDescriptor.TYPE_UINT64] = UInt64MapDecoder,
    [FieldDescriptor.TYPE_INT32] = Int32MapDecoder,
    [FieldDescriptor.TYPE_FIXED64] = Fixed64MapDecoder,
    [FieldDescriptor.TYPE_FIXED32] = Fixed32MapDecoder,
    [FieldDescriptor.TYPE_BOOL] = BoolMapDecoder,
    [FieldDescriptor.TYPE_STRING] = StringMapDecoder,
    [FieldDescriptor.TYPE_GROUP] = GroupMapDecoder,
    [FieldDescriptor.TYPE_MESSAGE] = MessageMapDecoder,
    [FieldDescriptor.TYPE_BYTES] = BytesMapDecoder,
    [FieldDescriptor.TYPE_UINT32] = UInt32MapDecoder,
    [FieldDescriptor.TYPE_ENUM] = EnumMapDecoder,
    [FieldDescriptor.TYPE_SFIXED32] = SFixed32MapDecoder,
    [FieldDescriptor.TYPE_SFIXED64] = SFixed64MapDecoder,
    [FieldDescriptor.TYPE_SINT32] = SInt32MapDecoder,
    [FieldDescriptor.TYPE_SINT64] = SInt64MapDecoder
}

return map_decoder
