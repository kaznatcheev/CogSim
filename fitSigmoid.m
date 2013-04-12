function [p_out,f_out] = fitSigmoid(X,Y)

%sigmoid function
sigmoid = @(p,x) p(1) + p(2)./(1 + exp(-(x - p(3))/p(4)));

%first we need to guess some parameters
y_min = min(Y);
y_max = max(Y);
y_range = max(Y) - y_min;
x_min = min(X);
x_range = max(X) - x_min;

if find(Y == y_min,1) < find(Y == y_max,1),
    flip = 1;
else
    flip = -1;
end;

p_guess = [y_min, y_range, x_min + x_range/2, flip*x_range/4];

p_out = nlinfit(X,Y,sigmoid,p_guess);
f_out = @(x) sigmoid(p_out,x);

end

