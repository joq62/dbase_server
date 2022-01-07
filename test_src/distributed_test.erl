%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(distributed_test).   
   
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
    
    io:format("~p~n",[{"Start add_db_test1()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok= add_db_test1(),
    io:format("~p~n",[{"Stop  add_db_test1()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start stop_restart()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok= stop_restart(),
    io:format("~p~n",[{"Stop  stop_restart()",?MODULE,?FUNCTION_NAME,?LINE}]),

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

stop_restart()->
    [N1,N2,N3]=get_nodes(),
    slave:stop(N2),
    io:format("Slave stopped ~n"),
    [io:format("#211 ~p~n",[{N,rpc:call(node(),db_host,read_all,[N],5*1000)}])||N<-get_nodes()],
    [io:format("#212 ~p~n",[{N,rpc:call(node(),db_test1,read_all_record,[N],5*1000)}])||N<-get_nodes()],

    {ok,N2}=start_slave("host1"),
    io:format("Slave restarted ~n"),
    {ok,_DbasePid2}=rpc:call(N2,dbase,start,[],5*1000),    
    RunningDbaseNodes2=[N1,N3],
    ok=rpc:call(N2,lib_dbase,dynamic_db_init,[RunningDbaseNodes2],5*1000),
    db_test1:add_table(N2),
    [io:format("#220 ~p~n",[{N,rpc:call(node(),db_host,read_all,[N],5*1000)}])||N<-get_nodes()],
    [io:format("#221 ~p~n",[{N,rpc:call(node(),db_test1,read_all_record,[N],5*1000)}])||N<-get_nodes()],
  %  [io:format("#222 ~p~n",[{N,rpc:call(N,mnesia,system_info,[],2*1000)}])||N<-get_nodes()],

    init:stop(),
    timer:sleep(2000),    
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
add_db_test1()->
    [N1,N2,N3]=get_nodes(),
    [io:format("#100 ~p~n",[{N,rpc:call(node(),db_host,read_all,[N],5*1000)}])||N<-get_nodes()],

    %% 
    ok=db_test1:create_table(N2),
    [io:format("#110 ~p~n",[{N,rpc:call(N,mnesia,system_info,[],2*1000)}])||N<-get_nodes()],
    db_test1:add_table(N1),
    db_test1:add_table(N3),
    {atomic,ok}=db_test1:create(N1,{term11,term12}),

   
   % make so it becomes a copy note only remote

    [io:format("#111 ~p~n",[{N,rpc:call(node(),db_host,read_all,[N],5*1000)}])||N<-get_nodes()],
    [io:format("#112 ~p~n",[{N,rpc:call(node(),db_test1,read_all_record,[N],5*1000)}])||N<-get_nodes()],

    [io:format("#113 ~p~n",[{N,rpc:call(N,mnesia,system_info,[],2*1000)}])||N<-get_nodes()],


    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
initial()->
    [N1,N2,N3]=get_nodes(),
    %% intial node
    {ok,_DbasePid1}=rpc:call(N1,dbase,start,[],5*1000),
    RunningDbaseNodes1=[],
    ok=rpc:call(N1,dbase,dynamic_db_init,[RunningDbaseNodes1],5*1000),    
    ok=db_host:create_table(N1),
    {atomic,ok}=db_host:create(N1,{id1,access1,type1,startargs1,dirs1,appdir1,capa1,status1}),
    [io:format("#10 ~p~n",[{N,rpc:call(N,mnesia,system_info,[tables],2*1000)}])||N<-get_nodes()],
    [io:format("#11 ~p~n",[{N,rpc:call(node(),db_host,read_all,[N],5*1000)}])||N<-get_nodes()],

    %% Second node
    {ok,_DbasePid2}=rpc:call(N2,dbase,start,[],5*1000),    
    RunningDbaseNodes2=[N1],
    ok=rpc:call(N2,lib_dbase,dynamic_db_init,[RunningDbaseNodes2],5*1000),    
    [io:format("#20 ~p~n",[{N,rpc:call(N,mnesia,system_info,[tables],2*1000)}])||N<-get_nodes()],
    {atomic,ok}=db_host:create(N2,{id2,access2,type2,startargs2,dirs2,appdir2,capa2,status2}),
    [io:format("#21 ~p~n",[{N,rpc:call(node(),db_host,read_all,[N],5*1000)}])||N<-get_nodes()],

    %% Third node

    {ok,_DbasePid3}=rpc:call(N3,dbase,start,[],5*1000),    
    RunningDbaseNodes3=[N1,N2],
    ok=rpc:call(N3,lib_dbase,dynamic_db_init,[RunningDbaseNodes3],5*1000),
    [io:format("#30 ~p~n",[{N,rpc:call(N,mnesia,system_info,[tables],2*1000)}])||N<-get_nodes()],
    {atomic,ok}=db_host:create(N2,{id3,access3,type3,startargs3,dirs3,appdir3,capa3,status3}),
    [io:format("#31 ~p~n",[{N,rpc:call(node(),db_host,read_all,[N],5*1000)}])||N<-get_nodes()],

    %% Update
    {atomic,ok}=db_host:update(N2,id3,status,working),
    [io:format("#40 ~p~n",[{N,rpc:call(node(),db_host,read_all,[N],5*1000)}])||N<-get_nodes()],
    
    %% Delete 
    {atomic,ok}=db_host:delete(N1,id2),
    [io:format("#50 ~p~n",[{N,rpc:call(node(),db_host,read_all,[N],5*1000)}])||N<-get_nodes()],
   
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
