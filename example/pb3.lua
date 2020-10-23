package.path = package.path .. ';../protobuf/?.lua;'
package.cpath = package.cpath .. ';../protobuf/?.so'

local print = print
local pb3_pb = require 'pb3_pb'
local prettyprint = require 'prettyprint'


function testassert(a, b)
  if a == b then
     print("same")
  end
  assert(a == b, "error")
end

local p3mwm = pb3_pb.Proto3MessageWithMaps()
local p3m = pb3_pb.Proto3Message()
p3m.field_double_1 = 1.88
p3m.field_int32_5 = 5 
p3m.field_uint64_4 =  ((2 << 61) )
p3m.field_int64_3 =  ((2 << 60) )

local p3mss = pb3_pb.Proto3Message()
local p3mdata = p3m:SerializeToString()

p3mss:ParseFromString(p3mdata)
print(string.format("%.u", p3m.field_uint64_4))
print(string.format("%.u", p3mss.field_uint64_4))

testassert(p3m.field_uint64_4, p3mss.field_uint64_4)
testassert(p3m.field_uint64_4, p3mss.field_uint64_4)
testassert(p3m.field_double_1, p3mss.ield_double_1)


p3mwm.field_map_bool_bool_1:insert(false, false)
p3mwm.field_map_bool_bool_1:insert(true, false)

for i = 1 , 10 do 
   p3mwm.field_map_int32_int32_59:insert(i,i)
end

p3mwm.field_map_int32_message_61:insert(1, p3m)


local data = p3mwm:SerializeToString()
local p3mwmss = pb3_pb.Proto3MessageWithMaps()
p3mwmss:ParseFromString(data)

print(p3mwmss:ByteSize())

assert(p3mwmss:ByteSize() == p3mwm:ByteSize(), "pb sizer error")

for i = 1 , 10 do 
   print(p3mwmss.field_map_int32_int32_59:get(i))
end



print(p3mwmss.field_map_int32_message_61:get(1).field_int32_5)
