%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(db_logger_test).   
      
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("controller.hrl").
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
%create(DateTime,Node,Severity,Msg,M,F,L,A)
-define(logger_info(Severity,Msg,Args),
	{date(),time(),node(),Severity,Msg,?MODULE,?FUNCTION_NAME,?LINE,Args,new}).
start()->
   
  
    L1=?logger_info(alert,"test1",[]),
    L2=?logger_info(alert,"test2",[23,76]),
    L3=?logger_info(ticket,"test3",[]),
    L4=?logger_info(info,"server started",[]),

    ok=db_logger:create(L1),
    ok=db_logger:create(L2),
    ok=db_logger:create(L3),
    ok=db_logger:create(L4),
    SortedList=lists:reverse(lists:sort(mnesia:dirty_all_keys(logger_info))),
    4=lists:flatlength(mnesia:dirty_all_keys(logger_info)),    
    [db_logger:nice_print(Id)||Id<-SortedList],
    io:format(" mellanrum ~n"),

    [db_logger:nice_print(Id)||Id<-lists:sublist(SortedList,2)],
    

    
    
   
    ok. 

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
