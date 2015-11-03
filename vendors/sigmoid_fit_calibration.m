function [test_struct, param] = sigmoid_fit_calibration(test_struct)

data = [];
idxs = [];
notUsed = [];
for i = 1:size(test_struct.unclipped_boxes,2)
    for j = 1:size(test_struct.unclipped_boxes{1,i},1)
%         if test_struct.unclipped_boxes{1,i}(j,end) < 0.9 %0.8
        data = cat(1,data,test_struct.unclipped_boxes{1,i}(j,end));
        idxs = cat(1,idxs, [i,j]);
%         else
%             notUsed = cat(1,notUsed,[test_struct.unclipped_boxes{1,i}(j,end),i,j]); 
%         end
    end
end

param = sigmoid_fit(data);
newData=cdf('logistic',data,param(1),param(2));

for i = 1 : length(data)
    test_struct.unclipped_boxes{1,idxs(i,1)}(idxs(i,2),end) = newData(i);
    test_struct.final_boxes{1,idxs(i,1)}(idxs(i,2),end) = newData(i);
end