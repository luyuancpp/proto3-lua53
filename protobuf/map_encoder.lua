--
--------------------------------------------------------------------------------
--  FILE:  encoder.lua
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
local encoder = require "encoder"

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

Fixed32MapSizer = _FixedMapSizer(4) 
SFixed32MapSizer = Fixed32MapSizer
FloatMapSizer = Fixed32MapSizer

Fixed64MapSizer = _FixedMapElementSizer(8) 
SFixed64MapSizer = Fixed64MapSizer
DoubleMapSizer = Fixed64MapSizer

BoolMapSizer = _FixedMapElementSizer(1)

local EN_CODER_TYPE_TO_MAP_SIZER = {
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

return map_encoder
