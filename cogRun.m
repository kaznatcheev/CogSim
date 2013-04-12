function out = cogRun(cogCost,range)

if (nargin < 2 || isempty(range)),
	range = 1:10;
end;

name = strcat('cogC', int2str(cogCost*10000));

%make the directory
mkdir(name)

for simRun = range,
	tic;
	[stratCount, intCount] = cogW(2.5,cogCost);
	dlmwrite(strcat(name, '/stratCount', int2str(simRun), '.txt'), stratCount);
	dlmwrite(strcat(name, '/intCount', int2str(simRun), '.txt'), intCount);
	{name simRun toc}
end;