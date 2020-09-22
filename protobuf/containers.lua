--
--------------------------------------------------------------------------------
--  FILE:  containers.lua
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
--  CREATED:  2010年08月02日 16时15分42秒 CST
--------------------------------------------------------------------------------
--

package.path = package.path .. ';../protobuf/?.lua'
package.cpath = package.cpath .. ';../protobuf/?.so'

local descriptor = require "descriptor"

local setmetatable = setmetatable
local table = table
local rawset = rawset
local error = error
local print = print
local type = type
local FieldDescriptor = descriptor.FieldDescriptor

local base = _ENV
local containers = {}
local _ENV = containers

local function _IsSameCppType(map_field_type, param )
    if "number" == type(param) then
        if map_filed_type == FieldDescriptor.CPPTYPE_INT32 or 
           map_filed_type == FieldDescriptor.CPPTYPE_INT64 or 
           map_filed_type == FieldDescriptor.CPPTYPE_UINT32 or 
           map_filed_type == FieldDescriptor.CPPTYPE_UINT64 or 
           map_filed_type == FieldDescriptor.CPPTYPE_DOUBLE or 
           map_filed_type == FieldDescriptor.CPPTYPE_FLOAT or
           map_filed_type == FieldDescriptor.CPPTYPE_ENUM then
           return true
       end
   elseif "boolean" == type(param) then
        if map_field_type == FieldDescriptor.CPPTYPE_BOOL then 
           return true
        end
   elseif "string" == type(param) then
        if map_field_type == FieldDescriptor.CPPTYPE_STRING then 
           return true
        end
   elseif "table" == type(param) then
        if map_field_type == FieldDescriptor.CPPTYPE_MESSAGE then 
           return true
        end
    end
 end


local _RCFC_meta = {
    add = function(self)

        local value = self._message_descriptor._concrete_class()
        if self.is_map then
            return nil 
        end

        local listener = self._listener
        rawset(self, #self + 1, value)
        value:_SetListener(listener)
        if listener.dirty == false then
            listener:Modified()
        end
        return value
    end,
    remove = function(self, key)
        local listener = self._listener
        table.remove(self, key)
        listener:Modified()
    end,
    insert = function(self, key, value)
        if not _IsSameCppType(self.key_type, key) then
               error("map key type error")
        end
        if not _IsSameCppType(self.value_type, value) then
               error("map value type error")
        end
        local listener = self._listener
        rawset(self, key, value)
        if type(value) == "table" then
             value:_SetListener(listener)
        end
        if listener.dirty == false then
            listener:Modified()
        end
        return value
    end,
    __newindex = function(self, key, value)
        error("RepeatedCompositeFieldContainer Can't set value directly")
    end
}
_RCFC_meta.__index = _RCFC_meta

function RepeatedCompositeFieldContainer(listener, message_descriptor)
    local o = {
        _listener = listener,
        _message_descriptor = message_descriptor,
        is_map = message_descriptor["is_map"],
        key_type = message_descriptor["key_type"],  
        value_type = message_descriptor["value_type"]  
    }
    return setmetatable(o, _RCFC_meta)
end

local _RSFC_meta = {
    append = function(self, value)
        self._type_checker(value)
        rawset(self, #self + 1, value)
        self._listener:Modified()
    end,
    remove = function(self, key)
        table.remove(self, key)
        self._listener:Modified()
    end,
    __newindex = function(self, key, value)
        error("RepeatedCompositeFieldContainer Can't set value directly")
    end
}
_RSFC_meta.__index = _RSFC_meta

function RepeatedScalarFieldContainer(listener, type_checker)
    local o = {}
    o._listener = listener
    o._type_checker = type_checker
    return setmetatable(o, _RSFC_meta)
end

return containers
