def moveZeroes(nums: list[int]) -> None:
    """
    Do not return anything, modify nums in-place instead.
    """
    found = []
    while True:
        try:
            idx = nums.index(0)
            zero = nums.pop(idx)
            found.append(0)
        except:
            break
    x = nums + found
    print(x)
    return x
