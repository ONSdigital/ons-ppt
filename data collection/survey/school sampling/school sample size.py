
# formula to calculate sample size

def sample_size(N, p=0.5, d=0.05, z=1.96, deff=1.0):
    numerator = deff * N * p * (1 - p)
    denominator = (d**2 / z**2) * (N - 1) + p * (1 - p)
    n = numerator / denominator
    return n
# inputting the values
N = 10000
p = 0.5
d = 0.05
z = 1.96
deff = 1.5
n = sample_size(N, p, d, z, deff)
print(f"Required sample size: {n:.2f}")
import math
print(f"Rounded up: {math.ceil(n)}")


