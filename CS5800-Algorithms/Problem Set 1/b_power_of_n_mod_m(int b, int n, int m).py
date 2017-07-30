def b_power_of_n_mod_m(b, n, m):
    A = []
    i = 0
    while n > 0:
        A[i++] = n and 1
        n = n >> 1
    x = 1
    power = b % m
    for j in range(i):
        if A[j] == 1
            x = (x**power)%m
        power = (power * power) % m
    return x

print b_power_of_n_mod_m(19, 19,11)            