#include <bits/stdc++.h>
#include <omp.h>
#define cp std::complex<float>

const int N = 6;
const int DIV_N = 200;
const float range = 100;
const int ITER_EACH = 10;

void givens_rotation(cp A[N][N], cp c[N], cp s[N], int row_id, int col_id) {
  cp a = A[col_id][col_id];
  cp b = A[row_id][col_id];
  float norm = 1.0 / sqrt(std::norm(a) + std::norm(b));
  c[col_id] = std::conj(a) * norm;
  s[col_id] = std::conj(b) * norm;
}

void mul_givens_mat(cp A[N][N], cp c[N], cp s[N], int row_id, int col_id,
                    int dir) {
  cp coef_c = c[col_id];
  cp coef_s = s[col_id];
  if (!dir) {
    for (int i = 0; i < N; i++) {
      cp a = A[col_id][i];
      cp b = A[row_id][i];
      A[col_id][i] = coef_c * a + coef_s * b;
      A[row_id][i] = -std::conj(coef_s) * a + std::conj(coef_c) * b;
    }
  } else {
    for (int i = 0; i < N; i++) {
      cp a = A[i][col_id];
      cp b = A[i][row_id];
      A[i][col_id] = std::conj(coef_c) * a + std::conj(coef_s) * b;
      A[i][row_id] = -coef_s * a + coef_c * b;
    }
  }
}

void qr_decomp(cp A[N][N], int lim) {
  cp tmp = A[lim][lim];
  for (int i = 0; i < N; i++) {
    A[i][i] -= tmp;
  }
  cp c[N], s[N];
  for (int row_id = 1; row_id <= lim; row_id++) {
    int col_id = row_id - 1;
    givens_rotation(A, c, s, row_id, col_id);
    mul_givens_mat(A, c, s, row_id, col_id, 0);
  }
  for (int row_id = 1; row_id <= lim; row_id++) {
    int col_id = row_id - 1;
    mul_givens_mat(A, c, s, row_id, col_id, 1);
  }
  for (int i = 0; i < N; i++) {
    A[i][i] += tmp;
  }
}

void iteration(cp A[N][N]) {
  int t = ITER_EACH * (N - 1);
  for (int i = 0; i < t; i++) {
    qr_decomp(A, N - 1 - i / ITER_EACH);
  }
}

int main() {

#pragma omp parallel for
  for (int i = -DIV_N + 1; i <= DIV_N; i++) {
    float t1 = 1.0 * i * range / DIV_N;
    for (int j = -DIV_N + 1; j <= DIV_N; j++) {
      float t2 = 1.0 * j * range / DIV_N;
      cp A[N][N];
      memset(A, 0, sizeof(A));
      for (int k = 1; k < N; k++) {
        A[k][k - 1] = 1;
      }
      A[0][1] = cp(0, 1);
      A[0][2] = cp(-1, 0);
      A[0][3] = cp(0, 1);
      A[0][0] = cp(-t2, -1);
      A[0][5] = cp(-1, t1);
      iteration(A);
    }
  }

  return 0;
}
