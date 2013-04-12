function [stratCount, intCount] = cogW(bcRat,cogCost,plot_flag)

if (nargin < 3) || isempty(plot_flag),
	plot_flag = 0;
end;

[stCount, temp, intCount] = CogSim(10000,[],0.01*bcRat,[],[],[],[],[],[],[],cogCost);

stratCount = sum(stCount,3);

if plot_flag,
    figure;
    hold;
    plot(stratCount(:,1),'b.');
    plot(stratCount(:,2),'g.');
    plot(stratCount(:,3),'y.');
    plot(stratCount(:,3),'r.');
    plot(sum(stratCount,2)./4, 'k');
    hold;
    grid;
end;

end

