![CLEVER DATA GIT REPO](https://raw.githubusercontent.com/LiCongMingDeShujuku/git-resources/master/0-clever-data-github.png "李聪明的数据库")

# 用这个还原逻辑为AlwaysOn配置做好准备
#### Prep For AlwaysOn Configurations With This Restore Logic
**发布-日期: 2016年3月21日 (评论)**

![#](images/##############?raw=true "#")

## Contents
- [SQL Logic](#Logic)
- [Build Info](#Build-Info)
- [Author](#Author)
- [License](#License) 


The following SQL logic will backup all databases excluding (‘master’, ‘model’, ‘msdb’, ‘tempdb’, ‘reportserver’, ‘reportservertempdb’), then it will produce 2 restore scripts. Restore Full Database Backups, and Restore Transaction Logs. The restore scripts will restore WITH NORECOVERY leaving the databases ready for the AlwaysOn configurations.

Here’s what the produced SQL logic will do:
1. Sets the Default Backup Compression before the databases are backed up.
2. Creates a single Full Database backup (for all databases) to: e:\MyFullBackupsFolder\
3. Creates a single Transaction Log backup (for all databases) to: e:\MyLogBackupsFolder\
4. Procues a Database Restore Script in the form of an XML link. Once clicked you’ll see the entire restore logic for all database backups.
5. Produces a Transaction Log Restore Script in the form of an XML Link. Once clicked you’ll see the entire restore logic for all transaction log backups.

以下的SQL逻辑将备份除了（'master'，'model'，'msdb'，'tempdb'，'reportserver'，'reportservertempdb'）之外的所有数据库，然后它将生成2个还原脚本。还原完整数据库备份和还原事务日志。还原脚本将还原WITH NORECOVERY，使数据库为AlwaysOn配置做好准备。

以下是生成的SQL逻辑将执行的操作：
1.	在备份数据库之前设置默认备份压缩。
2.	创建单个完整数据库备份（适用于所有数据库）到：e：\ MyFullBackupsFolder \
3.	创建单个事务日志备份（对于所有数据库）到：e：\ MyLogBackupsFolder \
4.	以XML链接的形式生成数据库还原脚本。 单击后，将看到所有数据库备份的整个还原逻辑（logic）。
5.	以XML链接的形式生成事务日志还原脚本。 单击后，将看到所有事务日志备份的整个还原逻辑（logic）。

Note: The logic will only backup databases that have an ONLINE status, and ensures the databases that are backed up are not part of a secondary, or set as a ‘Mirrors’ of an existing Database Mirror scheme. However the databases will be backup Principal databases if they exist. This is quite helpful if you are moving AlwaysOn or Mirrored databases to other servers.
Additionally; it doesn’t matter how many data files you have under each database. The logical and physical paths are read directly from the FILELISTONLY results per each backup file so all files should be addressed during the restore. This will also restore the data files in their normal hierarchy where the first data, and first log files are restored, then subsequent .trn’s or fulltext data files are hit next. This will avoid any precedence failures that might occur.

注意：逻辑仅备份具有ONLINE状态的数据库，并确认备份的数据库不是辅助数据库的一部分，或者设置为现有数据库镜像方案的“镜像”。 但是，如果数据库存在，则它们将是备份主体数据库。如果可以将AlwaysOn或Mirrored
数据库移动到其他服务器，会非常有用。
另外,每个数据库下有多少个数据文件并不影响。 逻辑和物理路径直接从每个备份文件的FILELISTONLY结果中读取，因此所有文件在修复期间都会被处理。还将恢复数据文件到其第一个数据和第一个日志文件被恢复的一般层次
结构中，然后下一个是.trn或全文数据文件， 这可以避免发生任何优先级故障。

Ok so how does this work? What do I need to do for this to run?
First; disable any transaction log backups you are currently running on any regular schedule. If a transaction log backup runs while this process is carried out it will through off the LSN’s and the subsequent transaction logs that follow will error out.
You’ll need the procedure ‘sp_killallprocessindb‘ which you can find here: http://www.databasejournal.com/scripts/article.php/3634276/Kill-All-Processes-in-a-Particular-DataBase.htm
Be sure to create this under your master database on the destination server, but it’s a really good proc to use whatever server you’re working on.
All you have to do is create 2 folders to hold the backup files. (both full backups and transaction log backups). In this example I am using the following:
e:\MyFullBackupsFolder
e:\MyLogBackupsFolder

This can be wherever you feel is best as long as you modify the backup logic AND the restore logic to be the appropriate path before running it.

好，那么它是如何工作的？ 我需要做什么才能运行？
首先，定期禁用当前正在运行的任何事务日志备份。如果在执行此过程时运行事务日志备份，则它将通过关闭LSN并且后续的后续事务日志将错误输出。
点此你可以找到你需要的程序‘sp_killallprocessindb‘：: http://www.databasejournal.com/scripts/article.php/3634276/Kill-All-Processes-in-a-Particular-DataBase.htm

定要在目标服务器上的主数据库下创建它，在你正在使用的任何服务器上尝试是一个非常好的步骤。
所要做的就是创建2个文件夹来保存备份文件（完整备份和事务日志备份）。在这个例子中，我用了以下内容：
e:\MyFullBackupsFolder
e:\MyLogBackupsFolder
在任何你认为最佳的地方，你都可以在运行前将备份逻辑和还原逻辑修改到适当的路径上。

Next simply copy all the the SQL logic below, and paste into Management Studio. Once it runs it will automatically create all the backups you need, and all the restore scripts necessarry. Once this is done; you will need to copy over the backup folders you created formerly (with all the new backups and transaction log backups) to the new server where you want to restore the databases. Then take the produced restore scripts and run them on the new server. The databases will all be restored WITH NORECOVERY so you’ll be all set to setup your AVAILABILITY GROUPS for your AlwaysOn configurations and it should synch up no problem.
Note: As a fail-safe measure to make sure no databases are automatically restored before you had a real chance to view the restore logic; you’ll see the following line of code after each restore set:
select/**/ — replace this line with: exec
Basically; all you have to do when you’re ready to run the logic is do a find and replace.
Replace this: select/**/ — replace this line with: exec
With this: exec

This was placed here to give you the opportunity to see the restore process as it is written for each database.
On with the script…

接下来，只需复制下面的所有SQL逻辑（logic），然后粘贴到Management Studio中。一旦运行，它将自动创建所有你需要的备份，和所有必须的还原脚本。一旦完成，你需要将以前创建的备份文件夹（包含所有新备份和事务日志备份）复制到要还原数据库的新服务器。然后获取生成的还原脚本并在新服务器上运行。所有数据库都将用NORECOVERY进行恢复，因此你只需要将AlwaysOn配置设置为AVAILABILITY GROUPS，它应该会进行同步操作。
注意：作为一种故障安全措施，它会确保在你真正有机会查看还原逻辑（logic）之前，不会自动恢复任何数据库。你会在每个还原集后看到以下代码：
select/**/ — replace this line with: exec

基本上，准备运行逻辑（logic）时，你只需要做一个查找和替换。
替换这个: select/**/ — replace this line with: exec
用这个：exec
写这个是为了让你有机会看到为每个数据库的还原过程。
以下是脚本：

```SQL
use master;
set nocount on
 
---------------------------
--BACKUP ALL DATABASES LOCOALLY.  SINGLE FULL BACKUP AND SINGLE TRANSACTION LOG BACKUP PER EACH DATABASE
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

```


[![WorksEveryTime](https://forthebadge.com/images/badges/60-percent-of-the-time-works-every-time.svg)](https://shitday.de/)

## Build-Info

| Build Quality | Build History |
|--|--|
|<table><tr><td>[![Build-Status](https://ci.appveyor.com/api/projects/status/pjxh5g91jpbh7t84?svg?style=flat-square)](#)</td></tr><tr><td>[![Coverage](https://coveralls.io/repos/github/tygerbytes/ResourceFitness/badge.svg?style=flat-square)](#)</td></tr><tr><td>[![Nuget](https://img.shields.io/nuget/v/TW.Resfit.Core.svg?style=flat-square)](#)</td></tr></table>|<table><tr><td>[![Build history](https://buildstats.info/appveyor/chart/tygerbytes/resourcefitness)](#)</td></tr></table>|

## Author

- **李聪明的数据库 Lee's Clever Data**
- **Mike的数据库宝典 Mikes Database Collection**
- **李聪明的数据库** "Lee Songming"

[![Gist](https://img.shields.io/badge/Gist-李聪明的数据库-<COLOR>.svg)](https://gist.github.com/congmingshuju)
[![Twitter](https://img.shields.io/badge/Twitter-mike的数据库宝典-<COLOR>.svg)](https://twitter.com/mikesdatawork?lang=en)
[![Wordpress](https://img.shields.io/badge/Wordpress-mike的数据库宝典-<COLOR>.svg)](https://mikesdatawork.wordpress.com/)

---
## License
[![LicenseCCSA](https://img.shields.io/badge/License-CreativeCommonsSA-<COLOR>.svg)](https://creativecommons.org/share-your-work/licensing-types-examples/)

![Lee Songming](https://raw.githubusercontent.com/LiCongMingDeShujuku/git-resources/master/1-clever-data-github.png "李聪明的数据库")

