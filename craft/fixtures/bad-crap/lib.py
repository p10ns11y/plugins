def messy(x, y, z, flag):
    if x > 0:
        if y > 0:
            if z > 0:
                if flag:
                    return x + y + z
                return x + y
            return x
        return 0
    return -1
