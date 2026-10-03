def covered():
    return 42

def uncovered(n):
    return n * 2 if n > 20 else n if n > 10 else -n if n < 0 else 0
