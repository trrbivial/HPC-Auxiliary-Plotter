import os
import numpy as np

np.set_printoptions(precision=4, suppress=True)

n = 3
nsize = n * 1920 * 144 // 2
res = 4 * (2**20) - nsize

print(res)

with open("bar.bin", "wb") as f:
    for i in range(n):
        with open("bar{}.bin".format(i + 1), "rb") as bar:
            size = os.path.getsize("bar{}.bin".format(i + 1))  #获得文件大小
            print(size)
            data = bar.read(size)
            f.write(data)

    for i in range(res):
        f.write(b'\x00')

size = os.path.getsize("bar.bin")  #获得文件大小
print(size)
