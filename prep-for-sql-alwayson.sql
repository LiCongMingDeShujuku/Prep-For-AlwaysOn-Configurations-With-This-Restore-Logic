use master;
set nocount on
 
---------------------------
--BACKUP ALL DATABASES LOCALLY.  SINGLE FULL BACKUP AND SINGLE TRANSACTION LOG BACKUP PER EACH DATABASE
--备份所有本地数据库。备份每个数据库的单个全备份和单个事务日志备份
 
declare
        @sao    int = (select cast([value] as int) from master.sys.configurations where [name] = 'show advanced options')
,       @bcd    int = (select cast([value] as int) from master.sys.configurations where [name] = 'backup compression default')
,       @xpc    int = (select cast([value] as int) from master.sys.configurations where [name] = 'xp_cmdshell')
declare @backup_all_user_databases      varchar(max)
set     @backup_all_user_databases      = ''
select  @backup_all_user_databases      = @backup_all_user_databases +
'use master;'       + char(10) +
'backup database        [' + upper(sd.name) + '] to disk = ''e:\MyFullBackupsFolder\' + upper(sd.name) + '.bak''    with format;'   + char(10) +
'backup log         [' + upper(sd.name) + '] to disk = ''e:\MyLogBackupsFolder\' + upper(sd.name) + '.trn''     with format;'   + char(10) + char(10)
from
    sys.databases sd join sys.database_mirroring sdm on sd.database_id = sdm.database_id
where   
    name not in ('master', 'model', 'msdb', 'tempdb', 'reportserver', 'reportservertempdb')
    and     state_desc = 'online'
    and     sd.source_database_id   is null
    and     sdm.mirroring_role_desc is null
    or      sdm.mirroring_role_desc != 'mirror'
order by
    name asc
if      @sao = 0    begin exec  master..sp_configure 'show advanced options', 1         reconfigure end
if      @bcd = 0    begin exec  master..sp_configure 'backup compression default', 1    reconfigure end
if      @xpc = 0    begin exec  master..sp_configure 'xp_cmdshell', 1                   reconfigure end
 
exec    (@backup_all_user_databases)
 
 
 
 
 
---------------------------
--CREATE RESTORE LOGIC FOR FULL DATABASE BACKUPS.  RUN THIS AT THE DESTINATION SERVER.
--为数据库全备份创建还原逻辑（logic）。 在目标服务器上运行。
 
declare     @create_restore_database_full_logic varchar(max) 
set         @create_restore_database_full_logic = '' 
select      @create_restore_database_full_logic = @create_restore_database_full_logic + '
use master;
set nocount on
go
declare @database_name      varchar (255) 
declare @backup_file_name   varchar (255) 
set     @database_name      = ''' + replace(name, '''', '''''') + '''
set     @backup_file_name   = ''e:\MyFullBackupsFolder\' + replace(name, '''', '') + '.bak''
declare @filelistonly       table
(
    logicalname     nvarchar (128)
,   physicalname    nvarchar (260) 
,   [type]          char (1)
,   filegroupname   nvarchar (128) 
,   size            numeric (20,0) 
,   maxsize         numeric (20,0) 
,   fileid          bigint
,   createlsn       numeric (25,0) 
,   droplsn         numeric (25,0) 
,   uniqueid        uniqueidentifier
,   readonlylsn     numeric (25,0) 
,   readwritelsn    numeric (25,0) 
,   backupsizeinbytes bigint
,   sourceblocksize int
,   filegroupid     int
,   loggroupguid    uniqueidentifier
,   differentialbaselsn     numeric (25,0) 
,   differentialbaseguid    uniqueidentifier
,   isreadonl       bit
,   ispresent       bit
,   tdethumbprint   varbinary (32)
)
insert into
        @filelistonly 
exec    (''restore filelistonly from disk = '''''' + @backup_file_name + '''''''') 
 
 
declare @restore_line0  varchar (255) 
declare @restore_line1  varchar (255) 
declare @restore_line2  varchar (255) 
declare @stats          varchar (255) 
declare @move_files     varchar (max) 
set     @restore_line0  = (''use master; '')
set     @restore_line1  = (''exec master..sp_killallprocessindb '''''' + @database_name + '''''';'')
set     @restore_line2  = (select ''restore database ['' + @database_name + ''] from disk = '''''' + @backup_file_name + '''''' with replace, norecovery, '') 
set     @stats          = (''stats = 20;'')
set     @move_files     = ''''
select  @move_files     = @move_files + ''move '''''' + logicalname + '''''' to '''''' + physicalname + '''''','' + char(10) from @filelistonly order by fileid asc
  
select/**/ -- replace this line with: exec
(
    @restore_line0
+   @restore_line1
+   @restore_line2
+   @move_files
+   @stats
)
go
'
from    sys.databases 
where   name not in ('master', 'model', 'tempdb', 'msdb', 'reportserver', 'reportservertempdb') 
select  (@create_restore_database_full_logic) for xml path (''), type
 
 
 
 
---------------------------
--CREATE RESTORE LOGIC FOR TRANSACTION LOG BACKUPS.  RUN THIS AT THE DESTINATION SERVER.
--为事务日志备份创建还原逻辑（logic）。 在目标服务器上运行。
 
 
declare     @create_restore_database_logs_logic varchar(max) 
set         @create_restore_database_logs_logic = '' 
select      @create_restore_database_logs_logic = @create_restore_database_logs_logic + '
use master;
set nocount on
go
declare @database_name      varchar (255) 
declare @backup_file_name   varchar (255) 
set     @database_name      = ''' + replace(name, '''', '''''') + '''
set     @backup_file_name   = ''e:\MyLogBackupsFolder\' + replace(name, '''', '') + '.trn''
declare @filelistonly       table
(
    logicalname     nvarchar (128) 
,   physicalname    nvarchar (260) 
,   [type]          char (1)
,   filegroupname   nvarchar (128) 
,   size            numeric (20,0) 
,   maxsize         numeric (20,0) 
,   fileid          bigint
,   createlsn       numeric (25,0) 
,   droplsn         numeric (25,0) 
,   uniqueid        uniqueidentifier
,   readonlylsn     numeric (25,0) 
,   readwritelsn    numeric (25,0) 
,   backupsizeinbytes bigint
,   sourceblocksize int
,   filegroupid     int
,   loggroupguid    uniqueidentifier
,   differentialbaselsn     numeric (25,0) 
,   differentialbaseguid    uniqueidentifier
,   isreadonl       bit
,   ispresent       bit
,   tdethumbprint   varbinary (32)
)
insert into
        @filelistonly   
exec    (''restore filelistonly from disk = '''''' + @backup_file_name + '''''''')
 
 
declare @restore_line0  varchar (255) 
declare @restore_line1  varchar (255) 
declare @restore_line2  varchar (255) 
declare @stats          varchar (255) 
declare @move_files     varchar (max) 
set     @restore_line0  = (''use master; '')
set     @restore_line1  = (''exec master..sp_killallprocessindb '''''' + @database_name + '''''';'')
set     @restore_line2  = (select ''restore log ['' + @database_name + ''] from disk = '''''' + @backup_file_name + '''''' with norecovery, '') 
set     @stats          = (''stats = 5;'')
  
--select/**/ -- replace this line with: exec
--用exec替换这行代码
(
    @restore_line0
+   @restore_line1
+   @restore_line2
+   @stats
)
go
'
from    sys.databases 
where   name not in ('master', 'model', 'tempdb', 'msdb', 'reportserver', 'reportservertempdb') 
select  (@create_restore_database_logs_logic) for xml path (''), type
