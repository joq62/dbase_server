%% Author: uabjle
%% Created: 10 dec 2012
%% Description: TODO: Add description to application_org
-module(dbase). 
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("dbase_spec.hrl").
%% --------------------------------------------------------------------
%% Behavioural exports
%% --------------------------------------------------------------------

-export([
	 create/1,
	 update/4,
	 delete/2,
	 do_qlc/1
	]).
-export([
	 
	 load_from_file/3,
	 init_dynamic/0,
	 add_dynamic/1,
	 dynamic_load_table/2
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

create(Record)->
     gen_server:call(?SERVER,{create,Record},infinity).

delete(Table,RecordToRemove)->
    gen_server:call(?SERVER,{delete,Table,RecordToRemove},infinity).
update(Table,RecordToUpdate,EntryNum,NewData)->
    gen_server:call(?SERVER,{update,Table,RecordToUpdate,EntryNum,NewData},infinity).
do_qlc(Table)->
     gen_server:call(?SERVER,{do_qlc,Table},infinity).

load_from_file(Module,Dir,Directive)->
    gen_server:call(?SERVER, {load_from_file,Module,Dir,Directive},infinity).

init_dynamic()->
    gen_server:call(?SERVER, {init_dynamic},infinity).
add_dynamic(Node)->
    gen_server:call(?SERVER, {add_dynamic,Node},infinity).
dynamic_load_table(Node,Module)->
    gen_server:call(?SERVER,{dynamic_load_table,Node,Module},infinity).


%% ====================================================================
%% Internal functions
%% ====================================================================

