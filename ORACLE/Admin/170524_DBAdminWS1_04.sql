
================================================
 4장 Managing the Database Instance
================================================

# 4-3

  [orcl:~]$ . oraenv
  ORACLE_SID = [orcl] ? orcl

  [orcl:~]$ sqlplus / as sysdba
  SQL> startup force
  SQL> exit

  [orcl:~]$ emctl status dbconsole
    Oracle Enterprise Manager 11g Database Control Release 11.2.0.1.0
    Copyright (c) 1996, 2009 Oracle Corporation.  All rights reserved.
    https://edydr1p0.us.oracle.com:1158/em/console/aboutApplication
    Oracle Enterprise Manager 11g is running.
    ------------------------------------------------------------------
    Logs are generated in directory /u01/app/oracle/product/11.2.0/dbhome_1/edydr1p0.us.oracle.com_orcl/sysman/log

  [orcl:~]$ emctl stop   dbconsole
  [orcl:~]$ emctl start  dbconsole

  https://192.168.56.101:1158/em

prod 에 em 추가 하기
DBCA 로 EM 설치해보기 setup


## DB Instance 관리
  - Management Framework
  - Parameter 및 Parameter file
  - startup 및 shutdown
  - Diagnostic tool
    file
    DPV(v$), DDV(DBA_)

* 죽은 리스너, DB 인스턴스 살리기
  os] . oraenv
  os] +ASM

  os] lsnrctl start listener
  os] lsnrctl start listener1

  os] sqlplus / as sysasm
  sql> startup
  sql> exit

  os] . oraenv
  os] orcl

  os] emctl start dbconsole
  os] sqlplus / as sysdba
  sql> startup
  sql> exit

  shutdown abort 강제로 죽임
  asm 인스턴스를 죽이면 의지하던 db 인스턴스도 죽음
  orcl 이 asm 의 메모리에 값을 남기기 때문에 prod 는 남기지 않아서 안죽음

rapidmining
tableau

## 초기화 파라메터파일 (데이터베이스 모양을 정의)
  > initSID.ora (pfile) : txt 파일
    create pfile from spfile 가능
    startup 을 함
    안에 파라미터를 통해 인스턴스 모양을 만듬
    스스로 혹은 DBA 에 의해 계속 바뀔수 있음
      alter system set db_cache_size=5G
      변경사항이 initSID 에 다시 반영되지 않음
  > spfileSID.ora (spfile): 바이너리파일
    create spfile from pfile
      기본위치의 기본 pfile ORACLE_HOME/dbs -> 변경 가능함
    계속 인스턴스와 연계가 되어 있어 변경사항이 반영됨
    alter system set db_cache_size=5G scope=[both|memory|spfile]
      - both 인스턴스와 spfile 도 동시에 변경
      - memory 인스턴스에만
      - spfile 지금 인스턴스엔 반영안하고 spfile 에만
  > 생성 순서
    pfile 먼저 생성 되어야함
  > 시작 순서
    spfile 을 먼저 찾고 pfile 을 찾음
  > show parameter spfile
    현재 읽고 있는 spfile
    pfile 은 알 수 없음
  > 여러개의 파라미터파일
    work load 드에 따라 인스턴스의 모양이 변경 될 수 있다.
    확장자 상관없이 만들어 사용
    startup pfile=a.txt
      지정해서 해당 파라미터를 읽음
    spfile 은 지정해서 읽을 수 없음
      pfile 에서 spfile 을 지정해서 읽어야함


* 실습
# port number 확인

  [oracle@ora11gr2 ~]$ more $ORACLE_HOME/install/portlist.ini
  Enterprise Manager Console HTTP Port (orcl) = 1158
  Enterprise Manager Agent Port (orcl) = 3938
  Enterprise Manager Console HTTP Port (prod) = 5500
  Enterprise Manager Agent Port (prod) = 1830

# 파라미터 파일 이해

 [1] pfile 추가 및 원하는 pfile을 이용해서 startup

  [oracle@ora11gr2 ~]$ ls -l $ORACLE_HOME/dbs/*prod.ora

    -rw-r--r--  1 oracle oinstall 384  9월  8 16:14 /u01/app/oracle/product/11.2.0/dbhome_1/dbs/initprod.ora
*/
  [oracle@ora11gr2 ~]$ cp /u01/app/oracle/product/11.2.0/dbhome_1/dbs/initprod.ora /home/oracle/mydb.txt
  [oracle@ora11gr2 ~]$ vi /home/oracle/mydb.txt

	# 아래 파라미터 한 개만 수정하세요.

        processes     = 200

  [oracle@ora11gr2 ~]$ export ORACLE_SID=prod
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> shutdown abort
  SQL> startup pfile=/home/oracle/mydb.txt

  SQL> show parameter processes

	NAME                                 TYPE                   VALUE
	------------------------------------ ---------------------- ------------------------------
	processes                            integer



   [2] spfile 추가 및 원하는 spfile을 이용해서 startup

    SQL> create spfile from pfile;                                                      ==> $ORACLE_HOME/dbs/initprod.ora --> $ORACLE_HOME/dbs/spfileprod.ora
    SQL> create spfile='/home/oracle/spmydb.txt' from pfile='/home/oracle/mydb.txt';    ==> '/home/oracle/mydb.txt'       --> '/home/oracle/spmydb.txt'

    SQL> !ls -l $ORACLE_HOME/dbs/*prod.ora

  	-rw-r--r--  1 oracle oinstall  384  9월  8 16:14 /u01/app/oracle/product/11.2.0/dbhome_1/dbs/initprod.ora
  	-rw-r-----  1 oracle oinstall 1536  9월  9 17:46 /u01/app/oracle/product/11.2.0/dbhome_1/dbs/spfileprod.ora
  */
    SQL> !ls -l /home/oracle/*mydb.txt

  	-rw-r--r--  1 oracle oinstall  384  9월  9 17:40 /home/oracle/mydb.txt
  	-rw-r-----  1 oracle oinstall 1536  9월  9 17:46 /home/oracle/spmydb.txt
  */
    SQL> startup force                                         => /u01/app/oracle/product/11.2.0/dbhome_1/dbs/spfileprod.ora
    -- 기본 위치의 spfile 을 읽음
    SQL> show parameter spfile

    	NAME                                 TYPE                   VALUE
    	------------------------------------ ---------------------- -----------------------------------------------------------
    	spfile                               string                 /u01/app/oracle/product/11.2.0/dbhome_1/dbs/spfileprod.ora


    SQL> startup force pfile=$ORACLE_HOME/dbs/initprod.ora     => /u01/app/oracle/product/11.2.0/dbhome_1/dbs/initprod.ora
    -- 지정한 위치 pfile 읽음
    SQL> show parameter spfile

    	NAME                                 TYPE                   VALUE
    	------------------------------------ ---------------------- ------------------------------
    	spfile                               string

    SQL> startup force pfile=/home/oracle/mydb.txt             => /home/oracle/mydb.txt
    -- 지정한 위치 pfile 읽음
    SQL> show parameter spfile

    	NAME                                 TYPE                   VALUE
    	------------------------------------ ---------------------- ------------------------------
    	spfile                               string

    SQL> startup force pfile=/home/oracle/spmydb.txt           => /home/oracle/spmydb.txt를 사용하지 못하고 에러 발생
    SQL> startup force spfile=/home/oracle/spmydb.txt          => 에러
    SQL> !vi /home/oracle/a.txt

  	 spfile=/home/oracle/spmydb.txt

    SQL> startup force pfile=/home/oracle/a.txt
    SQL> show parameter spfile

    	NAME                                 TYPE                   VALUE
    	------------------------------------ ---------------------- ------------------------------
    	spfile                               string                 /home/oracle/spmydb.txt

 ->> 이렇게 하면 startup force 만 쳐도 sprile 을 spmydb 에서 읽어 오나
  NO! 기본 위치의 spfile 로 읽어옴 spfile 파라미터로 지정

  initorcl 이 임의로 지정한 spfile 을 로드
  인스턴스 로그 되면서 읽는 파일은 기본위치의 spfile


진단파일
v$
데이터페이스 조정 - 명령어
인스턴스 조정 - 파라미터

## Hidden Parameter
특성
  _ 시작
원하는 파라미터만 보기
  SQL> ed show_param

    SET LINES 120

    COLUMN PARAMETER FORMAT A40
    COLUMN DESCRIPTION FORMAT A50 WORD_WRAPPED
    COLUMN "Session Value" FORMAT A10
    COLUMN "Instance Value" FORMAT A10

    SELECT A.KSPPINM "Parameter"
          ,A.KSPPDESC "Description"
          ,B.KSPPSTVL "Session Value"
          ,C.KSPPSTVL "Instance Value"
    FROM   X$KSPPI A
          ,X$KSPPCV B
          ,X$KSPPSV C
    WHERE  A.INDX = B.INDX
    AND    A.INDX = C.INDX
    AND    translate(A.KSPPINM, '_', '#') LIKE '%&1%';

  SQL> @show_param optimizer
  SQL> @show_param pga

_spin_count

Lock  : 긴 시간 자원공유
Latch : 짧은 시간 자원공유

* 생애주기
  데모버전 기능 테스트
  곧 없어질 기능
  히든 -> 일반 -> 히든



## static parameter vs dynamic parameter
  * static : 반듯이 scope=spfile 해야 하는 파라미터
    control file 등 ..
    shutdown startup 해서 반영하는 것들
  * dynamic : 언제든지 변경 할 수 있는 파라미터


 - Static parameter

    SQL> show parameter log_buffer

    	NAME                                 TYPE                   VALUE
    	------------------------------------ ---------------------- ------------------------------
    	log_buffer                           integer                2927616

    SQL> alter system set log_buffer=5855232 scope=both;        --> ORA-02095: specified initialization parameter cannot be modified
    SQL> alter system set log_buffer=5855232 scope=memory;      --> ORA-02095: specified initialization parameter cannot be modified
    SQL> alter system set log_buffer=5855232 scope=spfile;      --> startup을 다시 해야 적용됩니다.
    SQL> startup force

    SQL> show parameter log_buffer

    	NAME                                 TYPE                   VALUE
    	------------------------------------ ---------------------- ------------------------------
    	log_buffer                           integer                7057408

 - Dynamic parameter

    SQL> show parameter db_cache_size

    	NAME                                 TYPE                   VALUE
    	------------------------------------ ---------------------- ------------------------------
    	db_cache_size                        big integer            64M

    SQL> alter system set db_cache_size=60 scope=both;          --> 인스턴스와 spfile 모두 변경됩니다.
    SQL> alter system set db_cache_size=64 scope=memory;        --> 인스턴스만 변경되고 spfile은 변경되지 않습니다.
    SQL> alter system set db_cache_size=60 scope=spfile;        --> startup을 다시 해야 적용됩니다.


  * 파라미터를 담는 파일 spfile (또는 pfile)

* 기본 파라매터 종류들
  OS] vi $ORACLE_HOME/dbs/initbrdb.ora

	db_name       = brdb
	instance_name = brdb
  -- 현재 사용중인 소프트웨어의 버전 (버전에 따라 지원하지 않은 api 가 있을 수 있음)
	compatible    = 11.2.0
  -- 뒤에서 돌아가는 것들이 있으니까 동접 100명을 원하면 110 정도로 줘야 한다(?)
	processes     = 100

  -- tablespace 만 정해지면 undo segment 는 자동으로 해줌
	undo_management = auto
	undo_tablespace = undotbs01

	db_cache_size    = 64m
	shared_pool_size = 72m
	db_block_size    = 4096

	control_files = ('$ORACLE_BASE/oradata/brdb/control01.ctl',
	                 '$ORACLE_BASE/oradata/brdb/control02.ctl')

  -- 패스워드 파일 인증 가능하게 함
	remote_login_passwordfile = exclusive





## Restrict Mode
  제안모드 -> 허용

  [oracle@ora11gr2 ~]$ export ORACLE_SID=prod
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> startup restrict force
  SQL> select INSTANCE_NAME, LOGINS from v$instance;

  	INSTANCE_NAME                    LOGINS
  	-------------------------------- --------------------
  	prod                             RESTRICTED

  SQL> alter system disable restricted session;

  SQL> select INSTANCE_NAME, LOGINS from v$instance;

  	INSTANCE_NAME                    LOGINS
  	-------------------------------- --------------------
  	prod                             ALLOWED

  SQL> alter system enable restricted session;
  SQL> startup force
  SQL> exit


## alert 파일의 내용을 계속 모니터링하려면?
* 에러가 났거나 중요한 일이 벌어지면 지정한 위치
  background_dump_dest 에 log 가 남는다

  4-38 Viewing the Alert Log
  ---참고, 에러의 종류에 따러서 여러 log 파일이 생성되는 것 뿐이다!!---
  alert_SID.log       Background dump dest
  SID....pid.trc      Background dump dest    -> 에러문제, 없으면 좋은거다!!
  sid.ora_pid.trc     Background dump dest    -> SP가 문제를 만났을때 에러문제,
  sid.ora.PID.trc    user_dump_dest          -> Tuning 목적으로 유저가 생성
  -----------------------------------------------------------

  [oracle@ora11gr2 ~]$ export ORACLE_SID=prod
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> startup force
  SQL> show parameter background_dump_dest

  	NAME                                 TYPE                   VALUE
  	------------------------------------ ---------------------- ------------------------------------------------
  	background_dump_dest                 string                 /u01/app/oracle/diag/rdbms/prod/prod/trace

  SQL> !

  [oracle@ora11gr2 ~]$ cd /u01/app/oracle/diag/rdbms/prod/prod/trace
  [oracle@ora11gr2 log]$ ls *.log
  -- 맨 아래쪽을 보곘다 +
  [oracle@ora11gr2 log]$ vi + alert_prod.log

  [oracle@ora11gr2 log]$ tail -f alert_prod.log
  -- tail 파일을 맨 아래쪽을 보겠다. -f 를 쓰면 새로운 값이 들어오면 보는 화면에 바로 반영해줌


* Database Server Intener
  오라클 최종교육
    trace : 계속 뭔가 쌓임
    dump : 한번 만들어지고 끝



## DDV 및 DPV
DBA_ 파일은 control 파일에서 올라오기 때문에 OPEN 이 되어야만 확인 가능한다.
v$ 파일은 파일에 따라 nomount, mount 상태에 확인 가능하다.

  [oracle@ora11gr2 ~]$ export ORACLE_SID=prod
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> shutdown abort

  SQL> startup nomount
  SQL> select * from dba_users;     -- ORA-01219: database not open: queries allowed on fixed tables/views only
  SQL> select * from v$datafile;    -- ORA-01507: database not mounted
  SQL> select * from v$sga;

  SQL> alter database mount;
  SQL> select * from dba_users;     -- ORA-01219: database not open: queries allowed on fixed tables/views only
  SQL> select * from v$datafile;

  SQL> alter database open;
  SQL> select * from dba_users;
  SQL> exit


## Startup Shutdown
각 순서에 따라 동작하는 일 (할수있는일)

0. 'Shutdown -----------------------------'
  > startup (open), pfile, restric, force

1. 'Nomount  -----------------------------'
  DB 와 인스턴스가 연관이 되는 순간
  모든 control file 을 여기 저기 찾아 여는 행위
  export ORACLE_SID = ?
  SID 에 맞는 parameter file 읽음
  SGA 할당, BGP 실행, alet, diagnastic(진단파일) 열림

  할수있는일) DB 생성, control file 생성

2. 'Mount -----------------------------'
  DB 모드 수정, 이름 변경 등...
  parameter file 의 control file 읽음

  할수있는일) DB 수정 (archive..)

  Datafile, Online Redo log file 을 읽어 Open 시킴
3. 'Open -----------------------------'
  control file 의 redo log file, datafile 읽음
  roll forward
    redo file 로 인스턴스가 죽기전 모습으로 돌림

'--------------------------------------'
rollback

rollback, open, roll forward 3 가지는 instance recovery 라고 함


GI 깔았을 경우 시작하는 방법
> srvctl start database -d orcl -o mount
로 하면 관련된 리스너, 인스턴스, 디스크 그룹등이 같이 시작된다.

* 'Shutdown'
  - nomal 모드는 세션이 끊길때까지 기다림
  - transactional 진행중이 트렌젝션은 기다림
  - immediate  기존의 프로세스에게 전부 중지 명령을 내림 세션을 끊음 마무리 rollback 까지 끝
  - abort 메모리 해제 하지 않고 그냥 바로 중지 startup 때 인스턴스 복구가 필요

* 인스턴스 복구과정
  Redo log fiel ------->/
  datafile ---->/
  redo 로 두개의 차이를 복구시킴
  user 중에 commit 한 사람도 있고 안한 사람도 있고
    redo log 에는 commit 한것과 안한것 전부 있음
    datafile commit 해도 안내려간 것도 있고 내려간것도 있고
      commit 안해도 내려간것도 있고 안내려간 것도 있고
      dirty data 들이 있음
    >> 이때 startup
      commit 하든 안하든 내려간 것들은 다시 읽어짐
      roll forward
        commit 을 안한것들은 안한대로
        commit 을 한것들은 한대로
        복구됨
        rollback 이 필요한것들은 필요한대로 놔둠
        datafile 에 반영되지 못한것들을 redo 를 재실행
      on demand rollback
        user 가 rollback 이 필요한 블럭을 사용하려고 할때 rollback 작업을 하고 할당함
      smon
        그때 그때 필요한것들 조금씩 치워나감


* SQL 처리 과정
  - http://docs.oracle.com/cd/E11882_01/server.112/e25789/sqllangu.htm#CHDDAGAA
  - Select 수행 순서
  - DML 수행 순서 + Commit + Instance Recovery (+ DBWn 및 LGWR의 사명)
  DBWR와 LGWR가 내려쓰는 경우              : http://cafe.naver.com/gsinternet/24
  Mechanics of Instance and Crash Recovery : http://cafe.naver.com/gsinternet/25

## 진단 도구
  * 파일
    alert_sid.log
      그때그때 중요한 일, 에러에 무조건 생기는 파일
      위치 background dump dest

    sid....pid.trc
      서버프로세스가 에러가 생기면
      위치 background dump dest

    sid.ora_pid.trc
      서버프로세스가 에러가 생기면
      위치 background dump dest

    sid.ora.pid.trc
      위치 user dump dest
      서버프로세스가 튜닝을 목적으로 생김

  - ADR : show parameter dest (진단파일이 생기는 위치)
    show parameter diagonistic?

  * 쿼리 서버에대한 상태를 보는 view
    - static data dictionary view (data dictionary)
    [dba_ [all_ [user_ ]]] 포함 관계
    dba_  : dba
    all_  : 소유한 남이나한테 권한 준 접근가능
    user_ : 소유한것
      catalog.sql
    datafile 에서 있음
    sql.bsq ... 등과 같은 파일이 obj$, tab$ 테이블을 만듬
    obj$, tab$ 메타데이터가 자동으로 관리되는 테이블
    open 시에만 이용 가능
    인스턴스와 무관하게 data 는 유지된다.
    ddl, dcl 등을 해야 내용이 변경됨


    - dynamic performance view
    parameter file, instance, control file 로 x$ 테이블이 채워지고
    v$
      x$ 테이블로부터 내용을 채우는 뷰
      끊임 없이 바뀜
      수행내역을 보여줌
      nomount, mount, open 에 가서 상태 확인 가능
      대부분이 startup 하면 내용이 채워짐
      shutdown 하면 사라짐 휘발성
      sysstat 동적 성능 뷰
      대부분이 instance 와 동일한 생명주기를 가짐
      데이터가 너무 자주 바뀌고 바뀌기 전 데이터를 가지고 있지 않아서 읽기 일관성이 보장되지 않는다.
    v$lock 막고 있는 것 찾아 주는 것
    v$session 현재 세션
    v$sql 수행한 sql 문 확인
    v$fixed_table 모든 뷰를 볼수 있음
    select * from dictionary 메타데이터 정보

  * server alert
      awr, mmon, addm ...
      v$ 의 부족한 부분을 극복할려고 만든 process

  * Performance (성능)
    수행, 능력
    기대
  * Tuning
    조정
    지표를 보는 방법
    indicater
    변화에 대응

  o Server Tuning?
	(진단 결과를 해석할 능력이 있으면서 !!!!)
	목표에 맞는 Performance가 발휘되도록
	시스템의 여러 요소를 조절해 가는 과정

  o SQL Tuning?
	(특정 SQL이 처리되는 가장 좋은 경로를 알고 있으면서 !!!!)
	optimizer가 최적의 실행계획을 선택하도록 유도하는 과정.


부록 A 의 단원 3장 4장 (영문 참고)
dbca 에서 orcl 삭제 하고 다시 만들기

____
