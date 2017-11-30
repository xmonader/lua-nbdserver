#!/usr/bin/python
-- import struct, socket, sys, time
-- # Working: nbd protocol, read/write serving up files, error handling, file size detection, in theory, large file support... not really, so_reuseaddr, nonforking

local struct = require("struct")


local afile = io.open("test.out", 'rb+')
local socket = require("socket")
local host = "0.0.0.0"
local port = 17000

local onrequest = function(clientsock)
    
    while true do
        READ, WRITE, CLOSE = 0,1,2
        afile:seek('set', 2)
        -- >Q unsigned long long BIG ENDIAN

        --   >LL8sQL   unsigned long + unsigned long + 8 characters + unsigned long long + unsigned long.
        --   c8 means 8 chars 

        --   size of header is 77
        -- seek = tells if called with no arguments.
        local nbdmagic = 'NBDMAGIC\x00\x00\x42\x02\x81\x86\x12\x53' .. struct.pack('>Q', afile:seek()) .. string.rep('\0',128)
        clientsock:send(nbdmagic)

        while true do
            --   header = recvall(clientsock, struct.calcsize('>LLc8QL'))
            --   header = recvall(clientsock, struct.calcsize('>LLQQL'))

            header = clientsock:read(28)
            print("RECEIVED HEADER: ", header)
            magic, request, handle, offset, dlen = struct.unpack('>LLc8QL', header)
            print("MAGIC: ", magic, " REQUEST: ", request,  "HANDLE:" , handle, "OFFSET:", offset, "DLEN:", dlen)
            -- assert(magic == 0x25609513, "MAGIC doesnt equal 0x25609513")
            if request == READ then
                afile:seek('set',offset)
                clientsock:send('gDf\x98\0\0\0\0'..handle)
                clientsock:send(afile.read(dlen))
                print(string.format("read\t0x%08x\t0x%08x", offset, dlen), os.time())
            elseif request == WRITE then
                afile:seek('set', offset)
                -- afile:write(recvall(clientsock, dlen))
                afile:write(clientsock:read(dlen))
                afile:flush()
                clientsock.send('gDf\x98\0\0\0\0'..handle)
                print(string.format("write\t0x%08x\t0x%08x",offset, dlen), os.time())
            elseif request == CLOSE then
                clientsock:close()
                print "closed"
                return
            else
                print("ignored request", request)
            end
        end
    end
end

socket.tcp_server(host, port, onrequest)