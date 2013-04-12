function [x,y] = RNOGen(n)

x = ceil((2*n + 1)*rand) - (n + 1);
y = ceil((2*n + 1)*rand) - (n + 1);

while (abs(x) + abs(y)) > n,
	x = ceil((2*n + 1)*rand) - (n + 1);
	y = ceil((2*n + 1)*rand) - (n + 1);
end;