function x = vDivide(arg1,arg2)
%vDivide Element-wise right division 
%   overload operator rdivide when 0/0
    x=rdivide(zerotol(arg1),zerotol(arg2));
    x(isnan(x))=0;
end