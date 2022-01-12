%% Author: uabjle
%% Created: 10 dec 2012
%% Description: TODO: Add description to application_org
-module(dbase). 
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Behavioural exports
%% --------------------------------------------------------------------

-export([
	 dynamic_db_init/1,
	 load_textfile/1,
	 dynamic_add_table/2,
	 ping/0
	]).



-export([

	]).


%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([start/0,
	 stop/0]).
%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------
-define(SERVER,dbase_server).
%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% API Functions
%% --------------------------------------------------------------------


%% ====================================================================!
%% External functions
%% ====================================================================!

%% --------------------------------------------------------------------
%% Func: start/2
%% Returns: {ok, Pid}        |
%%          {ok, Pid, State} |
%%          {error, Reason}
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Func: start/2
%% Returns: {ok, Pid}        |
%%          {ok, Pid, State} |
%%          {error, Reason}
%% --------------------------------------------------------------------
start()-> gen_server:start_link({local, ?SERVER}, ?SERVER, [], []).
stop()-> gen_server:call(?SERVER, {stop},infinity).
ping()-> gen_server:call(?SERVER, {ping},infinity).


dynamic_db_init(DbaseNodeList)->
    gen_server:call(?SERVER, {dynamic_db_init,DbaseNodeList},infinity).

load_textfile(TableTextFiles)->
    gen_server:call(?SERVER, {load_textfile,TableTextFiles},infinity).
dynamic_add_table(Table,StorageType)->
    gen_server:call(?SERVER, {dynamic_add_table,Table,StorageType},infinity). 



%% ====================================================================
%% Internal functions
%% ====================================================================

