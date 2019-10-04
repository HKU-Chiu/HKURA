function [cubic_n, mat2] = calculate_SUV_peak_kernel(x1, y1, z1, sample_size)

pix_size = [x1 y1 z1];

cubic_n = ceil(1/min(pix_size));

if mod(cubic_n, 2)==0
    cubic_n = cubic_n+1;
end

%%
xn = round(cubic_n * x1 / sample_size);
yn = round(cubic_n * y1 / sample_size);
zn = round(cubic_n * z1 / sample_size);

mat1 = zeros(xn, yn, zn);

for idx1 = 1:xn
    for idx2 = 1:yn
        for idx3 = 1:zn
            xx = (idx1-0.5)*sample_size - xn/2*sample_size;
            yy = (idx2-0.5)*sample_size - yn/2*sample_size;
            zz = (idx3-0.5)*sample_size - zn/2*sample_size;
            if sqrt(xx^2+yy^2+zz^2) <= 0.5
                mat1(idx1, idx2, idx3) = 1;
            end
        end
    end
end

%%
mat2 = zeros(cubic_n, cubic_n, cubic_n);
for idx1 = 1:xn
    for idx2 = 1:yn
        for idx3 = 1:zn
            if mat1(idx1,idx2,idx3) == 1
                mat2(floor((idx1-1)/(x1/sample_size))+1, floor((idx2-1)/(y1/sample_size))+1, floor((idx3-1)/(z1/sample_size))+1) = mat2(floor((idx1-1)/(x1/sample_size))+1, floor((idx2-1)/(y1/sample_size))+1, floor((idx3-1)/(z1/sample_size))+1)+1;
            end
        end
    end
end
%%
mat2 = mat2/sum(mat2(:));
mat2 = mat2(:);