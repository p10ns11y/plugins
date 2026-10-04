def discount(price: int, rate: float) -> int:
    if price < 0:
        raise ValueError("price")
    if rate < 0 or rate > 1:
        raise ValueError("rate")
    return int(price * (1 - rate))

def inc(n): return n + 1

def count(n):
    i = 0
    while i < n:
        i = i + 1
    return i

