%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(lib_dbase).   
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("stdlib/include/qlc.hrl").
%%---------------------------------------------------------------------
%% Records for test
%%

%% --------------------------------------------------------------------
%-compile(export_all).

-export([
	 create/1,
	 update/4,
	 delete/2,
	 do_qlc/1,
	 dynamic_db_init/1,
	 dynamic_load_table/1
	 ]).
%% ====================================================================
%% External functions
%% ====================================================================
create(Record)->
    F = fun() ->
		mnesia:write(Record)
	end,
    mnesia:transaction(F).

delete(Table,RecordToRemove)->
    F = fun() -> 
		All=do_qlc(Table),
		RecordList=[Record||Record<-All,
			   Record=:=RecordToRemove],
		case RecordList of
		    []->
			mnesia:abort(Table);
		    [Record]->
			mnesia:delete_object(Record)
		end
		 
	end,
    mnesia:transaction(F).

update(Table,RecordToUpdate,EntryNum,NewData)->
    F = fun() -> 
		All=do_qlc(Table),
		RecordList=[Record||Record<-All,
				 Record=:=RecordToUpdate],
		case RecordList of
		    []->
			mnesia:abort(Table);
		    [Record]->
			RecordAsList=tuple_to_list(Record),
			{Head,Tail}=lists:split(EntryNum,RecordAsList),
			[_DataToChange|Tail2]=Tail,
						%io:format("Head,DataToChange,Tail2  ~p~n",[{Head,DataToChange,Tail2,?FUNCTION_NAME,?MODULE,?LINE}]),
			NewRecordAsList=lists:append(Head,[NewData|Tail2]),
			NewRecord=list_to_tuple(NewRecordAsList),
			mnesia:delete_object(Record),
			mnesia:write(NewRecord)
		end
		    
	end,
    mnesia:transaction(F).

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

do_qlc(Table) ->
    Q=qlc:q([X || X <- mnesia:table(Table)]),
    F = fun() -> qlc:e(Q) end,
    Result=case mnesia:transaction(F) of
	       {atomic, Val}->
		   Val;
	       Error->
		   Error
	   end,
    Result.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
dynamic_db_init([])->
    mnesia:stop(),
    mnesia:del_table_copy(schema,node()),
    mnesia:delete_schema([node()]),
    mnesia:start(),   
    ok;

dynamic_db_init([DbaseNode|T])->
    mnesia:stop(),
    mnesia:del_table_copy(schema,node()),
    mnesia:delete_schema([node()]),
    mnesia:start(),
%io:format("DbaseNode dynamic_db_init([DbaseNode|T]) ~p~n",[{DbaseNode,node(),?FUNCTION_NAME,?MODULE,?LINE}]),
    StorageType=ram_copies,
  %  case rpc:call(DbaseNode,mnesia,change_config,[extra_db_nodes, [node()]],5000) of
    case rpc:call(node(),mnesia,change_config,[extra_db_nodes,[DbaseNode]],5000) of
	{ok,[_AddedNode]}->
	    Tables=mnesia:system_info(tables),
	    [mnesia:add_table_copy(Table, node(),StorageType)||Table<-Tables,
							       Table/=schema],
	    mnesia:wait_for_tables(Tables,20*1000),
	    ok;
	_Reason ->
	    dynamic_db_init(T) 
    end.

dynamic_load_table(Module)->
  %  io:format("Module ~p~n",[{Module,node(),?FUNCTION_NAME,?MODULE,?LINE}]),
    Added=node(),
    StorageType=ram_copies,
    Module:add_table(Added,StorageType),
    Tables=mnesia:system_info(tables),
    mnesia:wait_for_tables(Tables,20*1000).

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
