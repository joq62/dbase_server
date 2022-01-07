-module(db_test1).
-import(lists, [foreach/2]).
%-compile(export_all).
-export([

	]).

-export([
	 read/2,
	 read_record/2,
	 read_all/1,
	 read_all_record/1,
	 create/2,
	 delete/2,	 
	 create_table/1,
	 update/4,
	 add_table/1

	]).

-include_lib("stdlib/include/qlc.hrl").

-define(TABLE,test_1).
-define(RECORD,test_1). 
-record(?RECORD,
	{
	 term1,
	 term2
	}).

%%------------------------- Application specific commands ----------------
%%------------------------- Generic  dbase commands ----------------------
create_table(Node)->
    {atomic,ok}=rpc:call(Node,mnesia,create_table,[?TABLE, [{attributes, record_info(fields, ?RECORD)}]],10*1000),
    rpc:call(Node,mnesia,wait_for_tables,[[?TABLE], 20000],23*1000).



create(Node,{T1,T2}) ->
    Record=#?RECORD{
		    term1=T1,
		    term2=T2
		   },		
    rpc:call(Node,dbase,create,[Record],10*1000).


read_all(Node) ->
    Result=case read_all_record(Node) of
	       {aborted,Reason}->
		   {aborted,Reason};
	       Z->
		   [{T1,T2}||
		       {?RECORD,T1,T2}<-Z]
	   end,
    Result.

read(Node,Object)->
    Result=case read_all(Node) of
	       {aborted,Reason}->
		   {aborted,Reason};
	       All->
		   [{T1,T2}||{T1,T2}<-All,
			T1=:=Object]
	   end,
    Result.


update(Node,Object,Entry,NewData)->
    Result=case read_record(Node,Object) of
	       {error,Reason}->
		   {error,Reason};
	       [Record]->
		   EntryNum=case Entry of
				term1-> 1;
				term2->2;
				NoEntry->
				    {error,[no_entry,NoEntry]}
			    end,
		   case EntryNum of
		       {error,Reason}->
			   {error,Reason};
		       EntryNum->
			   rpc:call(Node,dbase,update,[?TABLE,Record,EntryNum,NewData],5*1000)   
		   end
		   
	   end,
    Result.
    
    
delete(Node,Object) ->
    io:format("Node,Object ~p~n",[{Node,Object,?FUNCTION_NAME,?MODULE,?LINE}]),
    Result=case read_record(Node,Object) of
	       {error,Reason}->
		   {error,Reason};
	       [Record]->
		   io:format("Record ~p~n",[{Record,?FUNCTION_NAME,?MODULE,?LINE}]),
		   rpc:call(Node,dbase,delete,[?TABLE,Record],5*1000)
	   end,
    Result.
%%-------------------------------------------------------------------------
add_table(AddedNode)->
    StorageType=ram_copies,
    rpc:call(AddedNode,lib_dbase,dynamic_load_table,[?TABLE,StorageType],25*1000).
    


read_all_record(Node)->
    Result=case rpc:call(Node,dbase,do_qlc,[?TABLE],5*1000) of
	       {aborted,Reason}->
		   {aborted,Reason};
	       R->
		   R
	   end,
    Result.


read_record(Node,Object) ->
    Result=case read_all_record(Node) of
	       {aborted,Reason}->
		   {aborted,Reason};
	       All->
		   [{?RECORD,T1,T2}||
		      {?RECORD,T1,T2}<-All,
		       T1=:=Object]
	   end,
    Result.    


%%--------------------------------------------------------------------

