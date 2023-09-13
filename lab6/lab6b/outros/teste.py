yb, xc = 1042, -2042
tempos = [6823, 4756, 6047, 9913]
# 6823 4756 6047 9913
tr = tempos[3]

da, db, dc, _ = [((tr - i) * 3)//10 for i in tempos]
print(f"y = {da**2} + {yb**2} - {db**2} / (2*{yb})")
print(f"{da**2} - {db**2} + {yb**2} = {da**2-db**2+yb**2}")
y = (da**2 + yb**2 - db**2) / (2*yb)
print("y:", y)

x = (da**2 - y**2) ** (1/2)
x_ = -x

approx = abs((x - xc)**2 + y**2 - dc**2)
approx_ = abs((x_ - xc)**2 + y**2 - dc**2)

print("x:", x)
print("approx+:", approx)
print("approx-:", approx_)
print("min:", min(approx, approx_))
