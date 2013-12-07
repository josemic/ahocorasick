%%%-------------------------------------------------------------------
%%% @author michael <michael@donald-desktop>
%%% @copyright (C) 2013, michael
%%% @doc
%%%
%%% @end
%%% Created : 20 Nov 2013 by michael <michael@donald-desktop>
%%%-------------------------------------------------------------------
-module(ahocorasick_tests).

%% Note: This directive should only be used in test suites.
-compile(export_all).

-include_lib("eunit/include/eunit.hrl").

ahocorasick_test_() ->
    [
        ahocorasick_build_Dbs()
    ].

ahocorasick_build_Dbs() ->
	{GotoDict, FailDict, OutputDict} = ahocorasick:build_dicts([<<"Michael">>, <<"Andreas">>,<<"Andrea">>, <<"Bernd">>]), 
	Result = ahocorasick:find(GotoDict, FailDict, OutputDict, <<"AndreashallosdfsdffAndreasfsdfAndreaadsfsdfMichaelsdfdf">>),
	?_assertEqual(Result, [{43,<<"Michael">>}, {30,<<"Andrea">>}, {19,<<"Andreas">>}, {19,<<"Andrea">>}, {0,<<"Andreas">>}, {0,<<"Andrea">>}]).
