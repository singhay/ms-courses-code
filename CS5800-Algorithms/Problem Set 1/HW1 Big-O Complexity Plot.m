X = 0:10:100;

y01 = times(X,power(2, X+1));
y02 = power(X, 101/100);
y03 = times(X, power(log(X), 3));
y04 = times(X, log(X));
y05 = power(X, log(log(X)));
y06 = log(power(X, (times(2, X))));
y07 = power(X, log(X));
y08 = power(2, X);
y09 = times(X, power(2, X));
y10 = power(2, sqrt(log(X)));
y11 = power(2, power(2, X+1));
y12 = exp(exp(X));
y13 = log(factorial(X));
y14 = exp(log(X));
y15 = power(2, log(sqrt(X)));
y16 = power(sqrt(2), log(X));
y17 = power(2, power(X, 2));
y18 = 0;
y19 = 0;
y20 = log(log(X));

plot(X,y01,X,y02,X,y03,X,y04,X,y05,X,y06,X,y07,X,y08,X,y09,X,y10,X,y11,X,y12,X,y13,X,y14,X,y15,X,y16,X,y17,X,y18,X,y19,X,y20)

title('Big-O HW1 CompleXity Plot');
xlabel('Operations');
ylabel('Elements');