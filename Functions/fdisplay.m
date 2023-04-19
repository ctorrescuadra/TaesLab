function fdisplay(A,fmt)
%fdisplay Display a matrix A using C-like fmt
%   Input:
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