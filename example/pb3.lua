package.path = package.path .. ';../protobuf/?.lua;'
package.cpath = package.cpath .. ';../protobuf/?.so'

local print = print
local pb3_pb = require 'pb3_pb'
local prettyprint = require 'prettyprint'



local person = pb3_pb.Proto3MessageWithMaps()
local person1 = pb3_pb.Proto3MessageWithMaps()


person.field_map_bool_bool_1:insert(false, false)
person.field_map_bool_bool_1:insert(true, false)


--print(person.field_map_bool_bool_1:get(true))
--print('==================')
print(person:ByteSize())

local data = person:SerializeToString()
local msg = pb3_pb.Proto3MessageWithMaps()
msg:ParseFromString(data)

print(msg.field_map_bool_bool_1:get(false))
print(msg.field_map_bool_bool_1:get(true))
