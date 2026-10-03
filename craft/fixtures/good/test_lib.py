import pytest
from lib import count, discount, inc
def test_discount():
    assert discount(100, 0) == 100
    assert discount(100, 0.5) == 50
    with pytest.raises(ValueError):
        discount(-1, 0.1)
    with pytest.raises(ValueError):
        discount(10, 1.5)
def test_inc():
    assert inc(2) == 3
def test_count():
    assert count(2) == 2
