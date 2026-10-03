import pytest

from lib import discount


def test_discount_zero_rate():
    assert discount(100, 0) == 100


def test_discount_half():
    assert discount(100, 0.5) == 50


def test_discount_negative_price():
    with pytest.raises(ValueError):
        discount(-1, 0.1)


def test_discount_bad_rate():
    with pytest.raises(ValueError):
        discount(10, 1.5)
