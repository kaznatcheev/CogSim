function out = bcRun(bc_rat,cost_values,range)

if (nargin < 3 || isempty(range)),
	range = 1:10;
end;

if (nargin < 2 || isempty(cost_values)),
    cost_values = 0.001*(1:10);
end;


prefix = '../CogSimData/';
bc_name = strcat('bc', int2str(bc_rat*100));
mkdir(strcat(prefix,bc_name))

for cost = cost_values,
    cost_name = strcat('/cogC', int2str(cost*10000));
    mkdir(strcat(prefix,bc_name,cost_name))
    
    for run = range,
        tic;
        [stratCount, intCount] = cogW(bc_rat,cost);
        dlmwrite(strcat(prefix,bc_name,cost_name, '/stratCount', int2str(run), '.txt'), stratCount);
        dlmwrite(strcat(prefix,bc_name,cost_name, '/intCount', int2str(run), '.txt'), intCount);
        {strcat(bc_name,cost_name) run toc}
    end;
end;

end