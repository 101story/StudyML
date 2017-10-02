
dbca 설치 후 정보

[orcl:/]$ more etc/hosts
# Do not remove the following line, or various programs
# that require network functionality will fail.
127.0.0.1 edydr1p0.us.oracle.com edydr1p0 localhost.localdomain localhost
10.0.2.128 edydr1p0.us.oracle.com edydr1p0 localhost.localdomain localhost

[root@edydr1p0 ~]# echo $PS1
[\u@\h \W]\$
[orcl:~]$ echo $PS1
[`echo $ORACLE_SID`:\W]$


###########################
 Oracle Server 수동 설치
###########################
SQL> startup force

SQL> select name from v$datafile;
-- 임의로 만들어준 Data disk 에 저장되어 있음
  NAME
  --------------------------------------------------------------------------------
  +DATA/orcl/datafile/system.256.944158477
  +DATA/orcl/datafile/sysaux.257.944158477
  +DATA/orcl/datafile/undotbs1.258.944158479
  +DATA/orcl/datafile/users.259.944158479
  +DATA/orcl/datafile/example.265.944158725

SQL> select member from v$logfile;

  MEMBER
  --------------------------------------------------------------------------------
  +DATA/orcl/onlinelog/group_3.263.944158671
  +FRA/orcl/onlinelog/group_3.259.944158679
  +DATA/orcl/onlinelog/group_2.262.944158665
  +FRA/orcl/onlinelog/group_2.258.944158669
  +DATA/orcl/onlinelog/group_1.261.944158657
  +FRA/orcl/onlinelog/group_1.257.944158661

  6 rows selected.


SQL> select name from v$controlfile;

  NAME
  --------------------------------------------------------------------------------
  +DATA/orcl/controlfile/current.260.944158651
  +FRA/orcl/controlfile/current.256.944158651

SQL> startup force
  ORACLE instance started.

  Total System Global Area 1489829888 bytes
  Fixed Size                  1336624 bytes
  Variable Size             889195216 bytes
  Database Buffers          587202560 bytes
  Redo Buffers               12095488 bytes
  Database mounted.
  Database opened.
SQL> select name from v$tempfile;

  NAME
  --------------------------------------------------------------------------------
  +DATA/orcl/tempfile/temp.264.944158713

SQL> select name from v$controlfile;

  NAME
  --------------------------------------------------------------------------------
  +DATA/orcl/controlfile/current.260.944158651
  +FRA/orcl/controlfile/current.256.944158651

SQL> show user
  USER is "SYS"
SQL> desc obj$
   Name                                      Null?    Type
   ----------------------------------------- -------- ----------------------------
   OBJ#                                      NOT NULL NUMBER
   DATAOBJ#                                           NUMBER
   OWNER#                                    NOT NULL NUMBER
   NAME                                      NOT NULL VARCHAR2(30)
   NAMESPACE                                 NOT NULL NUMBER
   SUBNAME                                            VARCHAR2(30)
                                         DATE

SQL> desc tab$
   Name                                      Null?    Type
   ----------------------------------------- -------- ----------------------------
   OBJ#                                      NOT NULL NUMBER
   DATAOBJ#                                           NUMBER
   TS#                                       NOT NULL NUMBER
   FILE#                                     NOT NULL NUMBER
   BLOCK#                                    NOT NULL NUMBER
   BOBJ#                                              NUMBER
   TAB#                                               NUMBER
   COLS                                      NOT NULL NUMBER


========================================
orcl 서버 생성 뒤 곧바로 해 본 작업
========================================

# 서버 구성요소 확인

 [orcl:~]$ . oraenv
 ORACLE_SID = [orcl] ? orcl

 [orcl:~]$ sqlplus / as sysdba

 SQL> startup force

 SQL> select name   from v$datafile;
 SQL> select name   from v$tempfile;
 SQL> select member from v$logfile;
 SQL> select name   from v$controlfile;

 SQL> select * from v$sga;

 SQL> col DESCRIPTION noprint
 SQL> col error clear
 SQL> select * from v$bgprocess order by PADDR;
 SQL> select * from v$bgprocess where paddr <> '00' order by PADDR;

 SQL> show user

 SQL> desc obj$
 SQL> desc tab$

# Startup 및 Shutdown

 SQL> shutdown abort

 SQL> startup nomount
      --> parameter file 읽기
      --> SGA 할당
      --> BGP 시작
      --> Diagnostic file 열기

 SQL> alter database mount
      --> control file 읽기

 SQL> alter database open
      --> datafile 읽기
      --> redo log file 읽기

# 사용자 관리

 SQL> select username,
             account_status
      from dba_users;

 SQL> alter user scott
      account lock;

 SQL> alter user scott
      identified by tiger
      account unlock;

 SQL> alter user hr
      identified by hr
      account unlock;

 SQL> select *
      from v$tablespace;

 SQL> drop user james cascade;

 SQL> create user james
      identified by bond
      default tablespace users
      quota 10m on users
      quota 20m on example;

 SQL> grant create session, create table
      to james;

 SQL> conn james/bond

 SQL> create table t1
      (no number);

# 테이블스페이스 생성

 SQL> conn / as sysdba

 SQL> show parameter instance_name

 SQL> !mkdir -p $ORACLE_BASE/oradata/orcl

 SQL> drop tablespace ybts including contents and datafiles;

 SQL> create tablespace ybts
      datafile '$ORACLE_BASE/oradata/orcl/ybts01.dbf' size 10m,
               '$ORACLE_BASE/oradata/orcl/ybts02.dbf' size 10m
               autoextend on next 10m maxsize 1G;

 SQL> set lines 200
 SQL> col file_name format a60

 SQL> select tablespace_name, file_name
      from dba_data_files
      order by 1;

 SQL> alter user james
      quota unlimited on ybts;

 SQL> col username format a30

 SQL> select *
      from dba_ts_quotas
      order by 2;



# 리스너 관리

  [orcl:~]$ . oraenv
  ORACLE_SID = [orcl] ? +ASM

  [+ASM:~]$ lsnrctl stop

  [+ASM:~]$ echo $ORACLE_HOME

  [+ASM:~]$ ls $ORACLE_HOME/network/admin

  [+ASM:~]$ more $ORACLE_HOME/network/admin/listener.ora

  * 리스너 없애기 (툴을 이용)
  [+ASM:~]$ netca   --> 기존 리스너 삭제하세요!

  [+ASM:~]$ netca   --> 새로운 리스너 2개(1521, 1621) 생성하세요!

  [+ASM:~]$ lsnrctl stop listener
  [+ASM:~]$ lsnrctl stop listener1

  [+ASM:~]$ lsnrctl start listener
  [+ASM:~]$ lsnrctl start listener1

  [+ASM:~]$ ps -ef | grep lsnr



Net CA(별개의 툴) : 리스너만들어줌
ASM CA

[orcl:~]$ vi + $ORACLE_HOME/sqlplus/admin/glogin.sql
  define _editor=vi -- 추가
  -> 설명
  sqlplus 에서 ed 명령으로 editor 를 vi 로 설정해둠
  + 기호를 붙이면 파일의 제일 마지막이 보임
  glogin : DBMS/GI sqlplus 실행시 가장 먼저 읽는 파일
  glogin 파일 어느 위치에서든 해당 인스턴스로 접속하는 User는 가장 처음 읽게됨


========================================
 Database 생성
========================================

# DBCA 활용

  - 이미 수행했음

# Create Database 명령 활용
  -- 기본 loc disk 에 저장됨
  0.디렉토리 및 파라미터 파일 생성

   OS] vi /etc/oratab

  +ASM:/u01/app/oracle/product/11.2.0/grid:N
  orcl:/u01/app/oracle/product/11.2.0/dbhome_1:N
  prod:/u01/app/oracle/product/11.2.0/dbhome_1:N

   OS] rm -rf $ORACLE_BASE/oradata/prod
   OS] mkdir -p $ORACLE_BASE/oradata/prod
   OS] ls $ORACLE_BASE/oradata

        orcl  prod

   OS] . oraenv

   ORACLE_SID = [oracle] ? prod

   OS] vi $ORACLE_HOME/dbs/initprod.ora

	db_name       = prod
	instance_name = prod
	compatible    = 11.2.0
	processes     = 100

	undo_management = auto
	undo_tablespace = undotbs01

	db_cache_size    = 64m
	shared_pool_size = 72m
	db_block_size    = 4096

	control_files = ('$ORACLE_BASE/oradata/prod/control01.ctl',
	                 '$ORACLE_BASE/oradata/prod/control02.ctl')

	remote_login_passwordfile = exclusive

1.Software 시작

   OS] export ORACLE_SID=prod
   OS] sqlplus / as sysdba
   SQL> startup nomount
   SQL> select instance_name, status from v$instance;

     INSTANCE_NAME                    STATUS
     -------------------------------- ------------------------
     prod                             STARTED

   SQL> !ps -ef|grep smon

      oracle   10484     1  0 18:17 ?        00:00:00 asm_smon_+ASM
      oracle    4556     1  0 15:53 ?        00:00:00   ora_smon_prod
      oracle    8148     1  0 14:52 ?        00:00:01 ora_smon_orcl

  2.Create database 명령 실행
  -- nomount 상태 Started 상태
  -- control 파일을 작성하고, 읽음(mount 됐다고 지칭함)
  -- Datafile, Redo log file 만들고 읽음 (Open 되었다.)
  -- Redo log file 2개의 그룹에 2개씩 백업용 만들어둠
  -- Datafile 4개 (?)
   SQL> create database prod
	logfile group 1 ('$ORACLE_BASE/oradata/prod/redo01_a.log',
        	         '$ORACLE_BASE/oradata/prod/redo01_b.log') size 20m,
	        group 2 ('$ORACLE_BASE/oradata/prod/redo02_a.log',
	                 '$ORACLE_BASE/oradata/prod/redo02_b.log') size 20m
	datafile '$ORACLE_BASE/oradata/prod/system01.dbf' size 200m autoextend on next 20m maxsize unlimited
	sysaux datafile '$ORACLE_BASE/oradata/prod/sysaux01.dbf' size 200m autoextend on next 20m maxsize unlimited
	undo tablespace undotbs01 datafile '$ORACLE_BASE/oradata/prod/undotbs01.dbf' size 100m autoextend on next 20m maxsize 2G
	default temporary tablespace temp tempfile '$ORACLE_BASE/oradata/prod/temp01.tmp' size 20m autoextend on next 20m maxsize 2G;

cf.vi $ORACLE_HOME/rdbms/admin/sql.bsq
-- 자동으로 돌아감 sys 의 메타 데이터 들이 생성

   SQL> !ls -l $ORACLE_BASE/oradata/prod
   SQL> select instance_name, status from v$instance;

     INSTANCE_NAME                    STATUS
     -------------------------------- ------------------------
     prod                             OPEN

  3.필수 Script 수행

   SQL> alter user sys identified by oracle;        -- 기본 암호 : change_on_install
   SQL> alter user system identified by oracle;     -- 기본 암호 : manager
   SQL> ed after_db_create.sql
   -- ?/오라클 홈
    -- 데이터 딕셔너리, supplied 패키지 등 생성해줌
    -- pupbld : product user profile 을 만들어줌
      -- sqlplus 를 이용하는 유저가 특정 commd 를 사용하지 못하도록함
      -- sqldeveloper 나 다른걸 사용하면되서 목적이 달라짐
      -- 지금은 무조건 만들게 함 다른 목적을 위해(?)

    	conn sys/oracle as sysdba
    	@?/rdbms/admin/catalog.sql
    	@?/rdbms/admin/catproc.sql

    	conn system/oracle
    	@?/sqlplus/admin/pupbld.sql

   SQL> @ after_db_create.sql
   SQL> exit

  # Test

   OS] ps -ef|grep smon

	oracle   24145     1  0 18:06 ?        00:00:00 ora_smon_prod
	oracle   22122     1  0 17:52 ?        00:00:00 ora_smon_orcl
	oracle   22122     1  0 17:52 ?        00:00:00 ora_smon_+ASM

   OS] export ORACLE_SID=orcl
   OS] sqlplus / as sysdba
   -- 리셋 test 로 다시 켜보기
   SQL> startup force
   SQL> select instance_name from v$instance;
   SQL> exit

   OS] export ORACLE_SID=prod
   OS] sqlplus / as sysdba
   SQL> startup force
   SQL> select instance_name from v$instance;
   SQL> exit

# Server
  cpu, ram >>> hard disk
# Storage Server
  cpu, ram <<< hard disk
  hard disk 가 엄청큰


========================================
 Database 생성 뒤 해야할 일
========================================

# 서버 준비

  [orcl:~]$ export ORACLE_SID=orcl
  [orcl:~]$ sqlplus / as sysdba
  SQL> startup force
  SQL> alter user sys    identified by oracle;
  SQL> alter user system identified by oracle;

  파라미터 동적 할당
  SQL> alter system set service_names = 'orcl';

  SQL> exit

  [orcl:~]$ export ORACLE_SID=prod
  [prod:~]$ sqlplus / as sysdba
  SQL> startup force
  SQL> exit

# 패스워드 파일
  -- orapwprod 의 패스워드를 정해줌 최대 5명까지 dba 로 가능함
  [prod:~]$ orapwd file=$ORACLE_HOME/dbs/orapwprod password=nemam entries=5

# 리스너에 static 서비스 등록
-- $ORACLE_HOME/network/admin/listner.oracle 에 내용을 추가
-- GI 의 +ASM 인스턴스의 리스터를 사용
  [prod:~]$ . oraenv
  ORACLE_SID = [prod] ? +ASM

  [+ASM:~]$ lsnrctl service listener    << dynamic 서비스 등록 결과 확인됨
  [+ASM:~]$ lsnrctl service listener1   << 어떤 서비스도 등록되어 있지 않음

  [+ASM:~]$ more $ORACLE_HOME/network/admin/listener.ora
  -- 리스너 정보가 등록되어 있음 수동으로 추가
  SID_LIST_LISTENER2 =
  (.... orcl ...)
  (.... prod ...)

  [+ASM:~]$ netmgr   -> 1521 리스너에 orcl, prod 등록
                     -> 1621 리스너에 orcl, prod 등록
    -- db를 dbhome_1 로 변경
    -- G 이름과 SID 도 orcl 로 변경

  [+ASM:~]$ lsnrctl stop
  [+ASM:~]$ lsnrctl start

  [+ASM:~]$ lsnrctl stop  listener1
  [+ASM:~]$ lsnrctl start listener1


  >> Windows에서 접속 테스트

  [1] Easy connnect

  C:\Users\student> set path=C:\instantclient_12_1;%path%

  C:\Users\student> sqlplus system/oracle@192.168.56.101:1521/orcl
  C:\Users\student> sqlplus system/oracle@192.168.56.101:1521/prod

  C:\Users\student> sqlplus system/oracle@192.168.56.101:1621/orcl
  C:\Users\student> sqlplus system/oracle@192.168.56.101:1621/prod

  [2] Local naming
  -- 자동으로 다른 리스너 선택하기
  tnsnames.ora
  easy connect -> 클라이언트가 알아서 리스너를 주소를 바꿔서 접속
  local name -> tnsnames.ora 이용 (xe 는 쉬움 local file 만 변경해주면됨)
  set tns_admin=C:\instantclient_12_1
  notepad

  netmgr
  (mgr 로 자동생성) service name 생성
  tnsnames.ora 에 생성되어 있음
  두개의 주소중에 랜덤하게 접속함
  접속한 리스너가 접속이 되지 않을때 자동으로 다른 리스너로 감
  connect-time load balance : 접속을 분산시켜줌
  connect-time failover : 하나가 죽으면 다른 곳에 접속할수 있게 함

  C:\Users\student> notepad C:\instantclient_12_1\tnsnames.ora

    _orcl =
      (DESCRIPTION =
        (ADDRESS_LIST =
          (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.56.101)(PORT = 1521))
          (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.56.101)(PORT = 1621))
        )
        (CONNECT_DATA =
          (SERVICE_NAME = orcl)
        )
      )

    _prod =
      (DESCRIPTION =
        (ADDRESS_LIST =
          (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.56.101)(PORT = 1521))
          (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.56.101)(PORT = 1621))
        )
        (CONNECT_DATA =
          (SERVICE_NAME = prod)
        )
      )

  C:\Users\student> notepad _orcl_system.bat

    set path=C:\instantclient_12_1;%path%
    set tns_admin=C:\instantclient_12_1

    sqlplus system/oracle@_orcl

  C:\Users\student> _orcl_system
  SQL> select instance_name from v$instance;
  SQL> exit

  C:\Users\student> notepad _prod_system.bat

    set path=C:\instantclient_12_1;%path%
    set tns_admin=C:\instantclient_12_1

    sqlplus system/oracle@_prod

  C:\Users\student> _prod_system
  SQL> select instance_name from v$instance;
  SQL> exit


자바 개발자가 JDBC 사용 시
JDBC THIN/OCI 두가지 방법으로 접속 가능
  THIN : easy connect 방식
  OCI : Local naming 방식


SYS 오라클 수퍼사용자로 데이터베이스에서 발생하는 모든 문제를 처리할 수 있는 권한을 가짐
SYSTEM 오라클 데이터베이스를 유지보수 관리할 때 사용하는 ID이며, SYS 사용자와 차이점은 데이터베이스를 생성할 수 있는 권한이 없다.
SCOTT 처음 오라클 데이터베이스를 사용하는 사람을 위하여 만들어 놓은 sample 사용자 ID이다. HR sample 사용자 ID이다.
__
