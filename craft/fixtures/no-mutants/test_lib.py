from lib import push
def test_push():
    items = []
    push(items, 3)
    assert items == [6]
