import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
import gym
import sys
import matplotlib.pyplot as plt
import random


MAXAddr=65536
MINAddr=0

AddrList=[]
print(MINAddr,MAXAddr)
with open('addresses-locality.txt', 'w') as fp:  
    for ii in range (0,100):
        flag = random.randint(500,65036)
        for jj in range (0,100):
            TEMPAddr = random.randint(flag-500,flag+500)
            AddrList.append(TEMPAddr)
            fp.write(''.join([str(TEMPAddr),'\n']))    


x=np.arange(0,10000,1)
y1=AddrList
plt.plot(x, y1)
plt.title('Local access')
plt.xlabel('x')
plt.ylabel('y1')
 
plt.show()
plt.savefig('Local access.png')
