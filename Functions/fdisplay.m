function fdisplay(A,fmt)
% fdisplay display a matrix A using C-like fmt
%   USAGE:
%       fdisplay(A, fmt)
%   INPUT:
%       A - matrix
%     fmt - C-like format string
    label=inputname(1);    
    if isempty(label)
        label='ans';
    end
    fprintf('\n');
    fprintf('%s =\n',label)
    lfmt=[repmat(fmt,1,size(A,2)) '\n'];
    fprintf(lfmt,A);
    fprintf('\n');
end