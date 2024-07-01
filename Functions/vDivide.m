function x = vDivide(arg1,arg2)
%vDivide - Element-wise right division. Overload operator rdivide when 0/0
%   If the value is NaN it returns zero
%
%   Syntax
%     x = vDivide(arg1, arg2)
%   
%   Input Arguments
%     arg1, arg2 - vector arguments for rdivide
%   
%   Output Argument
%     x - result vector if x(i) is NaN return 0.
%
    x=rdivide(zerotol(arg1),zerotol(arg2));
    x(isnan(x))=0;
end