function x = vDivide(arg1, arg2)
%vDivide - Element-wise division with NaN handling for 0/0 cases.
%   Performs element-wise right division (arg1 ./ arg2) with special handling
%   for indeterminate forms (0/0) that produce NaN values. Instead of returning
%   NaN, the function returns zero for these cases. This is particularly useful
%   in thermoeconomic analysis where 0/0 ratios represent undefined but
%   structurally zero relationships.
%
%   The function applies zero-tolerance filtering to both inputs before division
%   to handle numerical precision issues, then replaces any resulting NaN values
%   with zeros. Input vectors are automatically oriented to match each other
%   (both row or both column vectors).
%
%   Syntax:
%     x = vDivide(arg1, arg2)
%   
%   Input Arguments:
%     arg1 - Numerator vector (n×1 or 1×n numeric)
%            Vector to be divided (dividend). Must be the same length as arg2.
%
%     arg2 - Denominator vector (n×1 or 1×n numeric)
%            Vector to divide by (divisor). Must be the same length as arg1.
%            Zero elements are handled via zerotol() before division.
%   
%   Output Arguments:
%     x - Result vector (n×1 or 1×n numeric, same orientation as arg1)
%         Element-wise division result where x(i) = arg1(i) / arg2(i).
%         NaN values (from 0/0) are replaced with 0.
%
%   Algorithm:
%     1. Validate input arguments (exactly 2 vectors of same length)
%     2. Orient vectors consistently (both row or both column)
%     3. Apply zero-tolerance filter to both vectors: zerotol()
%     4. Perform element-wise division: rdivide(arg1, arg2)
%     5. Replace NaN values with zero: x(isnan(x)) = 0
%
%   Examples:
%     % Example 1: Basic division with no zero denominators
%     a = [1, 0, 3];
%     b = [1, 2, 3];
%     x = vDivide(a, b);
%     % x = [1, 0, 1]
%     % a(2)/b(2) = 0/2 = 0 (not 0/0, so standard result)
%
%     % Example 2: True 0/0 case produces 0 instead of NaN
%     a = [1, 0, 3, 0];
%     b = [2, 0, 3, 5];
%     x = vDivide(a, b);
%     % x = [0.5, 0, 1, 0]
%     % a(2)/b(2) = 0/0 → NaN → 0
%
%     % Example 3: Division by zero (nonzero/0)
%     a = [1, 2, 0];
%     b = [2, 0, 0];
%     x = vDivide(a, b);
%     % x = [0.5, Inf, 0]
%     % a(2)/b(2) = 2/0 = Inf, a(3)/b(3) = 0/0 → 0
%
%     % Example 4: Column vectors
%     a = [4; 0; 6];
%     b = [2; 0; 3];
%     x = vDivide(a, b);
%     % x = [2; 0; 2]
%     % Preserves column vector orientation
%
%     % Example 5: Mixed orientations (auto-corrected)
%     a = [1, 2, 3];      % Row vector
%     b = [2; 4; 6];      % Column vector
%     x = vDivide(a, b);
%     % x = [0.5, 0.5, 0.5]
%     % b converted to row vector to match a
%
%     % Example 6: Efficiency ratios with zero handling
%     output = [10, 0, 15, 0];
%     input = [20, 5, 15, 0];
%     efficiency = vDivide(output, input);
%     % efficiency = [0.5, 0, 1, 0]
%     % Handles zero output/zero input as efficiency = 0
%
%   See also:
%     rdivide, zerotol
%

    % Validate input arguments: exactly 2 arguments required
    try
        narginchk(2, 2);
    catch ME
        msg = buildMessage(mfilename, ME.message);
        error(msg);
    end   
    % Validate that both arguments are vectors of the same length
    if ~isvector(arg1) || ~isvector(arg2) || (length(arg1) ~= length(arg2))
        msg = buildMessage(mfilename, cMessages.VectorLengthError);
        error(msg);
    end
    % Ensure both arguments have consistent orientation for element-wise division
    % Convert arg2 to match arg1's orientation (row or column)
    if iscolumn(arg1) && isrow(arg2), arg2 = arg2'; end
    if isrow(arg1) && iscolumn(arg2), arg2 = arg2'; end    
    % Apply zero-tolerance filter to both vectors to handle numerical precision
    % This prevents issues with very small numbers near zero
    arg1_filtered = zerotol(arg1);
    arg2_filtered = zerotol(arg2);
    x = rdivide(arg1_filtered, arg2_filtered);  % Perform element-wise division
    x(isnan(x)) = 0;                            % Replace NaN values (from 0/0) with zero
end