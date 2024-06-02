#coding:utf8
import os
import numpy as np

t1_sample = 700
t2_sample = 700
r = 3.1415926535897932384626

with open("cos_sin_chart.bin", "wb") as f:
    for t1_cnt in range(-t1_sample + 1, t1_sample + 1, 1):
        t1 = t1_cnt * r / t1_sample
        print(np.float32(np.sin(t1)), np.float32(np.cos(t1)))
        f.write(np.float32(np.sin(t1)))
        f.write(np.float32(np.cos(t1)))
