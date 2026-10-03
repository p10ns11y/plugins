def covered() -> int:
    return 42


def uncovered(n: int) -> int:
    if n > 10:
        if n > 20:
            return n * 2
        return n
    if n < 0:
        return -n
    return 0
