classdef (Sealed) cParseStream < cTaesLab
% cParseStream utility class to validate fuel-product stream definition
%
% cParseStream Methods
%   getFlows     - Get the I/O flows of a stream
%   checkStream  - Check a stream string definition
%	checkProcess - Check the F/P string definition
%	getFlowList  - Get the list of flow of a Stream
%	getStream    - Get the streams of the F/P string definition
%
	properties (Constant,Access=private)
		template='+-()';
		type_table=[2 3 4 5];
		base_table=[1 2 4 8 16 32 64];
		transition_table=[40 40 32 32 2 64 86 80];
		stream_pattern='([+|-]?[A-Z][A-Za-z0-9]+)+';
		flow_pattern='[+|-]?[A-Z][A-Za-z0-9]+';
        key_pattern='[A-Z][A-Za-z0-9]+'
        BEGIN=1;
        PLUS=2;
        MINUS=3;
        OPEN_BRACKET=4;
        CLOSE_BRACKET=5;
        KEY_FIRST=6;
        KEY_TEXT=7;
        END=8;
	end

    properties(Access=private)
        pQueue   % Positive flows queue
        nQueue   % Negative flows queue
    end  

    methods
        function obj=cParseStream()
        % Object Constructor
            obj.pQueue=cLogger();
            obj.nQueue=cLogger();
        end
        
        function [p,n]=getFlows(obj,stream)
		% return input/output flows lists
		% input: string contains the stream definition
		% output:
		%  p - cLogger containing the positive flows keys
        %  n - cLogger containing the negative flows keys
            obj.pQueue.clear; obj.nQueue.clear;
			tmp=regexp(stream,cParseStream.flow_pattern,'match');
            for i=1:length(tmp)
                aux=tmp{i};
                if isstrprop(aux(1),'alphanum')
                    obj.pQueue.add(aux);
                else
                    if aux(1)==cParseStream.template(1)
                        obj.pQueue.add(aux(2:end));
                    else
                        obj.nQueue.add(aux(2:end));
                    end
                end
            end
            p=obj.pQueue;
            n=obj.nQueue;
		end
    end
    
	methods (Static)
		function test=checkProcess(exp)
		% check if a fuel/product description is correct
			test=cParseStream.check(exp);
		end

		function res=getStreams(exp)
		% return a list of streams description of a fuel/product definition
			tmp=strrep(exp,')+',')');
			res=regexp(tmp,cParseStream.stream_pattern,'match');
		end

		function res=getFlowsList(stream)
		% return a list of the flows description of a stream
			res=regexp(stream,cParseStream.key_pattern,'match');
		end
    end
    
    methods(Static,Access=private)	
        function res=getType(char)
            if isstrprop(char,'upper')
                res=cParseStream.KEY_FIRST;
                return
            elseif isstrprop(char,'alphanum')
                res=cParseStream.KEY_TEXT;
            else
                test=strfind(cParseStream.template,char);
                if isempty(test)
                    res=0;
                else
                    res=cParseStream.type_table(test);
                end
            end
        end

		function test=check(exp)
		% Check stream definition. Internal method
		% input: 
		%   exp - string contains the stream definition
		%   tt - transition table
			prev=1;par=0;
            tt=cParseStream.transition_table;
			exp=upper(strtrim(exp));
			for i=1:length(exp) %Read characters
				act=cParseStream.getType(exp(i:i));
                if ~act
                    test=0;
                    return;
                end
                switch act %check open/close brackets
                case cParseStream.OPEN_BRACKET
                    par=par+1;
                case cParseStream.CLOSE_BRACKET
                    par=par-1;
                case cParseStream.KEY_FIRST
                    if prev>=act
                        act=cParseStream.KEY_TEXT;
                    end
                end
                % check transition table
				test=bitand(tt(prev),cParseStream.base_table(act));
				if ~test
					return;
				end
				prev=act;
			end
            test=bitand(tt(end),cParseStream.base_table(act)); %last character check
            test=and(test,~par);
		end
	end
end