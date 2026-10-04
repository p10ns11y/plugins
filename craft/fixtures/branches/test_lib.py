from lib import kept, matchy, multi, tern, using
def test_branches():
    assert tern(1, 2, 3, 4, True, False, False) == 1
    assert tern(1, 2, 3, 4, False, True, False) == 2 and tern(1, 2, 3, 4, False, False, True) == 3
    assert tern(1, 2, 3, 4, False, False, False) == 4 and using() == 1
    assert matchy(1) == "a" and matchy(2) == "b" and matchy(9) == "c"
    assert multi("3") == 3 and multi("x") == 0 and multi(None) == -1 and kept([0, 5, 20]) == [5]
