#!/bin/bash -e
echo "Compiling"
gcc record.c -lm 
//修改了一点点
echo "Running vm"
./a.out BACKING_STORE.bin addresses.txt > out.txt
echo "Comparing with correct.txt"
diff out.txt correct.txt
