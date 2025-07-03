// qr_decomp_iter.cu - CUDA adaptation of Givens QR iteration for complex matrix

#include <cuComplex.h>
#include <cuda_runtime.h>
#include <math.h>
#include <stdio.h>

#define N 6
#define ITER_EACH 10
#define DIV_N 5000
#define range 100.0

__device__ cuFloatComplex A[N][N];
__device__ cuFloatComplex c[N], s[N];

__device__ float complex_norm(cuFloatComplex a) {
  return cuCrealf(a) * cuCrealf(a) + cuCimagf(a) * cuCimagf(a);
}

__device__ void givens_rotation(cuFloatComplex A[N][N], cuFloatComplex c[N],
                                cuFloatComplex s[N], int row_id, int col_id) {
  cuFloatComplex a = A[col_id][col_id];
  cuFloatComplex b = A[row_id][col_id];
  float norm = rsqrtf(complex_norm(a) + complex_norm(b));
  c[col_id] = cuCmulf(cuConjf(a), make_cuFloatComplex(norm, 0));
  s[col_id] = cuCmulf(cuConjf(b), make_cuFloatComplex(norm, 0));
}

__device__ void mul_givens_mat(cuFloatComplex A[N][N], cuFloatComplex c[N],
                               cuFloatComplex s[N], int row_id, int col_id,
                               int dir) {
  cuFloatComplex coef_c = c[col_id];
  cuFloatComplex coef_s = s[col_id];

  if (dir == 0) {
    for (int i = 0; i < N; i++) {
      cuFloatComplex a = A[col_id][i];
      cuFloatComplex b = A[row_id][i];
      A[col_id][i] = cuCaddf(cuCmulf(coef_c, a), cuCmulf(coef_s, b));
      A[row_id][i] =
          cuCsubf(cuCmulf(cuConjf(coef_c), b), cuCmulf(cuConjf(coef_s), a));
    }
  } else {
    for (int i = 0; i < N; i++) {
      cuFloatComplex a = A[i][col_id];
      cuFloatComplex b = A[i][row_id];
      A[i][col_id] =
          cuCaddf(cuCmulf(cuConjf(coef_c), a), cuCmulf(cuConjf(coef_s), b));
      A[i][row_id] = cuCsubf(cuCmulf(coef_c, b), cuCmulf(coef_s, a));
    }
  }
}

__device__ void qr_decomp(cuFloatComplex A[N][N], int lim) {
  cuFloatComplex tmp = A[lim][lim];
  cuFloatComplex c[N], s[N];
  for (int i = 0; i < N; i++) {
    A[i][i] = cuCsubf(A[i][i], tmp);
  }
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
    A[i][i] = cuCaddf(A[i][i], tmp);
  }
}

__device__ void qr_iteration_kernel(cuFloatComplex A[N][N]) {
  int t = ITER_EACH * (N - 1);
  for (int i = 0; i < t; i++) {
    qr_decomp(A, N - 1 - i / ITER_EACH);
  }
}

void print_matrix(const cuFloatComplex h_A[N][N]) {
  for (int i = 0; i < N; i++) {
    for (int j = 0; j < N; j++) {
      printf("(%5.2f,%5.2f) ", cuCrealf(h_A[i][j]), cuCimagf(h_A[i][j]));
    }
    printf("\n");
  }
}

__global__ void kernel(cuFloatComplex *diag_results) {
  int i = blockIdx.y * blockDim.y + threadIdx.y - DIV_N + 1;
  int j = blockIdx.x * blockDim.x + threadIdx.x - DIV_N + 1;

  if (i < -DIV_N + 1 || i > DIV_N || j < -DIV_N + 1 || j > DIV_N)
    return;

  int grid_size = 2 * DIV_N + 1;
  int idx_i = i + DIV_N - 1;
  int idx_j = j + DIV_N - 1;
  int global_idx = (idx_i * grid_size + idx_j) * N;

  float t1 = 1.0f * i * range / DIV_N;
  float t2 = 1.0f * j * range / DIV_N;

  cuFloatComplex local_A[N][N];
  memset(local_A, 0, sizeof(local_A));

  for (int k = 1; k < N; k++) {
    local_A[k][k - 1] = make_cuFloatComplex(1.0f, 0.0f);
  }
  local_A[0][1] = make_cuFloatComplex(0, 1);
  local_A[0][2] = make_cuFloatComplex(-1, 0);
  local_A[0][3] = make_cuFloatComplex(0, 1);
  local_A[0][0] = make_cuFloatComplex(-t2, -1);
  local_A[0][5] = make_cuFloatComplex(-1, t1);

  qr_iteration_kernel(local_A);

  for (int d = 0; d < N; d++) {
    diag_results[global_idx + d] = local_A[d][d];
  }
}

int main() {
  dim3 blockDim(16, 16);
  dim3 gridDim((2 * DIV_N + 1 + 15) / 16, (2 * DIV_N + 1 + 15) / 16);

  cuFloatComplex *d_diag_results;
  cuFloatComplex *h_diag_results;

  int total_points = (2 * DIV_N + 1) * (2 * DIV_N + 1);
  cudaMalloc(&d_diag_results, sizeof(cuFloatComplex) * total_points * N);
  h_diag_results =
      (cuFloatComplex *)malloc(sizeof(cuFloatComplex) * total_points * N);

  kernel<<<gridDim, blockDim>>>(d_diag_results);
  cudaMemcpy(h_diag_results, d_diag_results,
             sizeof(cuFloatComplex) * total_points * N, cudaMemcpyDeviceToHost);

  /*
  for (int idx = 100000; idx < 160000; ++idx) {
    printf("Point %d: ", idx);
    for (int d = 0; d < N; ++d) {
      cuFloatComplex val = h_diag_results[idx * N + d];
      printf("(%5.2f, %5.2f) ", cuCrealf(val), cuCimagf(val));
    }
    printf("\n");
  }
  */

  return 0;
}

