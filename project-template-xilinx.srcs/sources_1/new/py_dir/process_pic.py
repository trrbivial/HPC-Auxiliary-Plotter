#coding:utf8
import os
import numpy as np
import random as rd
from PIL import Image

np.set_printoptions(precision=4, suppress=True)

id = 3

im_pic = Image.open(
    "/home/satori/thu/digital-design/pic/{}-tmp.jpg".format(id))

im_pic = im_pic.convert("L")

print(im_pic.format, im_pic.size, im_pic.mode)

pic_hsize, pic_vsize = im_pic.size

img_pic = np.array(im_pic)
# print(img_pic)

# assert False

res_vsize = 144 - pic_vsize
top_pad = res_vsize // 2
bottom_pad = res_vsize - top_pad

for i in range(pic_vsize):
    for j in range(pic_hsize):
        g = img_pic[i, j] >> 4

im = Image.new("L", (1920, 144))

img = np.array(im)

for i in range(top_pad):
    for j in range(1920):
        img[i, j] = 15

for i in range(pic_vsize):
    for j in range(1920):
        g = img_pic[i, j] >> 4
        if g > 12:
            g = 15
        img[top_pad + i, j] = g

for i in range(bottom_pad):
    for j in range(1920):
        img[top_pad + pic_vsize + i, j] = 15

with open("bar{}.bin".format(id), "wb") as f:
    for i in range(144):
        for j in range(0, 1920, 2):
            g1 = img[i, j]
            g2 = img[i, j + 1]
            g = np.uint8(255 ^ ((g2 << 4) + g1))
            f.write(g)

#   with open("bar1.bin", "rb") as f:
#       size = os.path.getsize("bar1.bin")  #获得文件大小
#       print(size)
#       assert False
#       for i in range(size):
#           data = f.read(1)  #每次输出一个字节
#           if data == b'\xff':
#               continue
#           print(data)
assert False

for i in range(144):
    for j in range(1920):
        g = img[i, j]
        img[i, j] = g * 16

img2 = Image.fromarray(np.uint8(img))

img2.show()
