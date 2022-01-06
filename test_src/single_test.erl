%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(single_test).   
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------

%% External exports
-export([start/0]). 


%% ====================================================================
%% External functions
%% ====================================================================


%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start()->
  %  io:format("~p~n",[{"Start setup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=setup(),
  %  io:format("~p~n",[{"Stop setup",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start cluster_start()()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=cluster_start(),
%    io:format("~p~n",[{"Stop cluster_start()",?MODULE,?FUNCTION_NAME,?LINE}]),


    io:format("~p~n",[{"Start initial()()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=initial(),
    io:format("~p~n",[{"Stop initial()()",?MODULE,?FUNCTION_NAME,?LINE}]),


 %   
      %% End application tests
  %  io:format("~p~n",[{"Start cleanup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cleanup(),
  %  io:format("~p~n",[{"Stop cleaup",?MODULE,?FUNCTION_NAME,?LINE}]),
   
    io:format("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
initial()->
  
    [N1|_]=get_nodes(),
    %% Start Dbase
    {ok,_DbasePid}=rpc:call(N1,dbase,start,[],5*1000),    
    io:format("#1 N1 ~p~n",[{rpc:call(N1,mnesia,system_info,[tables],2*1000)}]),

    %% create db_host
    ok=db_host:create_table(N1),
    io:format("#2 N1 ~p~n",[{rpc:call(N1,mnesia,system_info,[tables],2*1000)}]),    

    %{Id,AccessInfo,Type,StartArgs,DirsToKeep,AppDir,Capabilities,Status}
    {atomic,ok}=db_host:create(N1,{id1,access1,type1,startargs1,dirs1,appdir1,capa1,status1}),
    {atomic,ok}=db_host:create(N1,{id2,access2,type2,startargs2,dirs2,appdir2,capa2,status2}),
    
    io:format("#1 read_all_records ~p~n",[db_host:read_all_record(N1)]),   
    io:format("#1 read_all ~p~n",[db_host:read_all(N1)]),    
    io:format("#1 read(id2) ~p~n",[db_host:read(N1,id2)]),    
    
    {atomic,ok}=db_host:update(N1,id1,status,glurk),
    io:format("#2 read(id1) ~p~n",[db_host:read(N1,id1)]),        

    {atomic,ok}=db_host:delete(N1,id1),
    io:format("read_all ~p~n",[db_host:read_all(N1)]),    
    
    
    %%
    
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
get_nodes()->
    HostId=net_adm:localhost(),
    A="host0@"++HostId,
    Node0=list_to_atom(A),
    B="host1@"++HostId,
    Node1=list_to_atom(B),
    C="host2@"++HostId,
    Node2=list_to_atom(C),    
    [Node0,Node1,Node2].
    
start_slave(NodeName)->
    HostId=net_adm:localhost(),
    Node=list_to_atom(NodeName++"@"++HostId),
    rpc:call(Node,init,stop,[]),
    Cookie=atom_to_list(erlang:get_cookie()),
    Args="-pa ebin -setcookie "++Cookie,
    slave:start(HostId,NodeName,Args).

setup()->
    HostId=net_adm:localhost(),
    A="host0@"++HostId,
    Node0=list_to_atom(A),
    B="host1@"++HostId,
    Node1=list_to_atom(B),
    C="host2@"++HostId,
    Node2=list_to_atom(C),    
    Nodes=[Node0,Node1,Node2],
    [rpc:call(N,init,stop,[],5*1000)||N<-Nodes],
    timer:sleep(2000),
    [{ok,Node0},
     {ok,Node1},
     {ok,Node2}]=[start_slave(NodeName)||NodeName<-["host0","host1","host2"]],
    [net_adm:ping(N)||N<-Nodes],
    mnesia:stop(),
    mnesia:del_table_copy(schema,node()),
    mnesia:delete_schema([node()]),
    timer:sleep(1000),
    {ok,_}=sd:start(),
      
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------    

cleanup()->
    mnesia:stop(),
    mnesia:del_table_copy(schema,node()),
    mnesia:delete_schema([node()]),
    timer:sleep(1000),
    [slave:stop(Node)||Node<-get_nodes()],
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
