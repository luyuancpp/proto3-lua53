package.path = package.path .. ';../protobuf/?.lua;'
package.cpath = package.cpath .. ';../protobuf/?.so'

local print = print
local pb3_pb = require 'pb3_pb'
local prettyprint = require 'prettyprint'


function testassert(a, b)
  if a == nil or b == nil then
     assert(false, "nil")
  end
  if a ~= b then
    print(a)
    print(b)
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
testassert(p3m.field_int32_5, p3mss.field_int32_5)
testassert(p3m.field_int64_3, p3mss.field_int64_3)
testassert(p3m.field_double_1, p3mss.field_double_1)


p3mwm.field_map_bool_bool_1:insert(false, false)
p3mwm.field_map_bool_bool_1:insert(true, false)

for i = 1 , 10 do 
   p3mwm.field_map_int32_int32_59:insert(i,i)
end

local test_int64_b = (2 << 60) 
local test_int64_e = test_int64_b + 1000 
for i = test_int64_b , test_int64_e do 
   p3mwm.field_map_int64_int64_77:insert(i,i)
end
for i = test_int64_b , test_int64_e do 
   p3mwm.field_map_uint64_uint64_204:insert(i,i)
end

p3mwm.field_map_int32_message_61:insert(1, p3m)

local data = p3mwm:SerializeToString()
local p3mwmss = pb3_pb.Proto3MessageWithMaps()
p3mwmss:ParseFromString(data)

testassert(p3mwmss:ByteSize(), p3mwm:ByteSize())

for i = 1 , 10 do 
   testassert(p3mwmss.field_map_int32_int32_59:get(i), p3mwm.field_map_int32_int32_59:get(i))
end

for i = test_int64_b , test_int64_e do 
   testassert(p3mwmss.field_map_int64_int64_77:get(i), p3mwm.field_map_int64_int64_77:get(i))
end

for i = test_int64_b , test_int64_e do 
   testassert(p3mwmss.field_map_uint64_uint64_204:get(i), p3mwm.field_map_uint64_uint64_204:get(i))
end
print("--------------------------")
print(p3mwm.field_map_int32_message_61:get(1).field_uint64_4)
print(p3mwm.field_map_int32_message_61:get(1).field_int32_5)
print(p3mwm.field_map_int32_message_61:get(1).field_int64_3)
print(p3mwm.field_map_int32_message_61:get(1).field_double_1)
print(p3mwmss.field_map_int32_message_61:get(1).field_uint64_4)
print(p3mwmss.field_map_int32_message_61:get(1).field_int32_5)
print(p3mwmss.field_map_int32_message_61:get(1).field_int64_3)
print(p3mwmss.field_map_int32_message_61:get(1).field_double_1)
print("--------------------------")
