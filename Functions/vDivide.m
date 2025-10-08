function x = vDivide(arg1,arg2)
%vDivide - Element-wise right division. Overload operator rdivide when 0/0.
%   If the value is NaN it returns zero
%
%   Syntax:
%     x = vDivide(arg1, arg2)
%   
%   Input Arguments:
%     arg1, arg2 - vector arguments for rdivide
%   
%   Output Arguments:
%     x - result vector if x(i) is NaN return 0.
%
%   Example:
%     a = [1, 0, 3];
%     b = [1, 2, 3];
%     x = vDivide(a, b); %x = [1, 0, 1]
%
%   See also rdivide, zerotol

    % Check Input Arguments:
    if nargin ~= 2
        error('ERROR: vDivide. Requires two input arguments');
    end 
    % Check if arg1 and arg2 are vectors of the same length
    if ~isvector(arg1) || ~isvector(arg2) || (length(arg1) ~= length(arg2))
        error('ERROR: vDivide. Both input arguments must be vectors of the same length');
    end
    % Ensure both arguments are column or row  vectors for consistent division
    if iscolumn(arg1) && isrow(arg2),arg2= arg2';end
    if isrow(arg1) && iscolumn(arg2),arg2= arg2';end
    % Use zerotol to avoid division by zero issues
    x=rdivide(zerotol(arg1),zerotol(arg2));
    x(isnan(x))=0;
end