package.path = package.path .. ';../protobuf/?.lua;'
package.cpath = package.cpath .. ';../protobuf/?.so'

local print = print
local pb3_pb = require 'pb3_pb'
local prettyprint = require 'prettyprint'

local p3mwm = pb3_pb.Proto3MessageWithMaps()
local p3m = pb3_pb.Proto3Message()
p3m.field_uint64_4 =  ((2 << 61) )
p3m.field_int64_3 =  ((2 << 60) )

local p3mss = pb3_pb.Proto3Message()
local p3mdata = p3m:SerializeToString()

p3mss:ParseFromString(p3mdata)
print(string.format("%.u", p3m.field_uint64_4))
print(string.format("%.u", p3mss.field_uint64_4))

if p3m.field_uint64_4 == p3mss.field_uint64_4 then
  print("same")
end

if p3m.field_uint64_4 == p3mss.field_uint64_4 then
  print("same")
end

assert(p3m.field_uint64_4 == p3mss.field_uint64_4, "error")
assert(p3m.field_int64_3 == p3mss.field_int64_3, "error")

