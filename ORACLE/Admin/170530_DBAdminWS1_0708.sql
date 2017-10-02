
++++++++++++++++++++++++++++++
 07.Managing Database Storage Structures
++++++++++++++++++++++++++++++

* alter system dump datafile ... 블럭 덤프뜨기

## Block
* block header 에 여기저기 있는 위치 값을 가지고 있음
  header : 관리 정보
* DBA (Data Block Address)
* row directory
  : 출입구에 있는 각 row 정보의 위치값을 가짐 rowid 로 block 까지 접근하고 row directory 의 row 위치를 찾음
  rowid (object(tablespace), file, block, row 정보)
  index (keyvalue, rowid) rowid 는 정확히 하면 block 의 row directory 를 가리킴
  rowid (서울시 동작구 대방동 1-6)
  row directory (501호 세번째 방)
  - migration : block 에 더이상 공간이 없는 경우 다른 블럭에 row 를 저장함
    해당 row 의 index (row directory) 에는 옛날 주소가 있고 옛날 주소에 이사간 신 주소를 가르키게 해놓음 (io 의 횟수는 증가함)
    (reorganization 너무 많은 migration 이 있는 경우 전부다 다시 배열해서 넣고 다시 index 를 생성해야 함)
  - chaining : 데이터가 커서 2 block 이상을 차지하고 있는 것

* transaction slots 에 기록을 하고 block 변경을 함 dml
  이 트렌젝션이 이 블럭을 바꾼다 undo 를 가리키고 있음
  enq tx itl entry

* pctfree : update 용 여유 공간 확보

# EM 에서의 Block 설정
  * type
  - Permanent : 모든 형태가 가능한
  - Temporary : 전문 세그먼트
    오직 그것만 들어 올수 있는


# Tablespace 관련 개념

  - ASM  vs File System  : Stograge    cf.Raw device
  - OMF  vs UMF          : File        cf.Database Area vs Recovery Area
                                       cf.OMF 방식으로 수동 DB 생성 : http://cafe.naver.com/gseducation/1723
  - LMT  vs DMT          : Extent
  - ASSM vs MSSM         : Block

  - Permanent  vs Undo, Temporary
  - Read-write vs Read-only
  - Online     vs Offline
  - Logging    vs Nologging

  - SFT        vs BFT

  - Multple Block Size

# LMT vs DMT, ASSM vs MSSM

  [oracle@ora11gr2 ~]$ export ORACLE_SID=prod
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba

  SQL> create tablespace ts1
       datafile '/u01/app/oracle/oradata/prod/ts1.dbf' size 10m
       extent management LOCAL            -- LMT(default)
       segment space management AUTO      -- ASSM(default)

  SQL> create tablespace ts2
       datafile '/u01/app/oracle/oradata/prod/ts2.dbf' size 10m
       extent management LOCAL            -- LMT
       segment space management MANUAL    -- MSSM

  SQL> create tablespace ts3
       datafile '/u01/app/oracle/oradata/prod/ts3.dbf' size 10m
       extent management DICTIONARY       -- DMT
       segment space management AUTO      -- ASSM

	--> 에러 : ORA-30572: AUTO segment space management not valid with DICTIONARY extent management

  SQL> create tablespace ts4
       datafile '/u01/app/oracle/oradata/prod/ts4.dbf' size 10m
       extent management DICTIONARY       -- DMT
       segment space management MANUAL    -- MSSM

  SQL> set pages 100
  SQL> select TABLESPACE_NAME, CONTENTS, EXTENT_MANAGEMENT, SEGMENT_SPACE_MANAGEMENT
       from dba_tablespaces;

	TABLESPACE_NAME                CONTENTS  EXTENT_MAN SEGMEN
	------------------------------ --------- ---------- ------
	SYSTEM                         PERMANENT DICTIONARY MANUAL
	UNDOTBS01                      UNDO      LOCAL      MANUAL
	SYSAUX                         PERMANENT LOCAL      AUTO
	TEMP                           TEMPORARY LOCAL      MANUAL
	UNDOTBS02                      UNDO      LOCAL      MANUAL
	TEMP_TS                        TEMPORARY LOCAL      MANUAL
	USERS                          PERMANENT LOCAL      AUTO
	APP_TS                         PERMANENT LOCAL      AUTO
	TBS1                           PERMANENT LOCAL      AUTO
	TS1                            PERMANENT LOCAL      AUTO
	TS2                            PERMANENT LOCAL      MANUAL
	TS4                            PERMANENT DICTIONARY MANUAL


	--> System Tablespace가 DMT면 LMT, DMT가 모두 가능하고,
            System Tablespace가 LMT면 LMT만 가능하다.
	--> DBCA로   DB를 생성하면 System Tablespace가 LMT가 된다.
            수동으로 DB를 생성하면 System Tablespace가 DMT가 된다.


* EXTENT 할당 방식
local extent 할당되고 반납될때마다 로컬에서 관리
dictionary extent 할당되고 반납될때마다 딕셔너리에서 관리

Tablespace hearer | Segment header | block header | row hearder

* Freelist
  insert 를 동시에 하는 경우
    MSSM
      빈 블럭의 link 의 첫번째 값을 가지고 있음
      한번 하나씩 freelist 를 공간을 뒤짐
      ---------
        Block1  Block2      Block3
        Segment BlockHeader BlockHeader
      ---------
    ASSM
      들어오는 값들을 hasing 해서 데이터를 나눠 free block 을 할당함 Segment 가 ROOT(Segment) 가 Branch 를 가리키고
      Branch 가 leaf를 가리킴
      ---------
        Block1  Block2  Block3
        Leaf    Leaf    Leaf      > L1
        Branch  Branch  ...       > L2
        Segment ...     ...       > L3
        ...     ...     ...
      ---------

* Fragmentation 단편화
  총량은 많은데 실제로 쓸수 있는게 없는 상태
  서로다른크기, 들락날락
  DATABASE buffer cache 에는 단편화가 없다. 다 같은 크기여서
  shared_pool 에는 단편화가 있음
  Extent Allocation
    Automatic : 그때 끄때 다르게 할당
    Extent management autoallocate/local uniform (1M 고정)(size 4M)

## tablespace 삭제
  datefile 도 같이 없애기
  OMF
  including ...

## OMF 사용 Oracle-managed files
  파일을 마치 객체처럼 다룰 수 있게 해줌





============================================
 8장 Administering User Security
============================================
-- 지금까지는 도시를 건설하는 작업을함
-- 사람을 만들고 보호를 위한 작업

    - authentication
    - profile (cf.resource manager)
    - role
    - create user
    - grant : privilege, role

  ---------------------------------
   User 생성전 확인하는 것들
  ---------------------------------
    -- ANY 권한 가장 강력함
    select * from dba_users;
    select * from dba_tablespaces;

    select * from dba_sys_privs;
    select * from dba_sys_privs where grantee in ('CONNECT', 'RESOURCE');
    select distinct privilege from dba_sys_privs order by 1;
    select distinct privilege from dba_sys_privs where privilege like '%ROLE%';

    select * from dba_roles;
    select * from dba_profiles;

  ---------------------------------
   Authentication
  ---------------------------------

   [1] Database 일반 유저

    - Database 인증

      [oracle@ora11gr2 ~]$ export ORACLE_SID=prod
      [oracle@ora11gr2 ~]$ sqlplus / as sysdba
      SQL> startup force

      SQL> create user orange
           identified by orange;

      SQL> grant create session
           to orange;

      SQL> exit

      [oracle@ora11gr2 ~]$ sqlplus orange/orange
      SQL> show user
      SQL> exit

    - 운영체제 인증

      [oracle@ora11gr2 ~]$ sqlplus /

  	에러 : ORA-01017: invalid username/password; logon denied

      [oracle@ora11gr2 ~]$ whoami

  	oracle

      [oracle@ora11gr2 ~]$ sqlplus / as sysdba
      SQL> show parameter prefix

  	NAME                                 TYPE        VALUE
  	------------------------------------ ----------- ------------------------------
  	os_authent_prefix                    string      ops$

      SQL> create user ops$oracle
           identified externally;

      SQL> grant create session
           to ops$oracle;

      SQL> exit

      [oracle@ora11gr2 ~]$ sqlplus /
      SQL> show user

  	USER is "OPS$ORACLE"

      SQL> conn / as sysdba
      SQL> drop user ops$oracle;
      SQL> alter system set os_authent_prefix='' scope=spfile;
      SQL> startup force

      SQL> create user oracle
           identified externally;

      SQL> grant create session
           to oracle;

      SQL> select username, password
           from dba_users;

      SQL> exit

      [oracle@ora11gr2 ~]$ sqlplus /
      SQL> show user

   [2] SYSDBA 유저

    - 운영체제 인증

      [oracle@ora11gr2 ~]$ more /etc/group
      [oracle@ora11gr2 ~]$ more /etc/passwd

      --> OS 인증을 사용하는 유저 추가

      [oracle@ora11gr2 ~]$ su -
      Password:

      [root@ora11gr2 ~]# useradd -g oinstall -G dba chan
      [root@ora11gr2 ~]# passwd chan

    	Changing password for user chan.
  	New UNIX password:                   <-- chan 입력
  	Retype new UNIX password:            <-- chan 입력

      [root@ora11gr2 ~]# su - chan
      [chan@ora11gr2 ~]$ vi .bash_profile

  	ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
  	ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1; export ORACLE_HOME
  	ORACLE_SID=prod; export ORACLE_SID
  	PATH=/usr/sbin:$PATH; export PATH
  	PATH=$ORACLE_HOME/bin:$PATH; export PATH
  	NLS_LANG=korean_korea.ko16mswin949; export NLS_LANG

      [chan@ora11gr2 ~]$ . .bash_profile
      [chan@ora11gr2 ~]$ env|grep ORA
      [chan@ora11gr2 ~]$ whoami

  	chan

      [chan@ora11gr2 ~]$ sqlplus / as sysdba
      SQL> startup force
      SQL> select instance_name, status from v$instance;
      SQL> shutdown abort
      SQL> exit

      [chan@ora11gr2 ~]$ exit
      [root@ora11gr2 ~]$ exit

    - Password file 인증

      [oracle@ora11gr2 ~]$ export ORACLE_SID=prod
      [oracle@ora11gr2 ~]$ rm $ORACLE_HOME/dbs/orapwprod
      [oracle@ora11gr2 ~]$ orapwd file=$ORACLE_HOME/dbs/orapwprod password=murisu entries=5

      OS] sqlplus sys/murisu@ora11gr2.gsedu.com:1521/prod as sysdba
      SQL> startup force

      SQL> grant sysdba to orange;
      SQL> select * from v$pwfile_users;
      SQL> shutdown abort
      SQL> exit

      OS] sqlplus orange/orange@ora11gr2.gsedu.com:1521/prod

  	에러 : ORA-01034: ORACLE not available

      OS] sqlplus orange/orange@ora11gr2.gsedu.com:1521/prod as sysdba

      SQL> startup force
      SQL> show user

  	USER은 "SYS"입니다

      SQL> connect orange/orange@ora11gr2.gsedu.com:1521/prod
      SQL> show user

  	USER is "ORANGE"

      SQL> connect sys/murisu@ora11gr2.gsedu.com:1521/prod as sysdba
      SQL> revoke sysdba from orange;
      SQL> exit

       -- EM에서 접속 확인

  	User Name  : sys
  	Password   : murisu
  	Connect As : sysdba

  ---------------------------------
   Profile
  ---------------------------------

    [oracle@ora11gr2 ~]$ export ORACLE_SID=prod
    [oracle@ora11gr2 ~]$ sqlplus / as sysdba
    SQL> set linesize 300
    SQL> set pagesize 100
    SQL> select * from dba_profiles;
    SQL> ed ?/rdbms/admin/utlpwdmg.sql

  	-- 파일의 가장 마지막 부분의 아래 내용을 주석처리하세요.
  	-- ALTER PROFILE DEFAULT LIMIT
  	-- PASSWORD_LIFE_TIME 60
  	-- PASSWORD_GRACE_TIME 10
  	-- PASSWORD_REUSE_TIME 1800
  	-- PASSWORD_REUSE_MAX UNLIMITED
  	-- FAILED_LOGIN_ATTEMPTS 3
  	-- PASSWORD_LOCK_TIME 1/1440
  	-- PASSWORD_VERIFY_FUNCTION verify_function;

    SQL> @?/rdbms/admin/utlpwdmg.sql

    -- profile 은 생성하지 않으면 default 로 생성됨

    SQL> create profile dev_prof limit
          /* 자원에 관한것  */
          CPU_PER_SESSION           10000   -- CPU 를 몇초 이상 쓰면 끊어버림
          CPU_PER_CALL              1000    -- CPU 를 몇초 이상 쓰면 명령을 수행하지 않음 세션은 살아 있음
          CONNECT_TIME              600     -- 일을 하든 안하든 끊음
          IDLE_TIME                 60      -- 일을 안하면
          SESSIONS_PER_USER         3       -- 한사람 최대 3개 세션만 가능
          LOGICAL_READS_PER_SESSION 1000
          LOGICAL_READS_PER_CALL    100
          PRIVATE_SGA               1024    -- UGA 는 SGA 안에 .. SGA ...?
          COMPOSITE_LIMIT           default -- 가중치
          -- default 라는 이름의 설정값을 따르겠다.
          /* 암호에 관한것  */
          PASSWORD_LIFE_TIME        60
          PASSWORD_GRACE_TIME       5
          PASSWORD_REUSE_MAX        3        -- 한번쓴 암호를 다시 쓰려면 3번 이후에 다시 쓸 수 있음
          PASSWORD_REUSE_TIME       30
          PASSWORD_VERIFY_FUNCTION  verify_function   -- 너무 쉬운 암호 못쓰게 함 (자동 검증)
          FAILED_LOGIN_ATTEMPTS     3       -- 3번 틀리면 잠김
          PASSWORD_LOCK_TIME        5/1440;

    -- 자원 세팅
    SQL> alter system set resource_limit=true;

    SQL> drop user phi cascade;
    SQL> create user phi
         identified by yun_123
         default tablespace users
         temporary tablespace temp
         quota 10m on users
         quota 10m on app_ts
         profile dev_prof
         account unlock
         PASSWORD EXPIRE;

    SQL> alter user phi profile default;
    SQL> alter user phi identified by bow;
    SQL> alter user phi PASSWORD EXPIRE;

    SQL> alter user phi account lock;
    SQL> alter user phi account unlock;
    SQL> alter user phi quota 20m on users;

      ----------

    SQL> grant connect, resource     --> 비권장이며 필요할 경우 Role을 만들어서 사용하세요.
         to phi;

    SQL> create role dev_role;

    SQL> grant CREATE TABLE, CREATE OPERATOR, CREATE TYPE, CREATE CLUSTER, CREATE TRIGGER,
               CREATE SESSION, CREATE SEQUENCE, CREATE PROCEDURE, CREATE INDEXTYPE
         to dev_role;

    SQL> alter user leehlee quota 10m on users;
    SQL> create table leehlee.t1 (no number) tablespace users;
    SQL> grant select, insert, update, delte
         on leehlee.t1
         to dev_role;

    SQL> grant dev_role
         to phi, james;

    SQL> grant select any table, connect
         to dev_role;

    SQL> conn phi/bow

  	ORA-28001: the password has expired

  	Changing password for phi
  	New password:           <-- tiger 입력
  	Retype new password:    <-- tiger 입력

      ----------

    SQL> conn system/oracle
    SQL> grant dba to phi with admin option;

    SQL> conn phi/tiger
    SQL> revoke dba from system;
    SQL> revoke "AQ_ADMINISTRATOR_ROLE" from system;
    SQL> revoke "MGMT_USER" from "SYSTEM";

    SQL> conn system/oracle

  	ORA-01045: user SYSTEM lacks CREATE SESSION privilege; logon denied

    SQL> conn phi/tiger
    SQL> grant dba to system;
    SQL> grant "AQ_ADMINISTRATOR_ROLE" to system;
    SQL> grant "MGMT_USER" to "SYSTEM";

  # 유저별 할당된 공간 확인

    SQL> set lines 200
    SQL> select * from dba_ts_quotas;

-----

## SYS 계정
  ADMIN OPTION 과 함께 모든 권한가짐
  시작, 종료 및 유지관리
  데이터   딕셔너리 및 AWR(Automatic Workload Repository) 소유

## EM 에서 User 생성
  Password : DB 인증
  External : OS 인증


## user security 권한
  * with admin grant 차이
    주기
      with admin option
      a -> b -> c
      내가 권한을 부여하고 나의 권한도 뺏길 수 있다.
      with grant option
      a -> b -> c
      나의 권한을 뺏을 순없다.
    뺏기
      with admin option
      a -> b -> c
      a 가 b 의 권한을 뺏으면 c 는 유지됨
      with grant option
      a -> b -> c
      a 가 b 의 권한을 뺏으면 c 도 같이 뺏김

  * Grant any object privilege : 자신이 소유하지 않은 객체에 대해서 권한을 부여할 수 있음 DBA 같은 사람들

  * 새로운 Role 을 만들어도 소유 하진 못한다.
    소유의 개념은 내가 만들고 내가 없어졌을 때 같이 삭제될때 성립함.
    DBA 는 manage role 의 권한이 있음

  * role 에도 암호를 줄 수 있음
  set role dev_role identirfied by lion;
  identified using <procedure_name> -- 프로그래밍으로 방식으로 보안 유지

  * These functions are created with the
  <oracle_home>/rdbms/admin/utlpwdmg.sql 에서 암호 검증 조건을 변경해주술수 있으나
  default 부분에 적용 될수 있기 때문에 아래부분을 주석처리하고 진행해야 한다.
  In addition to creating VERIFY_FUNCTION, the utlpwdmg script also changes the DEFAULT
  profile with the following ALTER PROFILE command
  11gWS1_sg1.pdf 336 page


  # Multple Block Size
    -- 블럭의 크기를 다양하게 주고 싶을 때
    -- OLTP - 작고 빈번할수 있도록
    -- OLAP - 크고 한번에 많이

    SQL> alter system set db_cache_size=60M;
    SQL> alter system set db_8k_cache_size=4m;
    SQL> create tablespace ts8k datafile '/u01/app/oracle/oradata/prod/ts8k.dbf' size 10m blocksize 8k;
    SQL> select tablespace_name, block_size
         from dba_tablespaces;
    SQL> drop tablespace ts8k including contents and datafiles;

  # ASM + OMF

   모든 Oracle Databse Server 설정을 다음과 같이 한다면...
   (아래 명령은 참고용입니다. 설정하지 마세요.)

     SQL> alter system set db_create_file_dest         = '+DG1';
     SQL> alter system set db_create_online_log_dest_1 = '+DG1';
     SQL> alter system set db_create_online_log_dest_2 = '+DG1';

     SQL> alter system set db_recovery_file_dest_size  = 2G;
     SQL> alter system set db_recovery_file_dest       = '+DG2';


____
