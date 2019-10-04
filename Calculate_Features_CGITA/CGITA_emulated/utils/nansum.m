function out = nansum(x)
out = sum(x(~isnan(x)));
end