import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
import gym
import sys
import matplotlib.pyplot as plt
import random

AddrRandomList =[]
with open('random-addresses-locality.txt', 'w') as Randomfp: 
    for jj in range (0,10000):
        TEMPAddr = random.randint(0,65536)
        AddrRandomList.append(TEMPAddr)
        Randomfp.write(''.join([str(TEMPAddr),'\n']))     
x=np.arange(0,10000,1)
y2=AddrRandomList
plt.plot(x, y2)
plt.title('Random access')
plt.xlabel('x')
plt.ylabel('y2')
 
plt.show()
plt.savefig('Random access.png')
