int b_power_of_n_mod_m(int b, int n, int m) {
    //convert n to binary and save in A array 
    int A[20];
    int i = 0;
    // n must be positive
    while (n > 0) {
        A[i++] = n & 1;
        n = n >> 1;
    }
    int x = 1;
    int power = b % m;
    for (int j = 0; j < i; j++) {
        if (A[j] == 1) x = (x * power) % m;
        power = (power * power) % m;
    }
    return x;
}

int main(void) {
 int ans = b_power_of_n_mod_m(19, 19, 11);
 printf("%d", ans);
 return 0;
}

