============================================
 14장 Backup & Recovery
============================================

<Backup & recovery>
  * backup
    logical : export, data pump
    physical : os 명령 - 신뢰도가 떨어지는 백업
              RMAN 백업 검증까지 툴로 도와줌
  * Restore : 손상된 파일대신 배업해둔 파일을 그 자리로 가져오는것
  * Recovery : Restore + Redo 적용
              Complete Recovery 끝까지 복구
              Incomplete Recovery 요까지 복구


<Failure 유형>

DBServer 에서 나올수 있는 Failure
  1. Statment Stmt
    dba 가 개입하기는 하되
    그냥 그렇게 넘어갈떄도 있고
    table space 에 "쿼타?" 주고 넘어감
  2. User Process 실패
    기본은 dba 가 할일이 없다.
    PMON 이 대기하고 있음
  3. User 의 실수
    잘못된 drop -> 과거 기억까지만 살려야됨
  4. Network Failure
  5. Instance Failure
  6. Media Failure




▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒                                              ▒
▒ BACKUP AND RECOVERY (User-managed)           ▒
▒                                              ▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒

------------------------
> Failure 유형 및 HAA  <
------------------------

  o Statement failure    : DBA
  o User process failure : PMON
  o Network failure      : Network 관리자
  o User error           : DBA
  o Instance failure     : SMON
  o Media failure        : DBA

- HAA : 다운타임의 원인과 해결책들

  o http://gseducation.blog.me/20104367973



----------------------
> Database 수동 생성 <
----------------------

0.디렉토리 및 파라미터 파일 생성

  OS] rm -rf $ORACLE_BASE/oradata/brdb
  OS] mkdir $ORACLE_BASE/oradata/brdb
  OS] ls $ORACLE_BASE/oradata

        brdb  orcl

  OS] vi $ORACLE_HOME/dbs/initbrdb.ora

  db_name       = brdb
  instance_name = brdb
  compatible    = 11.2.0
  -- 실행 계획 안정화 할때는 낮은 버전으로 진행 10.2.0 (하향호환)
  processes     = 100
  -- 동시에 붙는 프로세스 개수

  undo_management = auto
  undo_tablespace = undotbs01

  db_cache_size    = 64m
  shared_pool_size = 72m
  db_block_size    = 4096

  control_files = ('$ORACLE_BASE/oradata/brdb/control01.ctl',
                   '$ORACLE_BASE/oradata/brdb/control02.ctl')

  remote_login_passwordfile = exclusive
  -- 패스워드 파일 인증

  --> 최소한의 파라매터

1.Software 시작

   OS] vi $ORACLE_HOME/sqlplus/admin/glogin.sql

  define _editor=vi  --> 마지막줄에 추가해 주세요.

   OS] export ORACLE_SID=brdb
   OS] sqlplus / as sysdba
   SQL> startup nomount -- 파라미터파일만 가지고
   SQL> select instance_name, status from v$instance;

     INSTANCE_NAME                    STATUS
     -------------------------------- ------------------------
     brdb                             STARTED

2.Create database 명령 실행

   SQL> create database brdb
    logfile group 1 ('$ORACLE_BASE/oradata/brdb/redo01_a.log',
          	         '$ORACLE_BASE/oradata/brdb/redo01_b.log') size 20m,
            group 2 ('$ORACLE_BASE/oradata/brdb/redo02_a.log',
                     '$ORACLE_BASE/oradata/brdb/redo02_b.log') size 20m
    datafile '$ORACLE_BASE/oradata/brdb/system01.dbf' size 200m autoextend on next 20m maxsize unlimited
    sysaux datafile '$ORACLE_BASE/oradata/brdb/sysaux01.dbf' size 200m autoextend on next 20m maxsize unlimited
    undo tablespace undotbs01 datafile '$ORACLE_BASE/oradata/brdb/undotbs01.dbf' size 100m autoextend on next 20m maxsize 2G
    default temporary tablespace temp tempfile '$ORACLE_BASE/oradata/brdb/temp01.tmp' size 20m autoextend on next 20m maxsize 2G;

  cf.다음 파일의 내용을 확인해 보세요.

     vi $ORACLE_HOME/rdbms/admin/sql.bsq

   SQL> select instance_name, status from v$instance;

     INSTANCE_NAME                    STATUS
     -------------------------------- ------------------------
     brdb                             OPEN

3.필수 Script 수행

   SQL> alter user sys identified by oracle;        -- change_on_install
   SQL> alter user system identified by oracle;     -- manager
   SQL> ed after_db_create.sql

    conn sys/oracle as sysdba
    @?/rdbms/admin/catalog.sql
    @?/rdbms/admin/catproc.sql

    conn system/oracle
    @?/sqlplus/admin/pupbld.sql
    -- sqlplus 로 접속하려면 돌려야 하는 스크립트

   SQL> @ after_db_create.sql
   SQL> exit


   ls $ORACLE_HOME/dbs/*drdb*
*/   파라메터파일만 보이고 패스워드 파일이 안보임

  [oracle@ora11gr2 ~]$ orapwd file=/u01/app/oracle/product/11.2.0/dbhome_1/dbs/orapwbrdb password=saturday entries=5

# Test

 [oracle@ora11gr2 ~]$ ps -ef|grep smon

  oracle   24145     1  0 18:06 ?        00:00:00 ora_smon_brdb
  oracle   22122     1  0 17:52 ?        00:00:00 ora_smon_orcl

 [oracle@ora11gr2 ~]$ vi /etc/oratab

  orcl:/u01/app/oracle/product/11.2.0/dbhome_1:N
  brdb:/u01/app/oracle/product/11.2.0/dbhome_1:N



----------------------
> Database mode 수정 <
----------------------
아카이브 파일이 생기게 함
echo $PS1 -- 명령 프롬프트 확인 : ~ 홈 (틸드)

  [oracle@ora11gr2 ~]$ export NLS_LANG=american_america.us7ascii
  -- 영어 인코딩 설정
  [oracle@ora11gr2 ~]$ export ORACLE_SID=brdb
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> create spfile from pfile;
  SQL> startup force
  -- 해당 spfile 로 다시 로딩시켜 부팅하기 위해서 재부팅함
  SQL> show parameter spfile

  NAME                                 TYPE                   VALUE
  ------------------------------------ ---------------------- ------------------------------
  spfile                               string                 /u01/app/oracle/product/11.2.0
                                                              /dbhome_1/dbs/spfilebrdb.ora
  SQL> exit
  -- 사전 준비 완료

  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> archive log list

  Database log mode              No Archive Mode -- 현재 꺼져있음
  Automatic archival             Disabled
  Archive destination            /u01/app/oracle/product/11.2.0/dbhome_1/dbs/arch
  Oldest online log sequence     47
  Current log sequence           50

  - 스레드
    RAC DB 를 공유
    datafile 은 같이 쓰는데 인스턴스 끼리 사용하는 구간이 다름
    redo logfile 은 인스턴스 끼리 각각 자기 공간이 따로 있음
    redo logfile 은 그룹이 있고 그룹에 맴버들이 있는데
      그룹을 모은 것을 스레드라고함
    [ G1[ [], [] ] G2[ [], [] ] ...     ]
    각각의 맴버가 아카이브 로그 파일이 되는데 명칭을 규칙을 정해줄수 있음
    log_archive_format 명명 규칙 > log sequence 번호 _ 랜덤번호 .dbf
    불완전 복구가 되면 파일명이 다른게 생김

  SQL> show parameter log_archive_format  --> default 값 유지하세요.
  SQL> show parameter log_archive_dest    --> 2군데를 아래처럼 설정하세요.

  SQL> !mkdir /u01/app/oracle/oradata/brdb_arch1
  SQL> !mkdir /u01/app/oracle/oradata/brdb_arch2
  -- 지역적으로 한쪽이 무너져도 복구 가능하도록 2가지의 백업을 함

  SQL> alter system set log_archive_dest_1 = 'location=/u01/app/oracle/oradata/brdb_arch1/';
  SQL> alter system set log_archive_dest_2 = 'location=/u01/app/oracle/oradata/brdb_arch2/';
  -- pfile 에 반영이 안되고 starup 하면 다시 되돌아 가기때문에
  -- 현재 인스턴스에도 변화를 주고 파일에도 적용하기 위해 spfile 이용

  SQL> shutdown immediate
  SQL> startup mount
  -- 정상적인 종료 과정
  SQL> alter database archivelog;
  -- logwriter 의 행동 방식에 변화를 줌
  -- DB writer 는 더티버퍼를 내려씀 블럭단위로 찾아서 재자리에 써아됨
  -- DB writer 의 눈치를 봄 logwriter 가 기다림
  -- db writer 가 덮어 쓰면 그때 다시 logwr 가 덮어씀
  -- 아카이브 모드가 되면 logwr 가 dbwr 와 arc writer 의 눈치를 보고 둘다 끝나면 그때 다시 내려씀


  SQL> archive log list

  데이터베이스 로그 모드        아카이브 모드   --> Mode
  자동 아카이브                 사용            --> arcN 프로세스 자동 시작
  아카이브 대상                 /u01/app/oracle/oradata/brdb_arch2/
  가장 오래된 온라인 로그 순서  47
  아카이브할 다음 로그          50
  현재 로그 순서                50

  -- 현 시점의 아카이브파일 리두로그파일 데이터파일
  -- 반듯이 어느시점에서 백업을 했어야 함

  SQL> alter database open; -- db open
  SQL> !ps -ef|grep brdb

    oracle   31761     1  0 15:02 ?        00:00:00 ora_arc0_brdb
    oracle   31763     1  0 15:02 ?        00:00:00 ora_arc1_brdb
    oracle   31765     1  0 15:02 ?        00:00:00 ora_arc2_brdb

    -- 아카이브 프로세스

  SQL> !ls -lR /u01/app/oracle/oradata/brdb_arch*

  -- 로스스위치를 해야함 생성됨
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;

  SQL> !ls -lR /u01/app/oracle/oradata/brdb_arch*

## Backup
  * closed Backup
    - noarchivelog, archivelog 모드 가능
    백업 파일
      몽땅
  * open Backup
    - archivelog 만 가능
    백업 파일
      Database
        controlfile datafile
        redo log 파일은 백업 대상에서 제외
      기타중요파일
        몽땅

-------------------------
> Whole Database Backup <
-------------------------
* 백업을 해야 진짜 데이터베이스 백업을 진행한것
* consistent : 디비를 이루고 있는 리두로그, 데이터파일의 정보들이 일정하다.

- offline (closed, cold, consistent) 백업

  SQL> !mkdir /u01/app/oracle/oradata/dontouch
  SQL> shutdown immediate

  SQL> !cp -R /u01/app/oracle/oradata/brdb/* /u01/app/oracle/oradata/dontouch
  */
  SQL> !ls -lR /u01/app/oracle/oradata/dontouch
  SQL> exit

- online (open, hot, inconsistent) 백업

  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> startup
  SQL> !mkdir /u01/app/oracle/oradata/openbackup

  SQL> alter database backup controlfile to trace as '/u01/app/oracle/oradata/openbackup/control_20120218.sql';
  -- txt 파일이 만들어짐
  -- as 로 경로를 넣지 않으면 user dump dest 에 남음
  SQL> !vi /u01/app/oracle/oradata/openbackup/control_20120218.sql

  SQL> set pages 100
  SQL> set linesize 300

  SQL> select 'alter tablespace '||tablespace_name||' begin backup;'||chr(10)||
              '!cp '||file_name||' /u01/app/oracle/oradata/openbackup'||chr(10)||
              'alter tablespace '||tablespace_name||' end backup;' as commands
       from dba_data_files;

  SQL> 질의 결과를 복사해서 실행하세요.
      COMMANDS
    -----------------------------------------------------------------------------------------
    alter tablespace USERS begin backup;
    !cp C:\ORACLEXE\APP\ORACLE\ORADATA\XE\USERS.DBF /u01/app/oracle/oradata/openbackup
    alter tablespace USERS end backup;

    alter tablespace SYSAUX begin backup;
    !cp C:\ORACLEXE\APP\ORACLE\ORADATA\XE\SYSAUX.DBF /u01/app/oracle/oradata/openbackup
    alter tablespace SYSAUX end backup;

    alter tablespace UNDOTBS1 begin backup;
    !cp C:\ORACLEXE\APP\ORACLE\ORADATA\XE\UNDOTBS1.DBF /u01/app/oracle/oradata/openbackup
    alter tablespace UNDOTBS1 end backup;

    alter tablespace SYSTEM begin backup;
    !cp C:\ORACLEXE\APP\ORACLE\ORADATA\XE\SYSTEM.DBF /u01/app/oracle/oradata/openbackup
    alter tablespace SYSTEM end backup;
  --> parctial 백업이 모여서 full 이됨

  SQL> exit



* 백업 용어
  full
    전부 백업
  incremental
    지난번 변경된 부분부터 백업
  -------
  whole
    DB 전체 백업
  parctial
    조각 백업

시스템 체인지 넘버
  변화할때마다 올라감

오픈백업
  변경되고 있는 파일을
  얼리고 -> 복사 -> 백업


consistent 백업
  클로즈드백업
  한번 전체 백업해 놓으면 전부 백업된것이 다 같음 동기화 정보가 일치
  첫번째 파일을 백업
  두번째 파일을 백업
inconsistent 백업
  오픈백업
  각각 파일을 얼리고 백업하고 다시 얼리고 하면 동기화 정보가 일지 하지 않음
  첫번째 파일을 백업
    두번째 파일을 백업
-> 복구를 할때 클로즈드백업과 오픈백업 파일의 복구는 전혀 차이가 없다.



######
  에러케이스
######
-----------------
> Recovery Case <
-----------------

-` complete recovery `-

  [0] parameter file 손상 1 : 파일이 삭제된 상황                            -> 재생성(alert 파일을 활용할 경우 편리하다.)
    --> nomount 도 안됨 alert 파일에 있는 기록으로 생성함 다른 파일을 사용 할 수 있음
  [0] parameter file 손상 2 : spfile에 오타 입력된 상황                     -> pfile 생성 ▷ pfile 편집 ▷ spfile 재생성
    --> spfile 은 바이너리여서 편집이 가능한 pfile 로 만들어서 오타를 다시 수정해줌
  [0] password file 손상                                                   -> 재생성

  [1] control file 1개 손상                                                 -> 복사, 붙여넣기
    --> control file 은 3개가 다 정상적이어야함 mount 가 되지 않는다. 문제가 없을걸 문제 있는걸로 복붙
    --> 2번 파일이 깨지면 1번은 멀쩡한것
  [2] control file 몽땅 손상                                                -> create controlfile 명령 수행
    --> 최근의 control file 내용을 가진 파일로 create 함 nomount 상태에서 진행해야 함
    --> parameter 파일에 있는 control file 위치에 생김
  [3] redo log file 멤버 1개 손상                                           -> 복사, 붙여넣기
    --> 완전 복구
    --> 해당 그룹에 하나라도 멀쩡하면 넘어 갈수 있음
    --> 두개의 맴버를 하나의 그룹에 첫번째 맴버들을 한 디스크에 두번째 맴버를 또 다른 디스크에 저장
    --> 다른 작업은 다 잘됨 로그스위치도 해당 손상 파일을 제외하고 잘되나
    --> commit 하면 redo log 파일을 내리는데 이때 손상되어 있으면 나중에 복구 할수가 없음
    --> alert 파일을 확인해야 한다.
    --> 다른디스크의 정상 두번째 파일을 손상된 두번째 파일에 복사
  [4] redo log file 그룹 손상 : Inactive                                    -> 삭제 or 복사, 붙여넣기 or Clear logfile
    --> 유저가 일으킨 변경은 다 데이터파일에 반영이 된 상태임
    --> 다 쓰고 완료가 된생태 채크포인트가 끝난 싱테
    --> 완전 복구
    --> alter system checkpoint --> dbwr 일시키기
    --> 멀쩡한 그룹껄 가져와도 되고 아니면 없애버리고 새로 만들고 백업함
    --> active(채크포인트가 설정되어 있는 상태) 나 current(현재 쓰고 있는 상태) 인 경우엔 끔찍!!
  [5] datafile 손상 : temporary       Tablespace의 datafile                 -> restartup 또는 "추가 뒤 삭제"
    --> restartup 하면 자동으로 살아남
    --> tablespace 에 temp 파일을 추가 문제 있는 temp 파일을 삭제 해주면 됨
  [6] datafile 손상 : 일반            Tablespace의 datafile                 -> open   recover(open에서)
    --> emp, dept..
    --> 문제가 있는 파일만 offline 하고
    --> open 상태에서 복원 -> 복구함
    --> 인스턴스가 죽지는 않는다. user 들은 문제가 생길 수 있음
  [7] datafile 손상 : 시스템(및 Undo) Tablespace의 datafile                 -> closed recover(mount에서)
    --> 뇌손상
    --> 메타데이터가 들어있는 시스템 파일이 없으면 open 이 안됨
    --> mount 상태에서 복원 -> 복구함
  [8] datafile 손상 : 백업하지 않은 datafile                                -> create datafile + redo 적용
    --> 복원 복구할 파일이 없음
    --> 데이터 파일을 만들어서 리두로 복구
    --> 백업 하지 않아도 복구가 되긴 하지만
    --> 해당 테이블이 시스템 테이블, 언두 테이블 소속 이 아니여야하고 사라지고 난 이후 리두로그 파일이 다 있어야한다.
  [9] datafile 손상 : 디스크 손상으로 인해 datafile을 다른 위치로 restore     -> rename file + redo 적용
    --> 다른 디스크로 복사
    --> 변경된 위치 알려주고 복구 함

-` incomplete recovery `-

  [10] table drop purge : flashback으로 복구 불가능한 경우                  --> time-based   불완전 복구
    --> 모든데이터 복원 백업한부분
    --> 복원 데이터가 있는 상확으로 복구
    --> 리두로그 파일 새로 만들어지면
    --> control 파일에 새로운 만들어진 리두로그 파일위치 알려줌

-` Clone Database `-
** 중요함!!

  [11] Database의 백업 datafile을 이용해서 복제 DB 생성하기
    --> 기계가 두개 이상이면 그냥 디비 복사 startup 하면됨
    --> 새로운 머신이 없을때 디비를 복사해서 두는데 이름을 바꿔야 하는 상황 (클론디비)
    1. 필요한 데이터 파일만 복사
    2. 파라미터 파일 만듬
    3. 컨트롤 파일 만듬 (startup nomount create controfile)
    4. 리두로그 파일 만듬 (alter database redo log)

-` Clone Database를 이용한 불완전 복구 `-

  [12] Clone Database를 이용한 복구 (user-managed 방식)

-` incomplete recovery `-

  [13] current(또는 active) group 손상                                      --> cancel-based 불완전 복구
    --> dbwr 가 ckpt 로 신호를 받아서 datafile 을 쓰고 있는데 current 그룹이 갑자기 사라짐
    --> 갑자기 쓰고 있던 redo 가 없어짐
    --> 현재 datafile 동기화 정보가 다 안맞는 상황 (쓰다만 파일 보기에는 정상처럼 보이지만 버려야되는 파일 커밋여부도 알수없음)
    --> 리두로그 파일이 있는 것까지만 복구 시킴


=  실습 ▼   ================================================================================
-----------------------------------------------------------
 [0] parameter file 손상 1 : 파일이 삭제된 상황
-----------------------------------------------------------

  [oracle@ora11gr2 ~]$ ls -l $ORACLE_HOME/dbs/*brdb.ora
  [oracle@ora11gr2 ~]$ rm $ORACLE_HOME/dbs/*brdb.ora
*/
  [oracle@ora11gr2 ~]$ export ORACLE_SID=brdb
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> startup force

	ORA-01078: failure in processing system parameters
	LRM-00109: '/u01/app/oracle/product/11.2.0/dbhome_1/dbs/initbrdb.ora'

  SQL> exit

  [oracle@ora11gr2 ~]$ cd /u01/app/oracle/diag/rdbms/brdb/brdb/trace
  [oracle@ora11gr2 log]$ vi + alert_brdb.log

     --> 이 파일을 거슬러 올라가다 처음 발견되는 파라미터의 모음을 이용해서 아래와 같이 파일을 새로 만드세요.

  [oracle@ora11gr2 log]$ vi /u01/app/oracle/product/11.2.0/dbhome_1/dbs/initbrdb.ora

	processes                = 100
	shared_pool_size         = 75497472
	control_files            = /u01/app/oracle/oradata/brdb/control01.ctl, /u01/app/oracle/oradata/brdb/control02.ctl
	db_block_size            = 4096
	db_cache_size            = 67108864
	compatible               = 11.2.0
	log_archive_dest_1       = 'location=/u01/app/oracle/oradata/brdb_arch1/'
	log_archive_dest_2       = 'location=/u01/app/oracle/oradata/brdb_arch2/'
	undo_management          = AUTO
	undo_tablespace          = UNDOTBS01
	remote_login_passwordfile= EXCLUSIVE
	instance_name            = brdb
	db_name                  = brdb

  [oracle@ora11gr2 log]$ cd
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> startup
  SQL> create spfile from pfile;

  SQL> startup force
  SQL> show parameter spfile

	NAME                                 TYPE                   VALUE
	------------------------------------ ---------------------- ----------------------------------------------------------
	spfile                               string                 /u01/app/oracle/product/11.2.0/dbhome_1/dbs/spfilebrdb.ora



  -----------------------------------------------------------
   [0] parameter file 손상 2 : spfile에 오타 입력된 상황
  -----------------------------------------------------------

    [oracle@ora11gr2 ~]$ export ORACLE_SID=brdb
    [oracle@ora11gr2 ~]$ sqlplus / as sysdba
    SQL> startup force

    SQL> alter system set undo_management=auta scope=spfile;
    SQL> startup force

  	ORA-30043: Invalid value 'AUTA' specified for parameter 'Undo_Management'

    SQL> create pfile from spfile;
    SQL> !vi /u01/app/oracle/product/11.2.0/dbhome_1/dbs/initbrdb.ora

  	# 아래 파라미터만 수정하세요.

  	*.undo_management='AUTO'

    SQL> create spfile from pfile;
    SQL> startup force

    SQL> show parameter spfile

  	NAME                                 TYPE                   VALUE
  	------------------------------------ ---------------------- ----------------------------------------------------------
  	spfile                               string                 /u01/app/oracle/product/11.2.0/dbhome_1/dbs/spfilebrdb.ora

    SQL> exit

  -----------------------------------------------------------
   [0] password file 손상
  -----------------------------------------------------------

    [oracle@ora11gr2 ~]$ rm /u01/app/oracle/product/11.2.0/dbhome_1/dbs/orapwbrdb

  	--> 원격지에서 sys로 접속할 수 없게 됩니다. SQL*Plus, iSQL*Plus DBA, EM을 이용해서 sys로 접속할 수 없다는 것입니다.

    [oracle@ora11gr2 ~]$ orapwd file=/u01/app/oracle/product/11.2.0/dbhome_1/dbs/orapwbrdb password=weekend entries=5

  -----------------------------------------------------------
   [1] control file 1개 손상
  -----------------------------------------------------------

    [oracle@ora11gr2 ~]$ sqlplus / as sysdba
    SQL> startup force
    SQL> select name from v$controlfile;

  	NAME
  	-----------------------------------------------
  	/u01/app/oracle/oradata/brdb/control01.ctl
  	/u01/app/oracle/oradata/brdb/control02.ctl

    SQL> exit

    [oracle@ora11gr2 ~]$ rm /u01/app/oracle/oradata/brdb/control02.ctl

    [oracle@ora11gr2 ~]$ sqlplus / as sysdba
    SQL> startup force

  	ORA-00205: error in identifying control file, check alert log for more info

    SQL> select status from v$instance;

  	STATUS
  	------------------------
  	STARTED

    SQL> !vi + /u01/app/oracle/diag/rdbms/brdb/brdb/trace/alert_brdb.log

  	ORA-00202: control file: '/u01/app/oracle/oradata/brdb/control02.ctl'
  	ORA-27037: unable to obtain file status

    SQL> !cp /u01/app/oracle/oradata/brdb/control01.ctl /u01/app/oracle/oradata/brdb/control02.ctl
    SQL> startup force
    SQL> exit

  -----------------------------------------------------------
   [2] control file 몽땅 손상
  -----------------------------------------------------------

    [oracle@ora11gr2 ~]$ rm /u01/app/oracle/oradata/brdb/control*

    [oracle@ora11gr2 ~]$ sqlplus / as sysdba
    SQL> startup force

    SQL> select status from v$instance;

  	STATUS
  	------------------------
  	STARTED

    SQL> !vi + /u01/app/oracle/diag/rdbms/brdb/brdb/trace/alert_brdb.log

  	ORA-00202: control file: '/u01/app/oracle/oradata/brdb/control01.ctl'
  	ORA-27037: unable to obtain file status

    SQL> !cp /u01/app/oracle/oradata/brdb/control02.ctl /u01/app/oracle/oradata/brdb/control01.ctl --> 실패 : 모든 컨트롤 파일이 삭제되었음을 확인하는 순간이다.

    SQL> !vi /u01/app/oracle/oradata/openbackup/control_20120218.sql

  	--> 아래 내용만 남기고 다른 내용은 모두 삭제하시면 됩니다.

  	CREATE CONTROLFILE REUSE DATABASE "BRDB" NORESETLOGS  ARCHIVELOG
  	    MAXLOGFILES 16
  	    MAXLOGMEMBERS 2
  	    MAXDATAFILES 30
  	    MAXINSTANCES 1
  	    MAXLOGHISTORY 292
  	LOGFILE
  	  GROUP 1 (
  	    '/u01/app/oracle/oradata/brdb/redo01_a.log',
  	    '/u01/app/oracle/oradata/brdb/redo01_b.log'
  	  ) SIZE 20M,
  	  GROUP 2 (
  	    '/u01/app/oracle/oradata/brdb/redo02_a.log',
  	    '/u01/app/oracle/oradata/brdb/redo02_b.log'
  	  ) SIZE 20M
  	DATAFILE
  	  '/u01/app/oracle/oradata/brdb/system01.dbf',
  	  '/u01/app/oracle/oradata/brdb/undotbs01.dbf',
  	  '/u01/app/oracle/oradata/brdb/sysaux01.dbf'
  	CHARACTER SET US7ASCII
  	;

  	RECOVER DATABASE

  	ALTER SYSTEM ARCHIVE LOG ALL;
  	ALTER DATABASE OPEN;
  	ALTER TABLESPACE TEMP ADD TEMPFILE '/u01/app/oracle/oradata/brdb/temp01.tmp'
  	     SIZE 20971520  REUSE AUTOEXTEND ON NEXT 20971520  MAXSIZE 2048M;

    SQL> startup force nomount
    SQL> @/u01/app/oracle/oradata/openbackup/control_20120218.sql

    SQL> select status from v$instance;

  	STATUS
  	------------------------
  	OPEN

    SQL> !ls -l /u01/app/oracle/oradata/brdb/*.ctl

	-rw-r-----  1 oracle oinstall 6307840  9월 16 17:10 /u01/app/oracle/oradata/brdb/control01.ctl
	-rw-r-----  1 oracle oinstall 6307840  9월 16 17:10 /u01/app/oracle/oradata/brdb/control02.ctl
*/
-----------------------------------------------------------
 [3] redo log file 멤버 1개 손상
-----------------------------------------------------------

  SQL> col member format a60
  SQL> select group#, member from v$logfile;

  SQL> !rm /u01/app/oracle/oradata/brdb/redo02_a.log
  SQL> startup force

  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;

  SQL> !vi + /u01/app/oracle/diag/rdbms/brdb/brdb/trace/alert_brdb.log

	--> 파일을 거슬러 읽어가다보면 아래와 같은 내용을 만나게 될 것이다.

	ORA-00313: open failed for members of log group 2 of thread 1
	ORA-00312: online log 2 thread 1: '/u01/app/oracle/oradata/brdb/redo02_a.log'
	ORA-27037: unable to obtain file status

  SQL> !cp /u01/app/oracle/oradata/brdb/redo02_b.log /u01/app/oracle/oradata/brdb/redo02_a.log

  SQL> startup force

  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;

  SQL> !vi + /u01/app/oracle/diag/rdbms/brdb/brdb/trace/alert_brdb.log

-----------------------------------------------------------
 [4] redo log file 그룹 손상 : Inactive
-----------------------------------------------------------
  SQL> alter database add logfile ('/u01/app/oracle/oradata/brdb/redo03_a.log',
                                   '/u01/app/oracle/oradata/brdb/redo03_b.log') size 20M;

  SQL> alter system switch logfile;
  SQL> alter system switch logfile;

  SQL> select * from v$log;
  SQL> alter system checkpoint;
  SQL> select * from v$log where status = 'INACTIVE';

  SQL> select '!rm '||member from v$logfile
       where group# = (select max(group#)from v$log where status = 'INACTIVE');

  --> 강제로 환경 맞추기

  SQL> !rm /u01/app/oracle/oradata/brdb/redo0?_a.log   --> ?에 해당되는 숫자는 각자 다를 수 있습니다.
  SQL> !rm /u01/app/oracle/oradata/brdb/redo0?_b.log
  SQL> exit
  --> 그룹을 삭제함 startup 이 되지 않음 그룹별로 하나씩은 멀쩡해야됨
  --> mount 상태에서 올라가질 못함
  --> 그룹이 사라지면 logswitch 과정에서 다음 그룹으로 넘어가지 않고 에러남

  [oracle@ora11gr2 ~]$ export NLS_LANG=american_america.us7ascii
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> startup force

	ORA-00313: open failed for members of log group ? of thread 1
	ORA-00312: online log ? thread 1: '/u01/app/oracle/oradata/brdb/redo0?_a.log'
	ORA-00312: online log ? thread 1: '/u01/app/oracle/oradata/brdb/redo0?_b.log'

  SQL> exit

  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> startup mount

  SQL> select * from v$log;

	--> 질의결과를 통해 손상된 그룹이 inactive 그룹임을 확인했다.

  SQL> alter database drop logfile group ?;

  SQL> alter database open;

  SQL> select * from v$log;

  SQL> alter database add logfile group ? ('/u01/app/oracle/oradata/brdb/redo0?_a.log',
                                           '/u01/app/oracle/oradata/brdb/redo0?_b.log') size 10m;

  SQL> select * from v$log;

  --> 장애는 간단히 해결되었으나 반드시 Whole 백업을 해야 한다.
  --> 아카이빙이 안됐는 손상된거라면 아카이브 파일이 비게 된다.
  --> 백업이 안되어 있으면 복구에 문제가 될 수 있다.

  SQL> shutdown immediate
  SQL> !cp -R /u01/app/oracle/oradata/brdb/* /u01/app/oracle/oradata/dontouch
*/  SQL> exit

----------------------------------------------------------
 [5] datafile 손상 : temporary Tablespace의 datafile
----------------------------------------------------------

  [oracle@ora11gr2 ~]$ export ORACLE_SID=brdb
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> startup

  SQL> create tablespace users
       datafile '/u01/app/oracle/oradata/brdb/users01.dbf' size 20m;

  SQL> alter tablespace users begin backup;
  SQL> !cp /u01/app/oracle/oradata/brdb/users01.dbf /u01/app/oracle/oradata/dontouch
  SQL> alter tablespace users end backup;
  --> 컨트롤 파일의 내용이 바뀌면 백업을 해줘야 한다.

  SQL> create user james identified by bond default tablespace users temporary tablespace temp quota 1m on users;

  SQL> grant create session, create table
       to james;

  SQL> conn james/bond

  SQL> create table t1
       as select * from all_objects;

  --> 에러 만들기
  SQL> alter session set workarea_size_policy=manual;
    --> pga 자동 조정 기능을 사용하지 않겠다. 인덱스 bitmap 인덱스 오더바이 해시조인 ... pga 사용
  SQL> alter session set sort_area_size=10;
    --> 일부러 아주 작게 만듬

  SQL> !rm /u01/app/oracle/oradata/brdb/temp01.tmp
    --> 메모리가 모잘라도 쓸수 없도록 삭제 해버림

  SQL> select *
       from t1 a, t1 b, t1 c, t1 d
       order by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;
   --> 아주 큰 파일 join, order by pga 가 동작하게

  	ORA-01116: error in opening database file 201
  	ORA-01110: data file 201: '/u01/app/oracle/oradata/brdb/temp01.tmp'

  SQL> conn / as sysdba
  SQL> startup force
    --> 자동으로 살아남
  SQL> !ls -l /u01/app/oracle/oradata/brdb/temp01.tmp

  SQL> !vi + /u01/app/oracle/diag/rdbms/brdb/brdb/trace/alert_brdb.log
    --> 작업의 흔적이 남음
  	Mon Sep 19 14:23:33 2011
  	Re-creating tempfile /u01/app/oracle/oradata/brdb/temp01.tmp

	--> startup을 다시 하지 않고 문제를 해결하는 방법 : 11gWS2의 4-6 페이지를 참조하세요.

  SQL> exit

----------------------------------------------------------------
 [6] datafile 손상 : 일반 Tablespace의 datafile --> Open 복구
----------------------------------------------------------------

  [oracle@ora11gr2 ~]$ export ORACLE_SID=brdb
  [oracle@ora11gr2 ~]$ export NLS_LANG=american_america.us7ascii
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> startup force
  SQL> show user
  USER은 "SYS"입니다

  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;

  SQL> !rm /u01/app/oracle/oradata/brdb/users01.dbf
    --> 일반데이터파일이 죽어서 문제가 생기진 않는다.
  SQL> startup force
    --> online 상태의 데이터 파일이 멀쩡해야 open 됨

	ORA-01157: cannot identify/lock data file 4 - see DBWR trace file
	ORA-01110: data file 4: '/u01/app/oracle/oradata/brdb/users01.dbf'

  SQL> alter database datafile 4 offline; --> 있는대 이용하지 않는 파일
  SQL> alter database open;

  SQL> !cp /u01/app/oracle/oradata/dontouch/users01.dbf /u01/app/oracle/oradata/brdb/users01.dbf
    --> 복원
  SQL> recover datafile 4;
    --> 복원된 데이터 파일의 해더를 보고 scn 번호로 어떤 아카이브의 어느부분을 복구할지 이거냐고 물어봄
    --> RET 리턴
    --> 엔터를 치면서 하거나 아니면 auto로 한번에 함
    --> 해당 위치에 없으면 위치를 지정해 주면 됨 /app/oracle/oradata ...

	Specify log: {<RET>=suggested | filename | AUTO | CANCEL}
	|auto      <-- auto 입력

  SQL> alter database datafile 4 online;

---------------------------------------------------------------------------------
 [7] datafile 손상 : 시스템(및 Undo) Tablespace의 datafile --> Closed 복구
---------------------------------------------------------------------------------

  SQL> !rm /u01/app/oracle/oradata/brdb/system01.dbf

  SQL> startup force

  	ORA-01157: cannot identify/lock data file 1 - see DBWR trace file
  	ORA-01110: data file 1: '/u01/app/oracle/oradata/brdb/system01.dbf'

  SQL> alter database datafile 1 offline;

  SQL> alter database open;

    ORA-01147: SYSTEM tablespace file 1 is offline
	  ORA-01110: data file 1: '/u01/app/oracle/oradata/brdb/system01.dbf'

    --> 6번 처럼 복구 해보려다 에러남
    --> open 으로 갈수가 없다.
  SQL> !cp /u01/app/oracle/oradata/dontouch/system01.dbf /u01/app/oracle/oradata/brdb/system01.dbf

	** OPEN   복구를 수행할 때 대상 파일은 offline 상태여야 합니다.
	** CLOSED 복구를 수행할 때 대상 파일은 online  상태여야 합니다.

  SQL> alter database datafile 1 online;

  SQL> recover datafile 1;
    --> mount 상태
    --> 일반유저 접속은 안됨 (closed 복구로 분류하는 이유)

	Specify log: {<RET>=suggested | filename | AUTO | CANCEL}
	|auto      <-- auto 입력

  SQL> alter database open;


----------------------------------------------------------
 [8] datafile 손상 : 백업하지 않은 datafile
----------------------------------------------------------

  * 주의 사항 : http://cafe.naver.com/gsinternet/32

  SQL> col name format a60
  SQL> select FILE#, CREATION_CHANGE#, CREATION_TIME, name from v$datafile;
      FILE# CREATION_CHANGE# CREATION NAME
    ------- ---------------- -------- -----------------------------------------------------
          1                8 14/05/29 C:\ORACLEXE\APP\ORACLE\ORADATA\XE\SYSTEM.DBF
          2             1823 14/05/29 C:\ORACLEXE\APP\ORACLE\ORADATA\XE\SYSAUX.DBF
          3             2861 14/05/29 C:\ORACLEXE\APP\ORACLE\ORADATA\XE\UNDOTBS1.DBF
          4            15521 14/05/29 C:\ORACLEXE\APP\ORACLE\ORADATA\XE\USERS.DBF

    --> 컨트롤 파일에서 파일을 읽어옴
    --> 각 파일의 생년월일이 들어 있음

  SQL> create tablespace ms_ts datafile '/u01/app/oracle/oradata/brdb/ms_ts01.dbf' size 10m;
    --> 작은 공간을 만들고 백업을 안했다!

  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;

  SQL> !rm /u01/app/oracle/oradata/brdb/ms_ts01.dbf
    --> 백업을 안한것이 깨짐

  SQL> startup force

  	ORA-01157: cannot identify/lock data file 5 - see DBWR trace file
  	ORA-01110: data file 5: '/u01/app/oracle/oradata/brdb/ms_ts01.dbf'

  SQL> alter database datafile '/u01/app/oracle/oradata/brdb/ms_ts01.dbf' offline;
    --> 일반 파일 offline 하고

  SQL> alter database open;
    --> open 상태로 디비를 띄우고

  SQL> !cp /u01/app/oracle/oradata/dontouch/ms_ts01.dbf /u01/app/oracle/oradata/brdb/ms_ts01.dbf
    --> 복구를 하려고 하는데!!

	에러! : 백업하지 않는 datafile이 손상되었음을 발견하는 상황이 발생한 것이다.

  SQL> select FILE#, CREATION_CHANGE#, CREATION_TIME, name from v$datafile;

  SQL> alter database create datafile '/u01/app/oracle/oradata/brdb/ms_ts01.dbf';
    --> 사라진 파일이름 파일을 만들때
    --> 삭제된 파일의 생년월일을 넣어 마치 처음 사라진 파일이 만들어 진것 처럼 만듬
  SQL> recover datafile '/u01/app/oracle/oradata/brdb/ms_ts01.dbf';

	Specify log: {<RET>=suggested | filename | AUTO | CANCEL}
	|auto      <-- auto 입력

  SQL> alter database datafile '/u01/app/oracle/oradata/brdb/ms_ts01.dbf' online;

  SQL> drop tablespace ms_ts including contents and datafiles;


---------------------------------------------------------------------------
 [9] datafile 손상 : 디스크 손상으로 인해 datafile을 다른 위치로 restore
---------------------------------------------------------------------------

  SQL> !rm /u01/app/oracle/oradata/brdb/users01.dbf

  SQL> startup force

	ORA-01157: cannot identify/lock data file 4 - see DBWR trace file
	ORA-01110: data file 4: '/u01/app/oracle/oradata/brdb/users01.dbf'

  SQL> alter database datafile 4 offline;
  SQL> alter database open;

  --> 손상된 파일을 복원하려 했으나 원래 파일이 있던 디스크가 손상되어
      다른 위치로 복원해야만 한다면 아래와 같은 방법을 사용하시면 됩니다.

  SQL> !mkdir /u01/app/oracle/oradata/disk1
  SQL> !cp /u01/app/oracle/oradata/dontouch/users01.dbf /u01/app/oracle/oradata/disk1/users01.dbf
    --> 전혀 다른 디스크로 복사
  SQL> alter database rename file '/u01/app/oracle/oradata/brdb/users01.dbf' to '/u01/app/oracle/oradata/disk1/users01.dbf';
    --> 변경된 파일 위치를 알려줌

  SQL> recover datafile 4;
    --> 새로운 위치의 파일에 헤더를 읽어서 어디까지 복구 할지 정함

	Specify log: {<RET>=suggested | filename | AUTO | CANCEL}
	|auto      <-- auto 입력

  SQL> alter database datafile 4 online;

  SQL> col file_name format a60
  SQL> select tablespace_name, file_name from dba_data_files
       union all
       select tablespace_name, file_name from dba_temp_files;

  	TABLESPACE_NAME      CONTENTS  FILE_NAME
  	-------------------- --------- --------------------------------------------------
  	USERS                PERMANENT /u01/app/oracle/oradata/disk1/users01.dbf    <-- 파일의 위치에 주목하세요.

  -- 정리

  SQL> drop tablespace users including contents and datafiles;
  SQL> !rm -r /u01/app/oracle/oradata/disk1
  SQL> shutdown immediate

  -- Whole backup 및 과거 백업 정리

  SQL> !rm -rf /u01/app/oracle/oradata/dontouch/*
  SQL> !rm -rf /u01/app/oracle/oradata/brdb_arch1/*
  SQL> !rm -rf /u01/app/oracle/oradata/brdb_arch2/*

  SQL> !cp /u01/app/oracle/oradata/brdb/* /u01/app/oracle/oradata/dontouch
  SQL> exit
*/
*******************************************************
 아래에서는 불완전 복구 상황들을 다룹니다.
*******************************************************

----------------------------------------------------------------
 [10] table drop purge : flashback으로 복구 불가능한 경우
----------------------------------------------------------------

  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> startup force

  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;

  SQL> alter user james quota 1m on system;
    --> 공간 할당을 해줌
  SQL> create table james.t2 (no number) tablespace system;
  SQL> insert into james.t2 values (1000);
  SQL> insert into james.t2 values (2000);
  SQL> commit;

  SQL> select * from james.t2;

  SQL> alter system switch logfile;
  SQL> alter system switch logfile;

  SQL> !date
    --> 에러가 발생하기 직전에 시간 확인 (실습의 편의상)
    --> 현실에서는 대략 시점을 잡아서 Logminer로 전부 시간을 찾아봐야 한다.

	   2012. 02. 23. (목) 15:10:29 KST

	   --> 실제 상황에서는 Logminer를 이용해서 에러가 발생한 시간을 확인하면 됩니다.
	    예제 : http://energ.tistory.com/entry/oracle-logminer

  SQL> alter system switch logfile;
  SQL> alter system switch logfile;

  SQL> drop table james.t2 purge;
  SQL> select * from james.t2;

    ORA-00942: table or view does not exist

  SQL> show recyclebin

  	--> 중요한 테이블이 삭제되었음을 알게되어 recyclebin을 확인했으나 완전히 삭제되었음을 알게되었다.
  	--> 아직 clone database를 이용한 복구를 알지 못하는 수준이기에 일반적인 불완전 복구를 수행하기로 결정한다.

               모든 datafile 복원
                      ↓
               startup mount;
                      ↓
               recover database until time '원하는 시점';
                      ↓
               alter database open resetlogs;
    --> 버리던지 아니면 요까지 복구
  SQL> shutdown abort

  SQL> !cp /u01/app/oracle/oradata/dontouch/*.dbf /u01/app/oracle/oradata/brdb
    --> 모든 데이터 파일 복원 */
  SQL> startup mount;
  SQL> recover database until time '2017-06-12 16:22:01';
    --> 시간을 줘서 그때까지의 상황을 복원
	Specify log: {<RET>=suggested | filename | AUTO | CANCEL}
	|auto      <-- auto 입력

  SQL> alter database open resetlogs;
    --> 리두로그 파일, 컨트롤 파일 동기화 정보 맞춰주기
    --> 새로운 리두로그 파일이 생성
    --> 컨터롤 파일은 새로운 리두로그 정보를 알아야함

  SQL> select * from james.t2;

	        NO
	----------
	      2000
	      1000

  SQL> select * from v$log;


	    GROUP#    THREAD#  SEQUENCE#      BYTES    MEMBERS ARC STATUS           FIRST_CHANGE# FIRST_TIM
	---------- ---------- ---------- ---------- ---------- --- ---------------- ------------- ---------
        	 1          1          0   20971520          2 YES UNUSED                       0
	         2          1          1   20971520          2 NO  CURRENT                 515775 10-DEC-11
	         3          1          0   10485760          2 YES UNUSED                       0

	--> 여러 그룹의 status가 unused이고 sequence#이 0이라는 것에 주목하세요.

  SQL> exit

------------------------------------------------------------------------
 [11] Database의 백업 datafile을 이용해서 복제 DB 생성하기
------------------------------------------------------------------------

  * 참고 : http://gseducation.blog.me/20096193881

  [oracle@ora11gr2 ~]$ mkdir /home/oracle/cldb
    --> 복재할 디비
  [oracle@ora11gr2 ~]$ cp /u01/app/oracle/oradata/dontouch/*.dbf /home/oracle/cldb
    --> 데이터 파일 전부를 복제
*/

  --> 요래 해도되고 해도되고
  --> brdb 를 그대로 가져온거니까 파라미터파일과 컨트롤 파일을 brdb 로 부터 가져옴
  --> db 이름만 바꿔주면됨
  [oracle@ora11gr2 ~]$ export ORACLE_SID=brdb
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> create pfile='/home/oracle/cldb/initcldb.ora' from spfile;
  SQL> alter database backup controlfile to trace as '/home/oracle/cldb/create_cldb_controlfile.sql';

  SQL> !ls -l  /home/oracle/cldb

	-rw-r--r--  1 oracle oinstall      6648  9월 20 14:39 create_babadb_controlfile.sql
	-rw-r--r--  1 oracle oinstall       579  9월 20 14:38 initbabadb.ora
	-rw-r-----  1 oracle oinstall 209719296  9월 20 14:36 sysaux01.dbf
	-rw-r-----  1 oracle oinstall 209719296  9월 20 14:37 system01.dbf
	-rw-r-----  1 oracle oinstall 125833216  9월 20 14:37 undotbs01.dbf

  SQL> exit

  [oracle@ora11gr2 ~]$ vi /home/oracle/cldb/initcldb.ora

  	*.db_name='cldb'
  	*.instance_name='cldb'
  	*.compatible='11.2.0'
  	*.control_files='/home/oracle/cldb/control01.ctl'
  	*.log_archive_dest_1='location=/home/oracle/cldb/'
  	*.db_block_size=4096
  	*.db_cache_size=67108864
  	*.processes=100
  	*.remote_login_passwordfile='EXCLUSIVE'
  	*.shared_pool_size=75497472
  	*.undo_management='auto'
  	*.undo_tablespace='UNDOTBS01'

  [oracle@ora11gr2 ~]$ vi /home/oracle/cldb/create_cldb_controlfile.sql
    --> 생성 스크립트 실행해서 컨트롤 파일 만들어줄

  	CREATE CONTROLFILE set DATABASE "cldb" resetlogs  ARCHIVELOG
  	LOGFILE
  	  GROUP 1 (
  	    '/home/oracle/cldb/redo01_a.log'
  	  ) SIZE 20M,
  	  GROUP 2 (
  	    '/home/oracle/cldb/redo02_a.log'
  	  ) SIZE 20M
  	DATAFILE
  	  '/home/oracle/cldb/system01.dbf',
  	  '/home/oracle/cldb/undotbs01.dbf',
  	  '/home/oracle/cldb/sysaux01.dbf'
  	CHARACTER SET US7ASCII;

  --> 생겼으면 하는 위치에 리두로그 파일 잡아줌
  --> datafile 의 위치와 이름을 잘 잡아 줘야됨

  [oracle@ora11gr2 ~]$ export ORACLE_SID=cldb
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> startup nomount pfile=/home/oracle/cldb/initcldb.ora
    --> 아직 컨트롤 파일은 없음 위치만 줬고 스크립트만 만들었음
    --> /home/oracle/cldb/control01.ctl
  SQL> @/home/oracle/cldb/create_cldb_controlfile.sql

  SQL> select status from v$instance;

  	STATUS
  	------------
  	MOUNTED

  SQL> !ls -l  /home/oracle/cldb

  	-rw-r-----  1 oracle oinstall   6078464  9월 20 14:50 control01.ctl
  	-rw-r--r--  1 oracle oinstall       446  9월 20 14:47 create_cldb_controlfile.sql
  	-rw-r--r--  1 oracle oinstall       371  9월 20 14:42 initbabadb.ora
  	-rw-r-----  1 oracle oinstall 209719296  9월 20 14:36 sysaux01.dbf
  	-rw-r-----  1 oracle oinstall 209719296  9월 20 14:37 system01.dbf
  	-rw-r-----  1 oracle oinstall 125833216  9월 20 14:37 undotbs01.dbf

  SQL> alter database open resetlogs;
    --> 리두로그 위치만 있으니까 다시 만들어줌 있어도 다시 만들고 없어도 다시 만들고
  SQL> !ls -l  /home/oracle/cldb

  	-rw-r-----  1 oracle oinstall   6078464  9월 20 14:52 control01.ctl
  	-rw-r--r--  1 oracle oinstall       446  9월 20 14:47 create_babadb_controlfile.sql
  	-rw-r--r--  1 oracle oinstall       371  9월 20 14:42 initbabadb.ora
  	-rw-r-----  1 oracle oinstall  20972032  9월 20 14:51 redo01_a.log
  	-rw-r-----  1 oracle oinstall  20972032  9월 20 14:51 redo02_a.log
  	-rw-r-----  1 oracle oinstall 209719296  9월 20 14:51 sysaux01.dbf
  	-rw-r-----  1 oracle oinstall 209719296  9월 20 14:51 system01.dbf
  	-rw-r-----  1 oracle oinstall 125833216  9월 20 14:51 undotbs01.dbf

  SQL> select instance_name, status from v$instance;

  	INSTANCE_NAME                    STATUS
  	-------------------------------- ------------------------
  	babadb                           OPEN

  SQL> col member format a60
  SQL> select * from v$log;
  SQL> select * from v$logfile;

  SQL> shutdown abort
  SQL> exit

  [oracle@ora11gr2 ~]$ rm -rf /home/oracle/cldb

------------------------------------------------------------------------
 [12] Clone Database를 이용한 복구 (user-managed 방식)
------------------------------------------------------------------------

  [oracle@ora11gr2 ~]$ export NLS_LANG=american_america.us7ascii
  [oracle@ora11gr2 ~]$ export ORACLE_SID=brdb
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> startup force

  SQL> alter system switch logfile;
  SQL> alter system switch logfile;

  SQL> shutdown immediate
  SQL> !cp -R /u01/app/oracle/oradata/brdb/* /u01/app/oracle/oradata/dontouch
*/
  SQL> startup

  SQL> insert into james.t2 values (3000);
  SQL> insert into james.t2 values (4000);
  SQL> commit;

  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;

  SQL> select * from  james.t2;

  SQL> !date

	 2012. 02. 23. (목) 17:15:46 KST

  SQL> alter system switch logfile;
  SQL> alter system switch logfile;

  --> 에러 발생 !!!!!!!!!!!!!
  SQL> drop table  james.t2 purge;

  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;
  SQL> alter system switch logfile;

  SQL> select * from  james.t2;

	 ORA-00942: table or view does not exist

  SQL> show recyclebin
  SQL> exit

	--> 중요한 테이블이 삭제되었음을 알게되어 recyclebin을 확인했으나 완전히 삭제되었음을 알게되었다.
	--> 그래서 clone database를 이용한 복구를 수행하기로 결정한다.

	       clone database를 이용한 불완전 복구
                      ↓
               필요한 테이블 export
                      ↓
               사용중인 database로 import

  --> 안되겠다!!! 클론디비를 만들자!
  [oracle@ora11gr2 ~]$ mkdir /home/oracle/clonedb
  [oracle@ora11gr2 ~]$ cp /u01/app/oracle/oradata/dontouch/*.dbf /home/oracle/clonedb
    --> 데이터 파일 전부
  [oracle@ora11gr2 ~]$ cp /u01/app/oracle/oradata/brdb_arch1/*   /home/oracle/clonedb
    --> 아카이브로그 파일 전부
  [oracle@ora11gr2 ~]$ cp /u01/app/oracle/oradata/brdb/*.log     /home/oracle/clonedb
    --> 리두로그 파일 전부
  [oracle@ora11gr2 ~]$ ls -l /home/oracle/clonedb
*/
  --> brdb 에가서 클론디비를 또 만들어줌
  [oracle@ora11gr2 ~]$ export ORACLE_SID=brdb
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> create pfile='/home/oracle/clonedb/initclonedb.ora' from spfile;
  SQL> alter database backup controlfile to trace as '/home/oracle/clonedb/create_clonedb_controlfile.sql';
  SQL> exit

  [oracle@ora11gr2 ~]$ vi /home/oracle/clonedb/initclonedb.ora

  	*.db_name='clonedb'
  	*.instance_name='clonedb'
  	*.compatible='11.2.0'
  	*.control_files='/home/oracle/clonedb/control01.ctl'
  	*.log_archive_dest_1='location=/home/oracle/clonedb/'
  	*.db_block_size=4096
  	*.db_cache_size=67108864
  	*.processes=100
  	*.remote_login_passwordfile='EXCLUSIVE'
  	*.shared_pool_size=75497472
  	*.undo_management='auto'
  	*.undo_tablespace='UNDOTBS01'

    -- 위치 지정
    -- *.control_files='/home/oracle/clonedb/control01.ctl'
  	-- *.log_archive_dest_1='location=/home/oracle/clonedb/'
  [oracle@ora11gr2 ~]$ vi /home/oracle/clonedb/create_clonedb_controlfile.sql
    --> 복사해온 온라인리두로그 파일 위치를 줘야함

  	CREATE CONTROLFILE set DATABASE "clonedb" resetlogs  ARCHIVELOG
  	LOGFILE
  	  GROUP 1 (
  	    '/home/oracle/clonedb/redo01_a.log'
  	  ) SIZE 20M,
  	  GROUP 2 (
  	    '/home/oracle/clonedb/redo02_a.log'
  	  ) SIZE 20M,
  	  GROUP 3 (
  	    '/home/oracle/clonedb/redo03_a.log'
  	  ) SIZE 10M
  	DATAFILE
  	  '/home/oracle/clonedb/system01.dbf',
  	  '/home/oracle/clonedb/undotbs01.dbf',
  	  '/home/oracle/clonedb/sysaux01.dbf'
  	CHARACTER SET US7ASCII;

  [oracle@ora11gr2 ~]$ export ORACLE_SID=clonedb
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> startup nomount pfile=/home/oracle/clonedb/initclonedb.ora
  SQL> @/home/oracle/clonedb/create_clonedb_controlfile.sql

  SQL> !ls -l /home/oracle/clonedb

  SQL> select instance_name, status from v$instance;

  	INSTANCE_NAME                    STATUS
  	-------------------------------- ------------------------
  	clonedb                          MOUNTED

  SQL> -- 아래 명령에서 사용되는 시간은 모두 다릅니다. 위의 date 명령에서 확인한 시간을 사용하세요.

  SQL> recover database until time '2012-02-23 17:15:46' USING backup controlfile;

  	Specify log: {<RET>=suggested | filename | AUTO | CANCEL}
  	|auto      <-- auto 입력

  	... 생략 ...

  SQL> alter database open resetlogs;
  SQL> select * from  james.t2;
  SQL> exit

  [oracle@ora11gr2 ~]$ exp james/bond file=a.dmp tables=t2

  [oracle@ora11gr2 ~]$ export ORACLE_SID=brdb
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> select * from james.t2;
  SQL> !imp james/bond file=a.dmp tables=t2
  SQL> select * from james.t2;
  SQL> exit

  [oracle@ora11gr2 ~]$ export ORACLE_SID=clonedb
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> shutdown  abort
  SQL> exit

  [oracle@ora11gr2 ~]$ rm -rf /home/oracle/clonedb


--------------------------------------------------------------
 [13] current(또는 active) group 손상
--------------------------------------------------------------

 - 에러 상황 재현

  SQL> startup

  SQL> alter system switch logfile;
  SQL> /
  SQL> /
  SQL> /
  SQL> /
  SQL> /

  SQL> select group#, status from v$log;

  SQL> select '!rm '||member as commands from v$logfile
       where group# = (select MAX(group#) from v$log where status = 'CURRENT');

  SQL> !rm /u01/app/oracle/oradata/prod/redo0□_a.log
  SQL> !rm /u01/app/oracle/oradata/prod/redo0□_b.log

  SQL> startup force

  	ORA-00313: open failed for members of log group □ of thread 1
  	ORA-00312: online log □ thread 1: '/u01/app/oracle/oradata/prod/redo0□_a.log'
  	ORA-00312: online log □ thread 1: '/u01/app/oracle/oradata/prod/redo0□_b.log'

  SQL> select * from v$log order by group#;

        --> 삭제된 그룹이 CURRENT임을 확인하고 복구를 수행한다.

  SQL> alter database clear logfile group □;

  	ORA-01624: log □ needed for crash recovery of instance prod (thread 1)
  	ORA-00312: online log □ thread 1: '/u01/app/oracle/oradata/prod/redo0□_a.log'
  	ORA-00312: online log □ thread 1: '/u01/app/oracle/oradata/prod/redo0□_b.log'

        --> CURRENT 그룹은 clear할 수 없다.

  SQL> alter database drop logfile group □;

  	ORA-01623: log □ is current log for instance prod (thread 1) - cannot drop
  	ORA-00312: online log □ thread 1: '/u01/app/oracle/oradata/prod/redo0□_a.log'
  	ORA-00312: online log □ thread 1: '/u01/app/oracle/oradata/prod/redo0□_b.log'

        --> CURRENT 그룹은 clear할 수 없다.

 - 복구

  SQL> shutdown abort
  SQL> !cp /u01/app/oracle/oradata/dontouch/*.dbf /u01/app/oracle/oradata/prod    --> 모든 datafile 복원
  SQL> startup mount                                                              --> Startup mount */
  SQL> recover database;

  	Specify log: {<RET>=suggested | filename | AUTO | CANCEL}
  	auto       <-- 입력

          ...

  	ORA-00283: recovery session canceled due to errors
  	ORA-00313: open failed for members of log group 2 of thread 1
  	ORA-00312: online log 2 thread 1: '/u01/app/oracle/oradata/prod/redo02_b.log'
  	ORA-27037: unable to obtain file status
  	Linux Error: 2: No such file or directory
  	Additional information: 3
  	ORA-00312: online log 2 thread 1: '/u01/app/oracle/oradata/prod/redo02_a.log'
  	ORA-27037: unable to obtain file status
  	Linux Error: 2: No such file or directory
  	Additional information: 3

  	ORA-01112: media recovery not started

	--> 에러가 발생하면 복구가 중지됩니다.

  SQL> recover database until cancel;

  	Specify log: {<RET>=suggested | filename | AUTO | CANCEL}
  	cancel     <-- 입력

  --> 정상 복구함 current redo 파일전까지
  --> 아직 current때매 오픈은 안됨

  SQL> !ls -l /u01/app/oracle/oradata/prod/*.log        --> 아직 삭제된 redo log file이 복구되지 않았음을 확인
*/
  SQL> alter database open resetlogs;
  --> 아애 다 새로 생김
  --> 새로 생긴 리두로그 파일에 컨트롤 파일이 변경되고 끝

  SQL> !ls -l /u01/app/oracle/oradata/prod/*.log        --> 삭제된 redo log file이 복구되었음을 확인

  SQL> select * from v$log;
*/
	    GROUP#    THREAD#  SEQUENCE#      BYTES    MEMBERS ARC STATUS           FIRST_CHANGE# FIRST_TIM
	---------- ---------- ---------- ---------- ---------- --- ---------------- ------------- ---------
	         1          1          0   20971520          2 YES UNUSED                       0
	         2          1          1   20971520          2 NO  CURRENT                 963987 21-JUL-11
	         3          1          0   10485760          2 YES UNUSED                       0
	         4          1          0   10485760          2 YES UNUSED                       0

  SQL> shutdown immediate
  SQL> !ls -l /u01/app/oracle/oradata/prod_arch1/
  SQL> !rm /u01/app/oracle/oradata/prod_arch1/*
  SQL> !rm /u01/app/oracle/oradata/prod_arch2/*
*/
  SQL> !cp /u01/app/oracle/oradata/prod/* /u01/app/oracle/oradata/dontouch
  SQL> !ls -l /u01/app/oracle/oradata/dontouch
  SQL> exit
*/

 *************************************************
  cf.OMF 방식으로 Database 생성하기
 *************************************************

  0.디렉토리 및 파라미터 파일 생성

   OS] mkdir /u01/app/oracle/oradata/omfdb               --> Database Area
   OS] mkdir /u01/app/oracle/oradata/omfdb_dontouch      --> Recovery Area
   OS] vi $ORACLE_HOME/dbs/initomfdb.ora

	db_name       = omfdb
	instance_name = omfdb
	compatible    = 11.2.0
	processes     = 100

	undo_management = auto

	db_cache_size    = 64m
	shared_pool_size = 72m
	db_block_size    = 4096

        db_create_file_dest         = '/u01/app/oracle/oradata/omfdb/'
        db_create_online_log_dest_1 = '/u01/app/oracle/oradata/omfdb/'
        db_create_online_log_dest_2 = '/u01/app/oracle/oradata/omfdb/'

        db_recovery_file_dest_size = 4G
        db_recovery_file_dest = '/u01/app/oracle/oradata/omfdb_dontouch/'

	remote_login_passwordfile = exclusive


  1.Software 시작

    OS] export ORACLE_SID=omfdb
    OS] sqlplus / as sysdba
    SQL> startup nomount

  2.Create database 명령 실행

    SQL> create database omfdb;

    SQL> ed db.sql

        col name format a80

        select name from v$controlfile
        union all
        select member from v$logfile
        union all
        select name from v$datafile
        union all
        select name from v$tempfile;

    SQL> @db.sql

    	NAME
    	--------------------------------------------------------------------------------
    	/u01/app/oracle/oradata/omfdb/OMFDB/controlfile/o1_mf_72sp107p_.ctl
    	/u01/app/oracle/oradata/omfdb/OMFDB/controlfile/o1_mf_72sp10cp_.ctl
    	/u01/app/oracle/oradata/omfdb/OMFDB/onlinelog/o1_mf_1_72sp10gm_.log
    	/u01/app/oracle/oradata/omfdb/OMFDB/onlinelog/o1_mf_1_72sp10q0_.log
    	/u01/app/oracle/oradata/omfdb/OMFDB/onlinelog/o1_mf_2_72sp12l9_.log
    	/u01/app/oracle/oradata/omfdb/OMFDB/onlinelog/o1_mf_2_72sp159p_.log
    	/u01/app/oracle/oradata/omfdb/OMFDB/datafile/o1_mf_system_72sp1b97_.dbf
    	/u01/app/oracle/oradata/omfdb/OMFDB/datafile/o1_mf_sys_undo_72sp1nf7_.dbf
    	/u01/app/oracle/oradata/omfdb/OMFDB/datafile/o1_mf_sysaux_72sp1nxp_.dbf

    SQL> create temporary tablespace temp;
    SQL> create tablespace users1;
    SQL> create tablespace users2;

    SQL> alter user sys identified by oracle;      --> 기본 암호 : change_on_install
    SQL> alter user system identified by oracle;   --> 기본 암호 : manager

  3.필수 Script 수행

    SQL> ed after_db_create.sql

    	conn sys/oracle as sysdba
    	@?/rdbms/admin/catalog.sql
    	@?/rdbms/admin/catproc.sql

    	conn system/oracle
    	@?/sqlplus/admin/pupbld.sql

    SQL> @ after_db_create.sql

    --> 아래 질의 결과를 이용해서 control_files 파라미터를 추가 설정하세요.

    SQL> select name from v$controlfile;

    	NAME
    	--------------------------------------------------------------------------------
    	/u01/app/oracle/oradata/omfdb/OMFDB/controlfile/각자파일이름이다릅니다1.ctl
    	/u01/app/oracle/oradata/omfdb/OMFDB/controlfile/각자파일이름이다릅니다2.ctl

    SQL> !vi $ORACLE_HOME/dbs/initomfdb.ora

	# 다음 파라미터를 추가하세요.

	control_files = /u01/app/oracle/oradata/omfdb/OMFDB/controlfile/각자파일이름이다릅니다1.ctl, /u01/app/oracle/oradata/omfdb/OMFDB/controlfile/각자파일이름이다릅니다2.ctl

    SQL> connect / as sysdba
    SQL> startup force

    SQL> create tablespace ts100;
    SQL> create tablespace ts101 datafile size 10m;
    SQL> alter database add logfile size 10m;

    SQL> drop tablespace ts100;
    SQL> drop tablespace ts101;
    SQL> alter database drop logfile group 3;
    SQL> exit

___
