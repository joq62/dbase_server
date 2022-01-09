%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(prototype_test).   
   
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
    io:format("~p~n",[{"Stop setup",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start cluster_start()()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=cluster_start(),
%    io:format("~p~n",[{"Stop cluster_start()",?MODULE,?FUNCTION_NAME,?LINE}]),


    io:format("~p~n",[{"Start app_simulation()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=app_simulation_1(),
    io:format("~p~n",[{"Stop app_simulation()",?MODULE,?FUNCTION_NAME,?LINE}]),
    

 %   io:format("~p~n",[{"Start load_texfile()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=load_texfile(),
 %   io:format("~p~n",[{"Stop load_texfile()",?MODULE,?FUNCTION_NAME,?LINE}]),
    
  %  io:format("~p~n",[{"Start add_db_test1()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok= add_db_test1(),
  %  io:format("~p~n",[{"Stop  add_db_test1()",?MODULE,?FUNCTION_NAME,?LINE}]),

  %  io:format("~p~n",[{"Start stop_restart()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok= stop_restart(),
  %  io:format("~p~n",[{"Stop  stop_restart()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   
      %% End application tests
  %  io:format("~p~n",[{"Start cleanup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cleanup(),
  %  io:format("~p~n",[{"Stop cleaup",?MODULE,?FUNCTION_NAME,?LINE}]),
   
    io:format("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.
 %  io:format("application:which ~p~n",[{application:which_applications(),?FUNCTION_NAME,?MODULE,?LINE}]),

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
app_simulation_1()->
    [N0,N1,N2]=get_nodes(),  
    TableTextFiles=[{fruit,ram_copies,"test_src/fruit.con"},
		    {vegetable,ram_copies,"test_src/fruit.con"},
		    {host,ram_copies,"test_src/host.config"}],    
    AppsTables=glukr,
    %% First Kubelete starts
    {ok,_}=sd:start(),
    ok=application:set_env([{dbase_infra,[{dbase_app,dbase_infra}]}]),
    ok=application:start(dbase_infra),
%    io:format("#0 mnesia:system_info() ~p~n",[{mnesia:system_info(),?FUNCTION_NAME,?MODULE,?LINE}]),
   
        
    %% Second Kubelet starts
    {ok,_}=rpc:call(N0,sd,start,[],5000),
    ok=rpc:call(N0,application,set_env,[[{dbase_infra,[{dbase_app,dbase_infra}]}]],5000),
    ok=rpc:call(N0,application,start,[dbase_infra],5000),  
 %   io:format("#1 mnesia:system_info() ~p~n",[{[rpc:call(N,mnesia,system_info,[],5000)|| N<-sd:get(mnesia)],?FUNCTION_NAME,?MODULE,?LINE}]),
   

    %% Application on first nod adds its tables 
    [{host0@c100,fruit,{atomic,ok}},
     {host0@c100,host,{atomic,ok}},
     {host0@c100,vegetable,{atomic,ok}}]=lists:sort(dbase:load_textfile(TableTextFiles)),
    
  %  io:format("#11 mnesia:system_info() ~p~n",[{rpc:call(node(),mnesia,system_info,[],5000),?FUNCTION_NAME,?MODULE,?LINE}]),

    not_attached=db_host:status({"c200","host"}),
   
    %% Second nodes App add is tables 
    [{test@c100,fruit,{aborted,{already_exists,fruit,test@c100}}},
     {test@c100,host,{aborted,{already_exists,host,test@c100}}},
     {test@c100,vegetable,{aborted,{already_exists,vegetable,test@c100}}}]=lists:sort(rpc:call(N0,dbase,load_textfile,[TableTextFiles],5000)),
   
%    io:format("#12 mnesia:system_info() ~p~n",[{[{N,rpc:call(N,mnesia,system_info,[],5000)}|| N<-sd:get(mnesia)],?FUNCTION_NAME,?MODULE,?LINE}]),
    
    [not_attached,
     not_attached]=[rpc:call(N,db_host,status,[{"c200","host"}],5000)|| N<-sd:get(mnesia)],
   
    {atomic,ok}=db_host:update_status({"c200","host"},"#1_connected"),

   ["#1_connected",
    "#1_connected"]=[rpc:call(N,db_host,status,[{"c200","host"}],5000)|| N<-sd:get(mnesia)],

%% Add third node
    {ok,_}=rpc:call(N1,sd,start,[],5000),
    ok=rpc:call(N1,application,set_env,[[{dbase_infra,[{dbase_app,dbase_infra}]}]],5000),
    ok=rpc:call(N1,application,start,[dbase_infra],5000),  
    %% App add is tables 
   
   [{host0@c100,fruit,
     {aborted,{already_exists,fruit,host0@c100}}},
    {host0@c100,host,{aborted,{already_exists,host,host0@c100}}},
    {host0@c100,vegetable,
     {aborted,{already_exists,vegetable,host0@c100}}},
    {test@c100,fruit,{aborted,{already_exists,fruit,test@c100}}},
    {test@c100,host,{aborted,{already_exists,host,test@c100}}},
    {test@c100,vegetable,
     {aborted,{already_exists,vegetable,test@c100}}}]=lists:sort(rpc:call(N1,dbase,load_textfile,[TableTextFiles],5000)),
    
  %  io:format("#13 mnesia:system_info() ~p~n",[{[{N,rpc:call(N,mnesia,system_info,[],5000)}|| N<-sd:get(mnesia)],?FUNCTION_NAME,?MODULE,?LINE}]),
  

    ["#1_connected","#1_connected","#1_connected"]=[rpc:call(N,db_host,status,[{"c200","host"}],5000)|| N<-sd:get(mnesia)],
    
   {atomic,ok}=rpc:call(N0,db_host,update_status,[{"c200","host"},"#2_connected"],5000), 
    
    
    ["#2_connected","#2_connected","#2_connected"]=[rpc:call(N,db_host,status,[{"c200","host"}],5000)|| N<-sd:get(mnesia)],

  %% Add fourth node'
    {ok,_}=rpc:call(N2,sd,start,[],5000),
    ok=rpc:call(N2,application,set_env,[[{dbase_infra,[{dbase_app,dbase_infra}]}]],5000),
    ok=rpc:call(N2,application,start,[dbase_infra],5000),  
    %% App add is tables 
   [{host0@c100,fruit,
     {aborted,{already_exists,fruit,host0@c100}}},
    {host0@c100,host,{aborted,{already_exists,host,host0@c100}}},
    {host0@c100,vegetable,
     {aborted,{already_exists,vegetable,host0@c100}}},
    {host1@c100,fruit,
     {aborted,{already_exists,fruit,host1@c100}}},
    {host1@c100,host,{aborted,{already_exists,host,host1@c100}}},
    {host1@c100,vegetable,
     {aborted,{already_exists,vegetable,host1@c100}}},
    {test@c100,fruit,{aborted,{already_exists,fruit,test@c100}}},
    {test@c100,host,{aborted,{already_exists,host,test@c100}}},
    {test@c100,vegetable,
     {aborted,{already_exists,vegetable,test@c100}}}]=lists:sort(rpc:call(N2,dbase,load_textfile,[TableTextFiles],5000)),
    
  %  io:format("#14 mnesia:system_info() ~p~n",[{[{N,rpc:call(N,mnesia,system_info,[],5000)}|| N<-sd:get(mnesia)],?FUNCTION_NAME,?MODULE,?LINE}]),
      ["#2_connected",
       "#2_connected",
       "#2_connected",
       "#2_connected"]=[rpc:call(N,db_host,status,[{"c200","host"}],5000)|| N<-sd:get(mnesia)],

   

 %  io:format("#2 mnesia:system_info() ~p~n",[{[rpc:call(N,mnesia,system_info,[],5000)|| N<-sd:get(mnesia)],?FUNCTION_NAME,?MODULE,?LINE}]),
    io:format("#21 mnesia:system_info() ~p~n",[{rpc:call(N2,mnesia,system_info,[],5000),?FUNCTION_NAME,?MODULE,?LINE}]),

    %% Kill N1
    slave:stop(N1),
  %  io:format("#3 mnesia:system_info() ~p~n",[{[rpc:call(N,mnesia,system_info,[],5000)|| N<-sd:get(mnesia)],?FUNCTION_NAME,?MODULE,?LINE}]),
 %   io:format("#31 mnesia:system_info() ~p~n",[{rpc:call(node(),mnesia,system_info,[],5000),?FUNCTION_NAME,?MODULE,?LINE}]),
  
    ["#2_connected",
     "#2_connected",
     "#2_connected"]=[rpc:call(N,db_host,status,[{"c200","host"}],5000)|| N<-sd:get(mnesia)],
    {atomic,ok}=rpc:call(N2,db_host,update_status,[{"c200","host"},"#3_connected"],5000), 
    %% Restart N1
    {ok,N1}=start_slave("host1"),
    {ok,_}=rpc:call(N1,sd,start,[],5000),
    ok=rpc:call(N1,application,set_env,[[{dbase_infra,[{dbase_app,dbase_infra}]}]],5000),
    ok=rpc:call(N1,application,start,[dbase_infra],5000),  
    %% App add is tables 
    [{host0@c100,fruit,
      {aborted,{already_exists,fruit,host0@c100}}},
     {host0@c100,host,{aborted,{already_exists,host,host0@c100}}},
     {host0@c100,vegetable,
      {aborted,{already_exists,vegetable,host0@c100}}},
     {host2@c100,fruit,
      {aborted,{already_exists,fruit,host2@c100}}},
     {host2@c100,host,{aborted,{already_exists,host,host2@c100}}},
     {host2@c100,vegetable,
      {aborted,{already_exists,vegetable,host2@c100}}},
     {test@c100,fruit,{aborted,{already_exists,fruit,test@c100}}},
     {test@c100,host,{aborted,{already_exists,host,test@c100}}},
     {test@c100,vegetable,
      {aborted,{already_exists,vegetable,test@c100}}}]=lists:sort(rpc:call(N1,dbase,load_textfile,[TableTextFiles],5000)),
    
    io:format("#15 mnesia:system_info() ~p~n",[{[{N,rpc:call(N,mnesia,system_info,[],5000)}|| N<-sd:get(mnesia)],?FUNCTION_NAME,?MODULE,?LINE}]),
    ["#3_connected",
     "#3_connected",
     "#3_connected",
     "#3_connected"]=[rpc:call(N,db_host,status,[{"c200","host"}],5000)|| N<-sd:get(mnesia)],
    

  %  init:stop(),
  %  timer:sleep(2000),

    

    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
load_texfile()->
   
    io:format("mnesia:sys info) ~p~n",[{mnesia:system_info(),?FUNCTION_NAME,?MODULE,?LINE}]),
    %% load from file 
    {atomic,ok}=mnesia:load_textfile("test_src/host.config"),
    [{"c200","host"},
     {"c201","host"},
     {"c202","host"},
     {"c203","host"}]=lists:sort(mnesia:dirty_all_keys(host)),
    {atomic,ok}=mnesia:load_textfile("test_src/fruit.con"),
    [apple,orange]=lists:sort(mnesia:dirty_all_keys(fruit)),
    

    io:format("mnesia:dirty_read ~p~n",[{mnesia:dirty_read(host,{"c200","host"}),?FUNCTION_NAME,?MODULE,?LINE}]),
    io:format("mnesia:dirty_read ~p~n",[{mnesia:dirty_read(fruit,apple),?FUNCTION_NAME,?MODULE,?LINE}]),
    
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
    Args="-pa ebin -pa test_ebin -setcookie "++Cookie,
    {ok,SNode}=slave:start(HostId,NodeName,Args),
    [net_adm:ping(N)||N<-nodes()],
    {ok,SNode}.

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
    application:stop(mnesia),
    application:unload(mnesia),

    mnesia:stop(),
    mnesia:del_table_copy(schema,node()),
    mnesia:delete_schema([node()]),
    timer:sleep(1000),
   
    
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
