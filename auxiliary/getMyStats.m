function [P,CI,STATS,hyatt_stats] = getMyStats(samp1, samp2, varargin)   
% [P,CI,STATS,hyatt_stats] = getMyStats(samp1, samp2, varargin)   
%standard statistics wrapper for input vectors (samp1, samp2,..., sampN)
%

% Hyatt Moore IV, (< June, 2013)

[H,P,CI,STATS] = ttest2(samp1,samp2,0.05,'both','unequal');
%STATS.df = degrees of freedom
%STATS.tstat = test statistic
%calculates useful statistics for the inputs provided

mx = mean(samp1);
std_x =std(samp1);
var_x = var(samp1);
sem = std_x/sqrt(numel(samp1));
n = numel(samp1);

if(n>1)
    other_mx = mean(samp2);
    other_var_x = var(samp2);
    t_value = (mx-other_mx)/(sqrt(var_x/numel(samp1)+other_var_x/numel(samp2)));
    dof = numel(samp2)+numel(samp1)-2;
    p_value = (1-cdf('t',abs(t_value),dof))*2;  %make it two-tailed (2-tailed)
    
    hyatt_stats = [t_value, p_value, dof];
    
end