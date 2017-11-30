# lua-nbdserver

simple nbd server in less than 100 lines

## Test

### Run server
```
tarantool nbd.lua
```

### Consume from the client
```ipython

In [2]: import nbdclient

In [3]: cl = nbdclient.nbd_client("0.0.0.0", 17000)
DONE HERE

In [4]: cl.read(0, 512)
SENDING HEADER IS  b'%`\x95\x13\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00' 28
>>>GOT REPLY: reply b'gDf\x98\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
>>>>>MAGIC:  1732535960 errno:  0 HANDLE:  0
Out[4]: b'\x00hello from this cute \n\nlovely\nawesome\n\nharsh \ncruel world\n'

In [5]: 

In [5]: 

In [5]: cl.write(b"ahmed"*512, 512)
SENDING HEADER IS  b'%`\x95\x13\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\n\x00' 28
SENDING:  b'%`\x95\x13\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\n\x00'
HEADER SENT..
>>>GOT REPLY: reply b'gDf\x98\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01'
>>>>>MAGIC:  1732535960 errno:  0 HANDLE:  1

Out[5]: 0

In [6]: cl.close()
SENDING HEADER IS  b'%`\x95\x13\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00' 28

```

### Logs on the server
you should see logging messages on on the requests

```
root@ubuntumachine:/opt/luanbdserver# tarantool nbd.lua 
started
entering the event loop
MAGIC SENT
RECEIVED HEADER:        %`�      LEN HEADER:    28
MAGIC:  25609513         REQUEST:       0       HANDLE:         OFFSET: 0 DLEN:    512
read    0x00000000      0x00000200      1512052087
RECEIVED HEADER:        %`�
         LEN HEADER:    28
MAGIC:  25609513         REQUEST:       1       HANDLE:         OFFSET: 512DLEN:   2560
write   0x00000200      0x00000a00      1512052095
RECEIVED HEADER:        %`�      LEN HEADER:    28
MAGIC:  25609513         REQUEST:       2       HANDLE:         OFFSET: 0 DLEN:    0

```