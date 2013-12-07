%%%-------------------------------------------------------------------
%%% @author michael <michael@donald-desktop>
%%% @copyright (C) 2013, michael
%%% @doc
%%%
%%% @end
%%% Created : 20 Nov 2013 by michael <michael@donald-desktop>
%%%-------------------------------------------------------------------
-module(ahocorasick).
-export([build_dicts/1, read/2, find/4, goto/3, output/2]).

new() ->
    dict:new().

read(Key, Db) ->
    case dict:find(Key,Db) of
	error -> {error, instance};
	{ok, Data} -> {ok, Data}
    end.

write(Key, Data, Db) ->
    dict:store(Key, Data, Db).


build_dicts(BinaryStringList) ->
    GotoDict = new(),
    FailDict = new(),
    OutputDict = new(),
    {GotoDictNew, OutputDictNew} = build_goto_output_do_loop(BinaryStringList, GotoDict, OutputDict, 0), 
    FailDictNew = build_fail_dict_do_loop(BinaryStringList, GotoDictNew, FailDict),
    {GotoDictNew, FailDictNew, OutputDictNew}. 

build_goto_output_do_loop([], GotoDict, OutputDict, _MaxState) ->
    {GotoDict, OutputDict};

build_goto_output_do_loop([HeadBinaryString|TailBinaryStringList], GotoDict, OutputDict, MaxState) ->
    {StateNew, GotoDictNew, MaxStateNew} = build_goto_output_char_do_inner_loop(_State = 0, HeadBinaryString, GotoDict, MaxState),
    OutputDictNew = write(StateNew, HeadBinaryString, OutputDict),
    build_goto_output_do_loop(TailBinaryStringList, GotoDictNew, OutputDictNew, MaxStateNew).

build_goto_output_char_do_inner_loop(State, <<>>, GotoDict, MaxState) ->
    {State, GotoDict, MaxState};

build_goto_output_char_do_inner_loop(State, <<Char:8, ByteStringRest/binary>>, GotoDict, MaxState) ->
    case  read(State, GotoDict) of
	{error, instance} ->
	    StateDb = new(),
	    MaxStateNew = MaxState+1,
	    StateDbNew = write(Char, MaxStateNew, StateDb),
	    GotoDictNew = write(State, StateDbNew, GotoDict),
	    NextState = MaxStateNew;		        
	{ok, StateDb} ->
	    case read(Char, StateDb) of 
		{error, instance} ->
		    MaxStateNew = MaxState+1,
		    StateDbNew = write(Char, MaxStateNew, StateDb),
		    GotoDictNew = write(State, StateDbNew, GotoDict),
		    NextState = MaxStateNew;
		{ok, NextState}-> 
		    GotoDictNew = GotoDict,
		    MaxStateNew = MaxState
	    end
    end,
    io:format("Char: ~p:'~p', State: ~p, NextState: ~p~n", [Char, [Char], State, NextState]),
    build_goto_output_char_do_inner_loop(NextState, ByteStringRest, GotoDictNew, MaxStateNew).

build_fail_dict_do_loop([], _GotoDict, FailDict) ->
    FailDict;

build_fail_dict_do_loop([HeadBinaryString|TailBinaryStringList], GotoDict, FailDict) ->
    {available, HeadBinaryStringState} = goto_charstring(GotoDict, 0, HeadBinaryString),
    FailDictNew = build_fail_char_do_inner_loop(HeadBinaryString, GotoDict, FailDict, HeadBinaryStringState),
    build_fail_dict_do_loop(TailBinaryStringList, GotoDict, FailDictNew).

build_fail_char_do_inner_loop(<<_Ignore:8>>, _GotoDict, FailDict, _HeadBinaryStringState) ->	
    FailDict;

build_fail_char_do_inner_loop(<<_Ignore:8, CharString/binary>>, GotoDict, FailDict,HeadBinaryStringState) ->
    case goto_charstring(GotoDict, 0, CharString) of
	not_available -> 
	    build_fail_char_do_inner_loop(<<CharString/binary>>, GotoDict, FailDict, HeadBinaryStringState);
	{available, FailState} -> 
	    FailDictNew = write(HeadBinaryStringState, FailState, FailDict),
	    build_fail_char_do_inner_loop(<<CharString/binary>>, GotoDict, FailDictNew, HeadBinaryStringState)
    end.

goto_charstring(_GotoDict, State, <<>>) ->
    {available, State};

goto_charstring(GotoDict, State, <<Char:8, TailCharString/binary>>) ->

    case goto(GotoDict, State, Char) of
	[] ->
	    not_available;
	0  ->	
	    not_available;
	NextState ->
	    goto_charstring(GotoDict, NextState, TailCharString) 	
    end.



goto(GotoDict, State = 0, Char) ->
    case read(State, GotoDict) of
        {error, instance} -> 
		0;
	{ok, StateDb} ->
	    case read(Char, StateDb) of
		{error, instance} -> 
			0;
		{ok, NextState}	->
			NextState
	    end
    end;

goto(GotoDict, State, Char) ->
    case read(State, GotoDict) of
        {error, instance} -> 
		[];
	{ok, StateDb} ->
	    case read(Char, StateDb) of
		{error, instance} -> 
			[];
		{ok, NextState}	->
			NextState
	    end
    end.

%% note the fail function has not been implemented yet. Thus upon fail it always goes back to the beginning.
fail(_FailDict, _State) ->
    0.
    %read(State, FailDict).

output(OutputDict, State) ->
    case read(State, OutputDict) of
	{error, instance} 
	-> [];
	{ok, FoundString}
	-> FoundString
    end.

find(GotoDict, FailDict, OutputDict, BinaryString) ->
    traverse_loop(0, GotoDict, FailDict, OutputDict, BinaryString, 0, []).

traverse_loop(_State, _GotoDict, _FailDict, _OutputDict, <<>>, _Index, Acc)->
    Acc;

traverse_loop(State, GotoDict, FailDict, OutputDict, <<Char:8, Rest/binary>>, Index, Acc) ->
    StateNew = fail_loop(GotoDict, FailDict, State, Char),
    FoundBinaryString = output(OutputDict, StateNew),
    FoundBinaryStringNew = case FoundBinaryString of
			       [] ->
				   Acc;
			       _Other -> [{Index+1-size(FoundBinaryString), FoundBinaryString}|Acc]
			   end,
    traverse_loop(StateNew, GotoDict, FailDict, OutputDict, <<Rest/binary>>, Index+1, FoundBinaryStringNew).

fail_loop(GotoDict, FailDict, State, Char)->
    Q1 = goto(GotoDict, State, Char),
    case Q1 of
	[] ->
	    fail_loop(GotoDict, FailDict, fail(FailDict, State), Char);
	_Other ->
	    Q1
    end.




