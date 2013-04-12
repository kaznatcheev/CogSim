function [p_sigmoid_coop,p_sigmoid_hum,p_sigmoid_eth] = ...
    bcPlot(bc_rat,cost_values,range,plot_flag)

if (nargin < 4 || isempty(plot_flag)),
    plot_flag = 1;
end;

if (nargin < 3 || isempty(range)),
	range = 1:10;
end;

if (nargin < 2 || isempty(cost_values)),
    cost_values = 0.001*(1:10);
end;

nEp = 10000;
tailEp = 1000;

prefix = '../CogSimData/';
bc_name = strcat('bc', int2str(bc_rat*100));


stratCount = zeros(nEp,4,length(range));
intCount = zeros(nEp,2,length(range));

num_costs = length(cost_values);
hum_costs = zeros(num_costs,1);
eth_costs = zeros(num_costs,1);
coop_costs = zeros(num_costs,1);

for cost_index = 1:num_costs,
    cost = cost_values(cost_index);
    cost_name = strcat('/cogC', int2str(cost*10000));
    
    for run = range,
        %read strategy data
        f_name = strcat(prefix,bc_name,cost_name, '/stratCount', int2str(run), '.txt');
        f_data = dlmread(f_name);
        
        stratCount(:,:,run) = f_data(1:nEp,:);
        
        %read interaction data
        f_name = strcat(prefix,bc_name,cost_name, '/intCount', int2str(run), '.txt');
        f_data = dlmread(f_name);
        
        intCount(:,:,run) = f_data(1:nEp,:);
    end;
    
    clear hum_num_temp;
    clear tot_num_temp;
    hum_num_temp(:,:) = stratCount(:,1,:);
    eth_num_temp(:,:) = stratCount(:,2,:);
    tot_num_temp(:,:) = sum(stratCount,2);
    
    humProp(:,:) = hum_num_temp./max(tot_num_temp, 1);
    humAvg = mean(humProp,2);

    hum_costs(cost_index) = mean(humAvg((nEp - tailEp + 1):nEp));
    
    eth_prop(:,:) = eth_num_temp./max(tot_num_temp,1);
    eth_avg = mean(eth_prop,2);
    
    eth_costs(cost_index) = mean(eth_avg((nEp - tailEp + 1):nEp));
    
    coopProp(:,:) = intCount(:,1,:)./max(intCount(:,1,:) + intCount(:,2,:), 1);
    coopAvg = mean(coopProp,2);
    
    coop_costs(cost_index) = mean(coopAvg((nEp - tailEp + 1):nEp));
end;

%fit the best sigmoid
[p_sigmoid_hum, f_sigmoid_hum] = fitSigmoid(cost_values,hum_costs');
[p_sigmoid_eth, f_sigmoid_eth] = fitSigmoid(cost_values,eth_costs');
[p_sigmoid_coop, f_sigmoid_coop] = fitSigmoid(cost_values,coop_costs');


if plot_flag,
    h = figure;
    hold;
    
    plot(cost_values,hum_costs,'b.');
    plot(cost_values,eth_costs,'r.');
    plot(cost_values,coop_costs,'k.');

    fplot(f_sigmoid_hum,[cost_values(1), cost_values(num_costs)],'b');
    fplot(f_sigmoid_eth,[cost_values(1), cost_values(num_costs)],'r');
    fplot(f_sigmoid_coop,[cost_values(1), cost_values(num_costs)],'k');
    
    plot([p_sigmoid_hum(3),p_sigmoid_hum(3)],[0 1],'b--');
    plot([p_sigmoid_eth(3),p_sigmoid_eth(3)],[0 1],'r--');
    plot([p_sigmoid_coop(3),p_sigmoid_coop(3)],[0 1],'k--');
    
    axis([cost_values(1), cost_values(num_costs), 0, 1]);
    grid;
    hold;
    
    print(h,'-dpng',strcat(prefix,bc_name, '/propPlot.png'));
end;

end