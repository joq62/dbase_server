%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : resource discovery accroding to OPT in Action 
%%% This service discovery is adapted to 
%%% Type = application 
%%% Instance ={ip_addr,{IP_addr,Port}}|{erlang_node,{ErlNode}}
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(dbase_server).

-behaviour(gen_server).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("logger_infra.hrl").
%% --------------------------------------------------------------------

-define(ScheduleInterval,1*10*1000).

%% External exports
-export([
	 schedule/0
	]).


%% gen_server callbacks



-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {loaded,
		spec_list
	       }).

%% ====================================================================
%% External functions
%% ====================================================================


schedule()->
    gen_server:cast(?MODULE, {schedule}).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    
    mnesia:stop(),
    mnesia:del_table_copy(schema,node()),
    mnesia:delete_schema([node()]),
    mnesia:start(),
    
    rpc:cast(node(),log,log,[?logger_info(info,"server started",[])]),
    {ok, #state{}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_call({create,Record},_From, State) ->
    Reply=rpc:call(node(),lib_dbase,create,[Record],5*1000),
    {reply, Reply, State};

handle_call({delete,Table,RecordToRemove},_From, State) ->
    Reply=rpc:call(node(),lib_dbase,delete,[Table,RecordToRemove],5*1000),
    {reply, Reply, State};

handle_call({update,Table,RecordToUpdate,EntryNum,NewData},_From, State) ->
    Reply=rpc:call(node(),lib_dbase,update,[Table,RecordToUpdate,EntryNum,NewData],5*1000),
    {reply, Reply, State};

handle_call({do_qlc,Table},_From, State) ->
    Reply=rpc:call(node(),lib_dbase,do_qlc,[Table],5*1000),
    {reply, Reply, State};

handle_call({load_from_file,Module,Dir,yes},_From, State) ->
    ok=rpc:call(node(),Module,create_table,[],5*1000),
    AllData=rpc:call(node(),Module,data_from_file,[Dir],5*1000),
    CreateResult=[rpc:call(node(),Module,create,[Data],5*1000)||Data<-AllData],
    Reply=case [R||R<-CreateResult,R/=ok] of
	      []->
		  ok;
	      ErrorList->
		  log:log(?logger_info(ticket,"Create failed ",[ErrorList])),
		  ErrorList
	  end,
    {reply, Reply, State};

handle_call({load_from_file,Module,na,no},_From, State) ->
    Reply=rpc:call(node(),Module,create_table,[],5*1000),
    {reply, Reply, State};


handle_call({init_dynamic},_From, State) ->
    Reply=rpc:call(node(),dbase,dynamic_db_init,[[]],5*1000),
    {reply, Reply, State};

handle_call({add_dynamic,Node},_From, State) ->
    Reply=rpc:call(Node,dbase,dynamic_db_init,[[node()]],5*1000),
    {reply, Reply, State};

handle_call({dynamic_load_table,Node,Module},_From, State) ->
    Reply=rpc:call(Node,dbase,dynamic_load_table,[Module],5*1000),
    {reply, Reply, State};

handle_call({loaded},_From, State) ->
    Reply=State#state.loaded,
    {reply, Reply, State};

handle_call({stop}, _From, State) ->
    mnesia:stop(),
    mnesia:del_table_copy(schema,node()),
    mnesia:delete_schema([node()]),
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    Reply = {unmatched_signal,?MODULE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{Msg,?MODULE,?LINE}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(Info, State) ->
    io:format("unmatched match~p~n",[{Info,?MODULE,?LINE}]), 
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
