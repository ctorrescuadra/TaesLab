classdef cParseStream
%cParseStream static utility class to check and validadate strings
%   Contains functions to check names and fuel-product string definition
%
%   cParseStream Methods
%     checkProcess   - Check the F-P definition string
%     getFlowList    - Get the list of flows in a FP definition string
%     getStreams     - Get the list of productive groups
%	  getFlows       - Get the input and output flows of a productive group
%     checkKeyText   - Check if a key name is valid
%     checkListNames - Check if a list of names (states, samples) are valid 
%
	properties (Constant,Access=private)
		TEMPLATE='+-()';
		TYPE_TABLE=[2 3 4 5];
		BASE_TABLE=[1 2 4 8 16 32 64];
		TRANSITION_TABLE=[40 40 32 32 2 64 86 80];
		STREAM_PATTERN='([+|-]?[A-Z][A-Za-z0-9]+)+';
		FLOW_PATTERN='[+|-]?[A-Z][A-Za-z0-9]+';
        KEY_PATTERN='[A-Z][A-Za-z0-9]+'
        KEY_CHECK='^[A-Z][A-Za-z0-9]{1,7}$'
		NAME_PATTERN='^[A-Za-z]\w{1,9}$'
        BEGIN=1;
        PLUS=2;
        MINUS=3;
        OPEN_BRACKET=4;
        CLOSE_BRACKET=5;
        KEY_FIRST=6;
        KEY_TEXT=7;
        END=8;
	end

    methods(Static)
        function test=checkDefinitionFP(exp)
		%checkDefinitionFP check if a fuel/product definition string is correct
        %   Syntax:
        %     test=cParseStream.checkDefinitionFP(exp)
        %   Input Arguments: 
        %     exp - FP definition string
        %   Output Arguments:
        %     test - true/false
        %
			test=cParseStream.check(exp);
        end

        function res=getFlowsList(exp)
		%getFlowsList - Get the list of flows in a FP definition string
        %   Syntax:
        %     res=cParseStream.getFlowsList(exp)
        %   Input Arguments: 
        %     exp - FP definition string
        %   Output Arguments:
        %     res - cell array with the flow keys of the FP definition 
        %
			res=regexp(exp,cParseStream.KEY_PATTERN,'match');
		end

		function res=getStreams(exp)
		%getStreams - Get the list of productive groups
        %   Syntax:
        %     res=cParseStream.getStreams(exp)
        %   Input Arguments: 
        %     exp - FP definition string
        %   Output Arguments:
        %     res - cell array with the productive groups definition
        %
			tmp=strrep(exp,')+',')');
			res=regexp(tmp,cParseStream.STREAM_PATTERN,'match');
		end

        function [finp,fout]=getStreamFlows(str,fp)
        %getStreamFlows - return input/output flows lists
        %   Syntax:
        %     [finp,fout]=cParseStream.getFlows(stream)
        %   Input Arguments: 
        %     str - string contains the productive group definition
        %     fp - Indicate if the stream is fuel or product
        %   Output Arguments:
        %     finp - cell array of input flows
        %     fout - cell array of output flows
            p=cQueue();n=cQueue(); 
            tmp=regexp(str,cParseStream.FLOW_PATTERN,'match');
            for i=1:length(tmp)
                aux=tmp{i};
                tchar=cParseStream.getType(aux(1));
                
                switch tchar
                    case cParseStream.KEY_FIRST
                        p.add(aux);
                    case cParseStream.PLUS
                        p.add(aux(2:end));
                    case cParseStream.MINUS
                        n.add(aux(2:end));
                end
                switch fp
                    case cType.Stream.FUEL
                        finp=p.getContent;
                        fout=n.getContent;
                    case cType.Stream.PRODUCT
                        finp=n.getContent;
                        fout=p.getContent;
                end
            end
        end

        function res=checkListNames(list)
        %checkName - Check if a name (State,Sample) is valid
        %   Syntax:
        %     res=checkNAme(name)
        %   Input Argument:
        %     list: cell array of text
        %   Output Argument:
        %     res - true/false
            res=~any(cellfun(@isempty,regexp(list,cParseStream.NAME_PATTERN)));
        end

        function res=checkTextKey(key)
        %checkTextKey - Check if a text key is valid
        %   Syntax:
        %     res=checkTextKey(name)
        %   Input Argument:
        %     key: char array to text
        %   Output Argument:
        %     res - true/false
            res=true;
            if isempty(regexp(key,cParseStream.KEY_CHECK,'once'))
                res=false;
            end
        end
    end
    
    methods(Static,Access=private)	
        function res=getType(char)
        %getType - Get type of char
        %   Input:
        %     char - char to analyze
        %   Output:
        %     res - type of char code
            if isstrprop(char,'upper')
                res=cParseStream.KEY_FIRST;
                return
            elseif isstrprop(char,'alphanum')
                res=cParseStream.KEY_TEXT;
            else
                test=strfind(cParseStream.TEMPLATE,char);
                if isempty(test)
                    res=0;
                else
                    res=cParseStream.TYPE_TABLE(test);
                end
            end
        end

		function test=check(exp)
		%check - Check stream definition. Internal method
		%   Input: 
		%     exp - string contains the stream definition
        %   Output:
        %     test - true/false
			prev=1;par=0;
            tt=cParseStream.TRANSITION_TABLE;
			exp=upper(strtrim(exp));
			for i=1:length(exp) %Read characters
				act=cParseStream.getType(exp(i));
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
				test=bitand(tt(prev),cParseStream.BASE_TABLE(act));
				if ~test
					return;
				end
				prev=act;
			end
            test=bitand(tt(end),cParseStream.BASE_TABLE(act)); %last character check
            test=and(test,~par);
		end
	end
end