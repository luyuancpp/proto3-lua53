package.path = package.path .. ';../protobuf/?.lua;'
package.cpath = package.cpath .. ';../protobuf/?.so'

local print = print
local pb3v_pb = require 'pb3v_pb'
local prettyprint = require 'prettyprint'

local person = pb3v_pb.Proto3MessageWithMaps()

person.field_map_int32_message_61:add()
