make -f Makefile.xcelium hw_reset

Register Map
------------
```
Offset  Name        	Description
----------------------------------------------------
0x00    SCRATCH         Non-volatile register
0x04    FIFO            FIFO register
0x08    FIFO_STATUS     FIFO status register
0x0C    GPIO            GPIO register
0x10    TIMER           Timer Register
0x14    INTERRUPT       Interrupt Register
```


SCRATCH Register
----------------
```
Bits	Name	Description							Type	Reset	Volatile
----------------------------------------------------------------------------
 31:0   SCRATCH Non-volatile register field.        RW      0x0     FALSE
```


FIFO Register
-------------
```
Bits	Name	Description							Type	Reset	Volatile
----------------------------------------------------------------------------
 31:0   DATA    A write pushes data into the FIFO.  RW      0x0     TRUE
                A read pops data from the FIFO
                and returns it.
```


FIFO_STATUS Register
--------------------
```
Bits	Name	Description							Type	Reset	Volatile
----------------------------------------------------------------------------
    0   EMPTY   1 means FIFO is empty               RO      0x1     TRUE
    8   FULL    1 means FIFO is full                RO      0x0     TRUE
23:16   COUNT   Count of data words in FIFO         RO      0x00    TRUE
```


GPIO Register
-------------
```
Bits    Name    Description                         Type    Reset   Volatile
----------------------------------------------------------------------------
  7:0   VALUE   A write drives value onto GPO pins. RW      0x0     TRUE
                A read returns value from GPI pins.
```


TIMER Register
--------------
```
Bits	Name	Description							Type	Reset	Volatile
----------------------------------------------------------------------------
 15:0   TIMER   Write loads counter which then      RW      0x0     TRUE
                counts down to 0.
                Read returns current counter value.
```


INTERRUPT Register
------------------
```
Bits	Name	Description							Type	Reset	Volatile
----------------------------------------------------------------------------
    0   EXPIRED 1 means TIMER expired.              RC      0x0     TRUE
                Clears on read.
```
