package main.java.com.cs6240.Fibonacci;

/**
 * Created by Ayush Singh on 1/27/17.
 */
class Fibonacci {
    public static void compute(int n)
    {
        /* Declare an array to store Fibonacci numbers. */
        int f[] = new int[n+1];
        int i;

        /* 0th and 1st number of the series are 0 and 1*/
        f[0] = 0;
        f[1] = 1;

        for (i = 2; i <= n; i++)
        {
            /* Add the previous 2 numbers in the series and store it */
            f[i] = f[i-1] + f[i-2];
        }
    }


    /** Below is the recursion method since above Dynamic Programming solution
     *  somehow improved the run time, but even if we used this recursive version
     *  Only Coarse Lock seems to get affected
    public static int computeRecurse(int n){
        if (n == 0) return 0;
        else if (n == 1) return 1;
        else {
            return computeRecurse(n-1) + computeRecurse(n-2);
        }
    }
     */
}