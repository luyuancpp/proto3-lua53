package.path = package.path .. ';../protobuf/?.lua;'
package.cpath = package.cpath .. ';../protobuf/?.so'

local print = print
local pb3_pb = require 'pb3_pb'
local prettyprint = require 'prettyprint'

local person = pb3_pb.Proto3MessageWithMaps()
local p3m = pb3_pb.Proto3Message()
p3m.field_int32_5 = 5 

person.field_map_bool_bool_1:insert(false, false)
person.field_map_bool_bool_1:insert(true, false)

print("-------------------")
for i = 1 , 10 do 
   person.field_map_int32_int32_59:insert(i,i)
end

person.field_map_int32_message_61:insert(1, p3m)
print("-------------------")

print(person:ByteSize())

local data = person:SerializeToString()
local msg = pb3_pb.Proto3MessageWithMaps()
msg:ParseFromString(data)

print(msg:ByteSize())

for i = 1 , 10 do 
   print(msg.field_map_int32_int32_59:get(i))
end
