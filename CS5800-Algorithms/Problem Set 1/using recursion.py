def modExp(a, b, m) :
    a %= m
    ret = None
    if b == 0 : ret = 1
    elif b%2 : ret = a * modExp(a,b-1,m)
    else : 
        ret = modExp(a,b//2,m)
        ret *= ret
    print ret%m          
    return ret%m
 
print modExp(19,19,11)