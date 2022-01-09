-module(db_host).
-import(lists, [foreach/2]).
%-compile(export_all).
-export([
	 status/0,
	 status/1,
	 hosts/0,
	 ids/0,
	 hostname/1,
	 start_args/1,
	 type/1,
	 dirs_to_keep/1,
	 application_dir/1,
	 ip/1,
	 port/1,
	 uid/1,
	 passwd/1,
	 erl_cmd/1,
	 env_vars/1,
	 cookie/1,
	 nodename/1,
	 update_status/2	 
	]).


-export([
	 data_from_file/1,
	 create_table/0,
	 delete_table_copy/1,
	 create/1,
	 add_table/1,
	 add_table/2,
	 add_node/3,
	 read_all_record/0,
	 read_all/0,
	 read_record/1,
	 read/1,
	 delete/1	 
	]).


-include_lib("stdlib/include/qlc.hrl").

-define(TABLE,host).
-define(RECORD,host). 
-record(host,
	{id,
	 hostname,
	 ip,
	 ssh_port,
	 uid,
	 pwd,
	 type,
	 start_args,
	 dirs_to_keep,
	 application_dir,
	 capabilities,
	 status
	}).

%%------------------------- Application specific commands ----------------
status()->
    AllRecords=read_all_record(),
    [{X#?RECORD.id,X#?RECORD.status}||X<-AllRecords].
status(Id)->
    Record=read_record(Id),
    Record#?RECORD.status.

hosts()->
    AllRecords=read_all_record(),
    [Host||{Host,_}<-[X#?RECORD.id||X<-AllRecords]].

ids()->
    AllRecords=read_all_record(),
    [Id||Id<-[X#?RECORD.id||X<-AllRecords]].

hostname(Id)->
    Record=read_record(Id),
    {HostName,_}=Record#?RECORD.id,
    HostName.

start_args(Id)->
    Record=read_record(Id),
    Record#?RECORD.start_args.

type(Id)->
    Record=read_record(Id),
    Record#?RECORD.type.

dirs_to_keep(Id)->
    Record=read_record(Id),
    Record#?RECORD.dirs_to_keep.

application_dir(Id)->
    Record=read_record(Id),
    Record#?RECORD.application_dir.

ip(Id)->
      Record=read_record(Id),
    Record#?RECORD.ip.
port(Id)->
    Record=read_record(Id),
    Record#?RECORD.ssh_port.
uid(Id)->
     Record=read_record(Id),
    Record#?RECORD.uid.
passwd(Id)->
    Record=read_record(Id),
    Record#?RECORD.pwd.

erl_cmd(Id)->
    I=start_args(Id),
    proplists:get_value(erl_cmd,I).
env_vars(Id)->
    I=start_args(Id),
    proplists:get_value(env_vars,I).
cookie(Id)->
    I=start_args(Id),
    proplists:get_value(cookie,I).
nodename(Id)->
    I=start_args(Id),
    proplists:get_value(nodename,I).

    
%%------------------------- Generic  dbase commands ----------------------
create_table()->
    {atomic,ok}=mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)}]),
    mnesia:wait_for_tables([?TABLE], 20000).
delete_table_copy(Dest)->
    mnesia:del_table_copy(?TABLE,Dest).

create({Id,HostName,Ip,SshPort,Uid,Pwd,Type,StartArgs,DirsKeep,AppDir,Capabilities,Status}) ->
%   io:format("create ~p~n",[{HostName,AccessInfo,Type,StartArgs,DirsToKeep,AppDir,Status}]),
    F = fun() ->
		Record=#?RECORD{
				id=Id,
				hostname=HostName,
				ip=Ip,
				ssh_port=SshPort,
				uid=Uid,
				pwd=Pwd,
				type=Type,
				start_args=StartArgs,
				dirs_to_keep=DirsKeep,
				application_dir=AppDir,
				capabilities=Capabilities,
				status=Status
			       },		
		mnesia:write(Record) end,
    case mnesia:transaction(F) of
	{atomic,ok}->
	    ok;
	ErrorReason ->
	    ErrorReason
    end.

add_table(Node,StorageType)->
    mnesia:add_table_copy(?TABLE, Node, StorageType).


add_table(StorageType)->
    mnesia:add_table_copy(?TABLE, node(), StorageType),
    Tables=mnesia:system_info(tables),
    mnesia:wait_for_tables(Tables,20*1000).

add_node(Dest,Source,StorageType)->
    mnesia:del_table_copy(schema,Dest),
    mnesia:del_table_copy(?TABLE,Dest),
    io:format("Node~p~n",[{Dest,Source,?FUNCTION_NAME,?MODULE,?LINE}]),
    Result=case mnesia:change_config(extra_db_nodes, [Dest]) of
	       {ok,[Dest]}->
		 %  io:format("add_table_copy(schema) ~p~n",[{Dest,Source, mnesia:add_table_copy(schema,Source,StorageType),?FUNCTION_NAME,?MODULE,?LINE}]),
		   mnesia:add_table_copy(schema,Source,StorageType),
		%   io:format("add_table_copy(table) ~p~n",[{Dest,Source, mnesia:add_table_copy(?TABLE,Dest,StorageType),?FUNCTION_NAME,?MODULE,?LINE}]),
		   mnesia:add_table_copy(?TABLE, Source, StorageType),
		   Tables=mnesia:system_info(tables),
		%   io:format("Tables~p~n",[{Tables,Dest,node(),?FUNCTION_NAME,?MODULE,?LINE}]),
		   mnesia:wait_for_tables(Tables,20*1000),
		   ok;
	       Reason ->
		   Reason
	   end,
    Result.

read_all_record()->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    Result=case Z of
	       {aborted,Reason}->
		   {aborted,Reason};
	       _->
		   Z
	   end,
    Result.
read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    Result=case Z of
	       {aborted,Reason}->
		   {aborted,Reason};
	       _->
		   [{Id,HostName,Ip,SshPort,Uid,Pwd,Type,StartArgs,DirsKeep,AppDir,Capabilities,Status}||
		       {?RECORD,Id,HostName,Ip,SshPort,Uid,Pwd,Type,StartArgs,DirsKeep,AppDir,Capabilities,Status}<-Z]
	   end,
    Result.

read_record(Object) ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		   X#?RECORD.id==Object])),
    Result=case Z of
	       {aborted,Reason}->
		   {error,Reason};
	       []->
		   {error,[eexists, Object]};
	       [X]->
		   X
	   end,
    Result.

read(Object) ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		   X#?RECORD.id==Object])),
    Result=case Z of
	       {aborted,Reason}->
		   {aborted,Reason};
	       []->
		   {error,[eexists, Object]};
	       _->
		   [R]=[{Id,HostName,Ip,SshPort,Uid,Pwd,Type,StartArgs,DirsKeep,AppDir,Capabilities,Status}||
			   {?RECORD,Id,HostName,Ip,SshPort,Uid,Pwd,Type,StartArgs,DirsKeep,AppDir,Capabilities,Status}<-Z],
		   R
	   end,
    Result.

delete(Object) ->
    F = fun() -> 
		RecordList=[X||X<-mnesia:read({?TABLE,Object}),
			    X#?RECORD.id==Object],
		case RecordList of
		    []->
			mnesia:abort(?TABLE);
		    [S1]->
			mnesia:delete_object(S1) 
		end
	end,
    mnesia:transaction(F).
update_status(Object,NewStatus)->
 F = fun() -> 
	     RecordList=do(qlc:q([X || X <- mnesia:table(?TABLE),
				       X#?RECORD.id==Object])),
	     case RecordList of
		 []->
		     mnesia:abort(?TABLE);
		 [S1]->
		     NewRecord=S1#?RECORD{status=NewStatus},
		     mnesia:delete_object(S1),
		     mnesia:write(NewRecord)
	     end
		 
     end,
    mnesia:transaction(F).
    

do(Q) ->
    F = fun() -> qlc:e(Q) end,
    Result=case mnesia:transaction(F) of
	       {atomic, Val}->
		   Val;
	       Error->
		   Error
	   end,
    Result.

%%--------------------------------------------------------------------
-define(Extension,".host").
data_from_file(Dir)->
    {ok,Files}=file:list_dir(Dir),
    HostFiles=[File||File<-Files,
		     ?Extension=:=filename:extension(File)],
    HostFileNames=[filename:join(Dir,File)||File<-HostFiles],
    data(HostFileNames).
    

data(HostFileNames)->
    data(HostFileNames,[]).
data([],List)->
   % io:format("List ~p~n",[List]),
    List;
data([HostFile|T],Acc)->
    {ok,I}=file:consult(HostFile),
    Id=proplists:get_value(id,I),
    HostName=proplists:get_value(hostname,I),
    Ip=proplists:get_value(ip,I),
    SshPort=proplists:get_value(ssh_port,I),
    Uid=proplists:get_value(uid,I),
    Pwd=proplists:get_value(pwd,I),
    StartArgs=proplists:get_value(start_args,I),
    Type=proplists:get_value(host_type,I),
    DirsKeep=proplists:get_value(dirs_to_keep,I),
    AppDir=proplists:get_value(application_dir,I),
    Capabilities=proplists:get_value(capabilities,I),
    Status=stopped,
   % io:format("~p~n",[{HostName,AccessInfo,Type,StartArgs,DirsToKeep,AppDir,Status}]),
    NewAcc=[{Id,HostName,Ip,SshPort,Uid,Pwd,Type,StartArgs,DirsKeep,AppDir,Capabilities,Status}|Acc],
    data(T,NewAcc).

