
counter = 1;
for i = 1: length(T_peak_index)
    aryy(counter) = t(T_peak_index(i)+randi(100));
    counter = counter + 1;
end

counter = 1;
for i = 1: length(T_peak_index)
    aryy1(counter) = t(T_peak_index(i));
    counter = counter + 1;
end

[a,b] = Sp_PP(aryy,aryy1);

% fix function arguments - make them two
function [Sensitivity, PPValue] = Sp_PP(Ref,Result)
    TP = 0;
    FP = 0;
    FN = 0;
    
    for i = 1 : length(Result)
        array = Ref >= Result(i)-0.06 & Ref <= Result(i)+0.06;
        if any(array)
            TP = TP + 1;
        else
            FP = FP + 1; 
        end
    end
    
    for i = 1 : length(Ref)
        array = Result >= (Ref(i)-0.06) & Result <= (Ref(i)+0.06);
        if ~any(array)
            FN = FN + 1;
        end
    end
    
    Sensitivity = TP/(TP+FN);
    PPValue = TP/(TP+FP);
end