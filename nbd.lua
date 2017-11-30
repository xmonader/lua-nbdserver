#!/usr/bin/tarantool
-- import struct, socket, sys, time
-- # Working: nbd protocol, read/write serving up files, error handling, file size detection, in theory, large file support... not really, so_reuseaddr, nonforking

local struct = require("struct")
local ffi = require("ffi")


local afile = io.open("test.out", 'rb+')
local socket = require("socket")
local host = "0.0.0.0"
local port = 17000


ffi.cdef[[
   #pragma packed(1)
   typedef struct {
     uint32_t  magic;
     uint32_t  request;
     uint64_t  handle;
     uint64_t  offset;
     uint32_t  dlen;
  } nbd_request_t;
    
    
  typedef struct {
	uint32_t magic;
	uint32_t error;
    char handle[8];	
    
   } nbd_reply_t;

   uint32_t htonl(uint32_t hostlong);
   uint16_t htons(uint16_t hostshort); 
   uint32_t ntohl(uint32_t netlong);
   uint16_t ntohs(uint16_t netshort);
   ]]
    

   --[[

        -- >Q unsigned long long BIG ENDIAN
        -- >LL8sQL   unsigned long + unsigned long + 8 characters + unsigned long long + unsigned long.
        --  c8 means 8 chars 
   ]]

local onstart = function(clientsock)
    while true do
        READ, WRITE, CLOSE = 0,1,2
        afile:seek('set', 2)

        local nbdmagic = 'NBDMAGIC\x00\x00\x42\x02\x81\x86\x12\x53' .. struct.pack('>d', afile:seek()) .. string.rep('\0',128)
        clientsock:send(nbdmagic)
        print("MAGIC SENT")

        while true do
            header = clientsock:read(28)
            print("RECEIVED HEADER: ", header, " LEN HEADER: ", #header)
            request_packet = ffi.new("nbd_request_t")
            ffi.copy(request_packet, header, ffi.sizeof(request_packet))
            print(request_packet)
            magic, request, handle, offset, dlen = tonumber(request_packet.magic), tonumber(request_packet.request), tonumber(request_packet.handle), tonumber(request_packet.offset), tonumber(request_packet.dlen)
     
            -- magic, request, handle, offset, dlen = struct.unpack('>LLc8dL', header)
            print("MAGIC: ", string.format("%x", magic), " REQUEST: ", request,  "HANDLE:" , handle, "OFFSET:", offset, "DLEN:", dlen)
            -- # FIXME: why magic is parsed wrong?
            if magic ~= tonumber(string.format("%x", 0x25609513)) then
                print("MAGIC doesnt equal 0x25609513")
            end
            if request == READ then 
                -- TODO: Sounds like a good idea if we can just pack it into a string 
                -- nbd_reply = ffi.new("nbd_reply_t")
                -- nbd_reply.magic = magic
                -- nbd_reply.error = 0
                -- nbd_reply.handle = string.format("%x", handle)

                afile:seek('set', offset)
                local datatosend = afile:read(dlen)
                -- handle is always :: '\x00\x00\x00\x00\x00\x00\x00\x00' 
                clientsock:write('gDf\x98\x00\x00\x00\x00\x00'.. struct.pack(">L", handle))
                clientsock:send(datatosend)

                print(string.format("read\t0x%08x\t0x%08x", offset, dlen), os.time())
            elseif request == WRITE then
                afile:seek('set', offset)
                -- afile:write(recvall(clientsock, dlen))
                afile:write(clientsock:read(dlen))
                afile:flush()
                clientsock.send('gDf\x98\0\0\0\0'..'\x00\x00\x00\x00\x00\x00\x00\x00')--handle
                print(string.format("write\t0x%08x\t0x%08x",offset, dlen), os.time())
            elseif request == CLOSE then
                -- clientsock:close()
                print "closed"
                return
            else
                print("ignored request", request)
            end
        end
    end
end

socket.tcp_server(host, port, onstart)