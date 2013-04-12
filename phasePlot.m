function  out = phasePlot(bc_rats,costs)

if (nargin < 2)|| isempty(costs),
    costs = cell(size(bc_rats));
    [costs{:}] = deal(0.001*(1:10));
end;

p_values_coop = zeros(length(bc_rats),4);
p_values_hum = zeros(length(bc_rats),4);
p_values_eth = zeros(length(bc_rats),4);

for bc_index = 1:length(bc_rats),
    [p_values_coop(bc_index,:), p_values_hum(bc_index,:), ...
        p_values_eth(bc_index,:)] ... 
        = bcPlot(bc_rats(bc_index),costs{bc_index},[],0);
end;

h = figure;
hold;
plot(bc_rats,p_values_hum(:,3),'b');
plot(bc_rats,p_values_eth(:,3),'r');
plot(bc_rats,p_values_coop(:,3),'k');
grid;

prefix = '../CogSimData';
print(h,'-dpng',strcat(prefix, '/phasePlot.png'));

end

