def tern(a, b, c, d, x, y, z):
    return a if x else b if y else c if z else d

def using():
    with open("/dev/null"):
        return 1

def matchy(x):
    match x:
        case 1: return "a"
        case 2: return "b"
        case _: return "c"

def multi(x):
    try: return int(x)
    except ValueError: return 0
    except TypeError: return -1

def kept(xs):
    return [x for x in xs if x > 0 if x < 10]
