#coding:utf8
import numpy as np
import random as rd
from PIL import Image

np.set_printoptions(precision=4, suppress=True)


def givens_rotation_complex(A, offset: int):
    (r, c) = np.shape(A)
    ind = rd.randint(5 - offset, 5 - offset)
    mu = A[ind, ind]
    for i in range(6):
        A[i, i] -= mu
    Q = np.identity(r, dtype=complex)
    R = np.copy(A)
    T = np.copy(A)

    row_arr = []
    col_arr = []
    for i in range(5 - offset):
        row_arr.append(i + 1)
    for i in range(5 - offset):
        col_arr.append(i)

    (rows, cols) = (row_arr, col_arr)
    for (row, col) in zip(rows, cols):
        if R[row, col] != 0:  # R[row, col]=0则c=1,s=0,R、Q不变
            r_ = np.sqrt((R[col, col] * np.conj(R[col, col]) +
                          R[row, col] * np.conj(R[row, col])).real)
            c = np.conj(R[col, col]) / r_
            s = np.conj(R[row, col]) / r_
            G = np.identity(r, dtype=complex)
            G[col, col] = c
            G[row, row] = np.conj(c)
            G[row, col] = -np.conj(s)
            G[col, row] = s
            R = np.dot(G, R)  # R=G(n-1,n)*...*G(2n)*...*G(23,1n)*...*G(12)*A
            Q = np.dot(Q, np.conjugate(
                G.T))  # Q=G(n-1,n).T*...*G(2n).T*...*G(23,1n).T*...*G(12).T
            T = np.dot(G, T)
            T = np.dot(T, np.conjugate(G.T))
    for i in range(6):
        T[i, i] += mu
    return T


def my_eig(A):
    t = 10
    B = A.copy()
    for i in range(6 * t):
        #q, r = np.linalg.qr(A)
        B = givens_rotation_complex(B, i // t)
        #A = np.dot(r, q)
    eig = [B[i][i] for i in range(6)]
    return eig


c = np.zeros((6, 6), dtype=np.csingle)

r = 100.0
t1_sample = 200
t2_sample = 200

c[0][1] = 1j
c[0][2] = -1
c[0][3] = 1j
c[0][4] = 0
c[1][0] = c[2][1] = c[3][2] = c[4][3] = c[5][4] = 1

hsize = 1440
vsize = 900

scalar = 160
offset = 1.5 - 0.5 * 1j

hsize = 1920
vsize = 1080
scalar = 200

im = Image.new("RGB", (hsize, vsize))

img = np.array(im)

for i in range(vsize):
    for j in range(hsize):
        img[i, j] = (0, 0, 0)

cnt = 0

for t1_cnt in range(-t1_sample + 1, t1_sample + 1, 1):
    t1 = t1_cnt * r / t1_sample
    for t2_cnt in range(-t2_sample + 1, t2_sample + 1, 1):
        t2 = t2_cnt * r / t1_sample
        cnt = cnt + 1
        #print(t1_cnt, t2_cnt)
        c[0][0] = -t2 - 1j
        c[0][5] = -1 + 1j * t1
        #eigv_c, _ = np.linalg.eig(c)
        eigv_c = my_eig(c)
        print(eigv_c)
        assert False
        for l in eigv_c:
            p = (l - offset) * scalar
            #a = int(np.round(np.real(p))) + hsize // 2 - 1
            #b = int(np.round(np.imag(p))) + vsize // 2 - 1
            a = int((np.real(p))) + hsize // 2 - 1
            b = int((np.imag(p))) + vsize // 2 - 1
            if cnt <= 128:
                print(t1, t2, a, b, l)
            if a < 0 or b < 0 or a >= hsize or b >= vsize:
                continue
            _, g, _ = img[vsize - 1 - b, a]
            if g == 15:
                continue
            img[vsize - 1 - b, a] = (g + 1, g + 1, g + 1)
        if cnt == 128:
            assert False

for i in range(vsize):
    for j in range(hsize):
        r, g, b = img[i, j]
        img[i, j] = (r * 16, g * 16, b * 16)

img2 = Image.fromarray(np.uint8(img))

img2.show()
