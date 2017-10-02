
대규모의 Server 구조 방식
Data guard
primary DB와 standby DB를 동기화시켜, primary DB가 하드웨어 장애 등의 문제가 생겼을 경우 standby DB로 failover 또는 switchover 시킬 수 있는 시스템 구성을 말한다.
RAC
'오라클 RAC'는 Oracle Real Application Clusters의 약자로서, 2001년 미국 오라클사가 개발한 클러스터링 및 고가용성을 위한 옵션이다.

SQL> 에서 linux cmd 명령어 : ! 붙여서 실행


===========================
 Authentication (인증)
===========================
Authorization 권한관리 User 별로 해야할일
Authentication User ID / PWD 관리 사전에 등록된 그사람인가

1. DB 인증
  일반유저 (scott, hr..)
2. OS 인증
  일반유저
  sysdba 유저
3. password 인증
  sysdba 유저
4. 기타

# OS 인증
  sys/oracle, system/oracle
  는 신과 같은 권력을 가짐 But startup 은 못함
  startup 이 되어 있지 않으면 sqlplus 접속 시도 시 not available 이 뜸
  그래서 os 인증과 pwd 인증을 만들어 둠
  etc/passwd 파일
  etc/group 파일

  닉스(?)계열의 최고user 는 root
  oinstall 그룹이 기본 그룹

  sqlplus / as sysdba
  as sysdba : os 인증을 해라

  oracle/oracle 사용자가
  oinstall 그룹에 속해 있는지 확인해봐라

  idle 인스턴스에 접속됨

# pwd 인증
 sqlplus u/p@ip:port/DB
  DB 인스턴스가 startup 됐을 때만 가능
 sqlplus u/p@ip:port/DB as sysdba
  as sysdba 붙일 수 있는데 OS 인증을 할 수 없다.
  OS에 있는 DB 말고 밖의 별도의 파일 orapw(인스턴스이름) 파일 password=memam entries=5
  기본user 인 sys/memam 가 생긴다.
  앞으로 4명 더 들어 갈 수 있음
  sqlplus sys/nemam@ip:port/DB as sysdba
  orapwprod 파일이 삭제되도 다 접속은 됨 as sysdba 접속만 안됨
  orapwprod 파일에 user 를 추가해서 entries 에 잠깐 sysdba 권한을 부여했다가 뻇을 수 있음


[1] Database 일반 유저

- Database 인증

  [oracle@ora11gr2 ~]$ export ORACLE_SID=prod
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> startup force

  SQL> create user orange
       identified by orange;

  SQL> grant create session
       to orange;

  SQL> !ps
  PID TTY          TIME CMD
  5533 pts/1    00:00:00 bash
  6173 pts/1    00:00:00 sqlplus
  6176 pts/1    00:00:00 ps

  -- 6173 은 클라이언트 프로세스
  -- 6174 은 6173 를 부모로 가진 서버 프로세스
  SQL> !ps -ef | grep 6173
  oracle    6173  5533  0 09:37 pts/1    00:00:00 sqlplus
  oracle    6174  6173  0 09:37 ?        00:00:00 oracleprod (DESCRIPTION=(LOCAL=YES)(ADDRESS=(PROTOCOL=beq))) <<<<서버프로세스
  oracle    6177  6173  0 09:37 pts/1    00:00:00 /bin/bash -c ps -ef | grep 6173
  oracle    6179  6177  0 09:37 pts/1    00:00:00 grep 6173

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
  -- show parameter (파라미터명)
  SQL> show parameter prefix

	NAME                                 TYPE        VALUE
	------------------------------------ ----------- ------------------------------
	os_authent_prefix                    string      ops$

  SQL> create user ops$oracle
       identified externally;
       -- by 가 들어가지 않는다.
       -- 그 건물에만 들어가면 어디든지 갈 수 있다.

  SQL> grant create session
       to ops$oracle;

  SQL> exit

  -- 그냥 / 만으로도 접속이 가능하다
  [oracle@ora11gr2 ~]$ sqlplus /
  SQL> show user

   USER is "OPS$ORACLE"

  SQL> conn / as sysdba
  SQL> drop user ops$oracle;
  -- OPS$ 를 지움

  SQL> shutdown abort
  SQL> create spfile from pfile;
  SQL> startup force

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

   -- oinstall 그룹에 chan 이라는 user 를 넣음
   [root@ora11gr2 ~]# useradd -g oinstall -G dba chan
   [root@ora11gr2 ~]# passwd chan

   Changing password for user chan.
   New UNIX password:                   <-- chan 입력
   Retype new UNIX password:            <-- chan 입력

   [root@ora11gr2 ~]# su - chan
   [chan@ora11gr2 ~]$ vi .bash_profile
   -- chan 의 홈디렉토리
   -- 만든적이 없는 것들의 정보를 채워넣음 (vi 편집 시 x 누르면 tab 사라짐)

   ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
   ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1; export ORACLE_HOME
   ORACLE_SID=prod; export ORACLE_SID
   PATH=/usr/sbin:$PATH; export PATH
   PATH=$ORACLE_HOME/bin:$PATH; export PATH
   -- NLS_LANG=korean_korea.ko16mswin949; export NLS_LANG

   [chan@ora11gr2 ~]$ . .bash_profile
   -- 다시 실행함

   [chan@ora11gr2 ~]$ env|grep ORA
   [chan@ora11gr2 ~]$ whoami

   chan

   [chan@ora11gr2 ~]$ sqlplus / as sysdba
   -- OS 인증이 됨
   -- / : oracle/oracle 사용자 계정이 생략되어 있으나
   -- as sysdba 로 접속하면 어짜피 인증하지 않는다. oinstall 그룹에 속해있는 user 만 가능 (root 유저만 가능)

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

   -- 하기 전에 SQL> shutdown abort 시키고 접속함

   >> Windows에서 테스트

   C:/Users/student> sqlplus sys/murisu@192.168.56.101:1521/prod as sysdba

   SQL> startup force

   -- orange 에 sysdba 권한을 줌
   SQL> grant sysdba to orange;
   -- passward 파일에 등록된 user 보기
   SQL> select * from v$pwfile_users;

   SQL> shutdown abort
   SQL> exit

   C:/Users/student> sqlplus orange/orange@192.168.56.101:1521/prod
   -- DB 인증 prod 인스턴스가 startup 이 되어 있지 않아서 에러남
   에러 : ORA-01034: ORACLE not available

   --OS] sqlplus orange/orange@ora11gr2.gsedu.com:1521/prod as sysdba
   C:/Users/student> sqlplus orange/orange@192.168.56.101:1521/prod as sysdba

   SQL> startup force
   SQL> show user

   USER은 "SYS"입니다
   -- sys 접속됨 orange 테이블을 볼수 없다. 다시 DB 인증으로 orange user로 접속
   -- SQL> connect orange/orange@ora11gr2.gsedu.com:1521/prod
   SQL> connect orange/orange@192.168.56.101:1521/prod
   SQL> show user

   USER is "ORANGE"

   -- SQL> connect sys/murisu@ora11gr2.gsedu.com:1521/prod as sysdba
   SQL> connect sys/murisu@192.168.56.101:1521/prod as sysdba
   -- orange 권한을 뻇음
   SQL> revoke sysdba from orange;
   SQL> select * from v$pwfile_users;
   SQL> exit

    -- EM에서 접속 확인

 User Name  : sys
 Password   : murisu
 Connect As : sysdba


sqldeveloper 에서는 sys 보다 system 으로 붙어서 작업을 하는것이 관리자의 작업을 수행 할 수 있다.


===========================
 일반 관리
===========================

# Control file 추가
# Redo log fiel 추가
# Datafile 추가
# 파일 위치 이동
# 파일 삭제

### Control file 추가

  [oracle@ora11gr2 ~]$ export ORACLE_SID=prod
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba
  SQL> shutdown abort
  SQL> create spfile from pfile;
  SQL> startup force
  SQL> show parameter spfile

  NAME                                 TYPE        VALUE
  ------------------------------------ ----------- ------------------------------
  spfile                               string      /u01/app/oracle/product/11.2.0
                                                   /dbhome_1/dbs/spfileprod.ora

  SQL> set linesize 300
  SQL> set pagesize 100
  SQL> select * from dba_profiles;
  SQL> select name from v$controlfile;

  SQL> alter system set control_files =
        '/u01/app/oracle/oradata/prod/control01.ctl',
        '/u01/app/oracle/oradata/prod/control02.ctl',
        '/u01/app/oracle/oradata/prod/control03.ctl'
        scope=spfile;

* scope 옵션: 파라미터 파일에 적용되고 반영되지는 않는다. 정상종료 후 진행해야됨

  SQL> shutdown immediate

  SQL> !ls -l /u01/app/oracle/oradata/prod

  SQL> !cp /u01/app/oracle/oradata/prod/control02.ctl /u01/app/oracle/oradata/prod/control03.ctl

  SQL> startup

  SQL> select name from v$controlfile;

### Redo log file 추가

  SQL> alter session set nls_date_format = 'YYYY\MM\DD HH24:MI:SS';

  SQL> select group#, sequence#, members, status, first_time
       from v$log;
  SQL> save log.sql

* 전에 2 그룹에 2개씩 만들어 넣었음
* sequence 각 그룹에 write 된 순서 1,2 -> 3,4 ....
* sequence 명은 아카이빙 될때 sequence 번호를 사용하여 작명됨 ...5...
* status
  current 현재 쓰고 있는것
  unused 한번도 안쓴

* 새로운 그룹만듬
3 번째 그룹 2개의 rego log file
4 번째 그룹 1개의 rego log file
4 번쨰 그룹 1개의 member 는 사이즈 다르게 생생해줌


  SQL> col member format a50
  SQL> select group#, member from v$logfile;

        GROUP# MEMBER
    ---------- --------------------------------------------------
             1 /u01/app/oracle/oradata/prod/redo01_a.log
             1 /u01/app/oracle/oradata/prod/redo01_b.log
             2 /u01/app/oracle/oradata/prod/redo02_a.log
             2 /u01/app/oracle/oradata/prod/redo02_b.log

  SQL> alter database add logfile
         ('/u01/app/oracle/oradata/prod/redo03_a.log',
          '/u01/app/oracle/oradata/prod/redo03_b.log')
       size 20m;

  SQL> alter database add logfile
         ('/u01/app/oracle/oradata/prod/redo04_a.log')
       size 20m;

  SQL> alter database add logfile member
         '/u01/app/oracle/oradata/prod/redo04_b.log'
       to group 4;

  SQL> @log.sql

      GROUP#  SEQUENCE#    MEMBERS STATUS           FIRST_TIME
  ---------- ---------- ---------- ---------------- -------------------
           1         45          2 CURRENT          2017\05\18 14:24:43
           2         44          2 INACTIVE         2017\05\18 13:12:09
           3          0          2 UNUSED
           4          0          2 UNUSED

* 수동으로 로그 스위치 시키기
  SQL> alter system switch logfile;
  SQL> @log

      GROUP#  SEQUENCE#    MEMBERS STATUS           FIRST_TIME
  ---------- ---------- ---------- ---------------- -------------------
           1         45          2 ACTIVE           2017\05\18 14:24:43
           2         44          2 INACTIVE         2017\05\18 13:12:09
           3         46          2 CURRENT          2017\05\18 14:39:27
           4          0          2 UNUSED

  SQL> alter system switch logfile;
  SQL> @log


### Datafile 추가

  SQL> select name from v$datafile
      union all
      select name from v$tempfile;

  SQL> create tablespace dhts
       datafile '/u01/app/oracle/oradata/prod/dhts01.dbf' size 10m,
                '/u01/app/oracle/oradata/prod/dhts02.dbf' size 10m
                autoextend on next 10m maxsize 100m;

* autoextend on next 10m maxsize 200M
10m 가 되고나면 계속 늘어나게 만듬

  SQL> create tablespace hnts
     datafile '/u01/app/oracle/oradata/prod/hnts01.dbf' size 10m;


* 10m 가 바닥나면 나중에 공간을 추가 하고 싶을때
  - 속성변경
  SQL> alter database datafile
         '/u01/app/oracle/oradata/prod/hnts01.dbf'
       autoextend on next 10m maxsize 100m;

  - add 해줄수 있음
  SQL> alter tablespace hnts
       add datafile '/u01/app/oracle/oradata/prod/hnts02.dbf' size 10m;

  SQL> select tablespace_name, file_name
    from dba_data_files;

  SQL> save ts.sql

  SQL> @ts.sql


dba_tablespaces..


### 파일 위치 이동

>> Control file 이동
  !) 항상 정상 종료가 되어 있는 상태에서 진행해야 한다.
    -> 이동하는 상황에 써지면 안되기 때문에
  SQL> alter system set control_files =
         '/u01/app/oracle/oradata/prod/control01.ctl',
         '/u01/app/oracle/oradata/prod/control02.ctl',
         '/u01/app/oracle/oradata/mola/control03.ctl'
       scope=spfile;

  SQL> !mkdir /u01/app/oracle/oradata/mola

  SQL> shutdown immediate

  SQL> !mv /u01/app/oracle/oradata/prod/control03.ctl /u01/app/oracle/oradata/mola

  SQL> startup

  SQL> select name from v$controlfile;

    NAME
    ----------------------------------------------------------------------------
    /u01/app/oracle/oradata/prod/control01.ctl
    /u01/app/oracle/oradata/prod/control02.ctl
    /u01/app/oracle/oradata/mola/control03.ctl


>> redo log file 이동
* control 파일이 들어 있는 디스크가 오류 날수 있기 때문에
  백업은 각 다른 디스크에 넣어 놓는 것이 좋다.
    prod:disk1 mola:disk2
    G1 (a, b)
    G2 (a, b)
    G3 (a, b)
    G4 (a, b)
* redo log file 그룹의 m1 은 disk1 에 m2 들은 disk2 에 다르게 둠

  SQL> shutdown immediate

  SQL> !ls -l /u01/app/oracle/oradata/prod/*b.log
*/
  SQL> !mv /u01/app/oracle/oradata/prod/*b.log /u01/app/oracle/oradata/mola
*/
  SQL> !ls -l /u01/app/oracle/oradata/prod/*a.log
  SQL> !ls -l /u01/app/oracle/oradata/mola/*b.log
*/
* control 파일 변경 mount 까지만 진행 컨트롤 파일을 읽은 상태에서 rename

  SQL> startup mount

  SQL> alter database rename file
         '/u01/app/oracle/oradata/prod/redo01_b.log' to
         '/u01/app/oracle/oradata/mola/redo01_b.log';

  SQL> alter database rename file
         '/u01/app/oracle/oradata/prod/redo02_b.log',
         '/u01/app/oracle/oradata/prod/redo03_b.log',
         '/u01/app/oracle/oradata/prod/redo04_b.log'
          to
         '/u01/app/oracle/oradata/mola/redo02_b.log',
         '/u01/app/oracle/oradata/mola/redo03_b.log',
         '/u01/app/oracle/oradata/mola/redo04_b.log';

  SQL> alter database open;

  SQL> select group#, member from v$logfile;

      GROUP# MEMBER
  ---------- --------------------------------------------------
           1 /u01/app/oracle/oradata/prod/redo01_a.log
           1 /u01/app/oracle/oradata/mola/redo01_b.log
           2 /u01/app/oracle/oradata/prod/redo02_a.log
           2 /u01/app/oracle/oradata/mola/redo02_b.log
           3 /u01/app/oracle/oradata/prod/redo03_a.log
           3 /u01/app/oracle/oradata/mola/redo03_b.log
           4 /u01/app/oracle/oradata/prod/redo04_a.log
           4 /u01/app/oracle/oradata/mola/redo04_b.log


>> Datafile 이동

* Datafile 은 control, redo 와 다르게 shutdown 하지 않고 offline 시켜 놓은 상태에서 진행
  SQL> alter tablespace hnts offline;

  SQL> !mv /u01/app/oracle/oradata/prod/hnts*.dbf  /u01/app/oracle/oradata/mola

  SQL> alter database rename file
         '/u01/app/oracle/oradata/prod/hnts01.dbf',
         '/u01/app/oracle/oradata/prod/hnts02.dbf'
         to
         '/u01/app/oracle/oradata/mola/hnts01.dbf',
         '/u01/app/oracle/oradata/mola/hnts02.dbf';

  SQL> alter tablespace hnts online;



### 파일 삭제
--> 어려움.... 다음에

===========================
 백업 및 복구
===========================

## Database 모드 수정

* Noarchive log <-> Archive log
* show parameter spfile 이 있어야됨

  [prod:~]$ . oraenv
  ORACLE_SID = [prod] ? prod

  [prod:~]$ sqlplus / as sysdba

  SQL> startup

  SQL> archive log list

       Database log mode    No Archive Mode
       Automatic archival   Disabled


* 아카이브드 로그가 생기는 위치 디렉토리 만들어줌

  SQL> !mkdir /u01/app/oracle/oradata/prod_arch1
  SQL> !mkdir /u01/app/oracle/oradata/prod_arch2

  SQL> alter system set log_archive_dest_1 =    'location=/u01/app/oracle/oradata/prod_arch1/';
  SQL> alter system set log_archive_dest_2 = 'location=/u01/app/oracle/oradata/prod_arch2/';

* 반듯이 정상종료 후 진행
* mount 상태에서 모드 변경

  SQL> shutdown immediate
  SQL> startup mount
  SQL> alter database archivelog;

* 아카이브 프로세스가 여러개 떠있음
logwriter 가 아카이브 파일에 쓰는데 여러개가 떠있어야 빠르게 백업해 둘수 있다.


  SQL> archive log list

       Database log mode    Archive Mode
       Automatic archival   Enabled

  SQL> alter database open;

  SQL> !ps -ef|grep arc

       oracle   16770     1  0 15:23 ?        00:00:00 ora_arc0_prod
       oracle   16772     1  0 15:23 ?        00:00:00 ora_arc1_prod
       oracle   16774     1  0 15:23 ?        00:00:00 ora_arc2_prod
       oracle   16776     1  0 15:23 ?        00:00:00 ora_arc3_prod

 SQL> !ls /u01/app/oracle/oradata/prod_arch*
   /u01/app/oracle/oradata/prod_arch1:

   /u01/app/oracle/oradata/prod_arch2:

* archived log file 은 안생겨있다.
  log switch 가 되어야 생김
  강제로 만들어줌

  SQL> alter system switch logfile;
  SQL> alter system switch logfile;

  SQL> !ls /u01/app/oracle/oradata/prod_arch*
    /u01/app/oracle/oradata/prod_arch1:
    1_47_944227692.dbf

    /u01/app/oracle/oradata/prod_arch2:
    1_47_944227692.dbf

## Database 백업

* 장애 시나리오) (복원&복구)
  장애발생) 백업 -> 변화 -> logfile switch 됨 -> 파일이 깨짐
  복구)
    -> open 이 되지 않는다.
    -> 장애난 파일을 offline 시키고 open 시킴
    -> datafile level 로 복구 시키기
    -> 파일에 문제가 있으면 offline 이 되지 않기 때문에 강제로 시킴
    -> 백업해둔 dontouch 파일을 다시 복원 시킴
    -> recover 명령으로 복원된 데이터의 header 파일로 어느 redo log file 을 가져올지 물음 : auto
    -> 다시 online 으로 바꿈
    -> 최근까지의 변경사항이 반영됨

# Database 백업

  SQL> !mkdir /u01/app/oracle/oradata/prod_dontouch

  SQL> shutdown immediate

  SQL> !cp /u01/app/oracle/oradata/prod/* /u01/app/oracle/oradata/prod_dontouch
  SQL> !cp /u01/app/oracle/oradata/mola/* /u01/app/oracle/oradata/prod_dontouch
*/
# 일상적인 작업

  SQL> startup

  SQL> select * from v$tablespace;

  SQL> alter user orange
       quota 10m on hnts;

  SQL> create table orange.t1
       tablespace hnts
       as
       select '1000' no, 'Lemon' name
       from dual;

  SQL> alter system switch logfile;
  SQL> /
  SQL> /
  SQL> /
  SQL> /
  SQL> /
  SQL> /

# 장애 발생

  SQL> !rm /u01/app/oracle/oradata/mola/hnts01.dbf
  SQL> !rm /u01/app/oracle/oradata/mola/hnts02.dbf
      !ls /u01/app/oracle/oradata/mola/*
*/
  SQL> startup force

       ORA-01157: cannot identify/lock data file 6 - see DBWR trace file
       ORA-01110: data file 6: '/u01/app/oracle/oradata/mola/hnts01.dbf'

  SQL> alter database datafile 6 offline;

  SQL> alter database open;

       ORA-01157: cannot identify/lock data file 7 - see DBWR trace file
       ORA-01110: data file 7: '/u01/app/oracle/oradata/mola/hnts02.dbf'

  SQL> alter database datafile 7 offline;

  SQL> alter database open;

# 복구

  SQL> alter tablespace hnts offline immediate;

  SQL> !cp /u01/app/oracle/oradata/prod_dontouch/hnts01.dbf /u01/app/oracle/oradata/mola
  SQL> !cp /u01/app/oracle/oradata/prod_dontouch/hnts02.dbf /u01/app/oracle/oradata/mola

  SQL> recover datafile 6;

       Specify log: {<RET>=suggested | filename | AUTO | CANCEL}
       auto    << auto 입력

  SQL> recover datafile 7;

       Specify log: {<RET>=suggested | filename | AUTO | CANCEL}
       auto    << auto 입력

  SQL> alter tablespace hnts online;

  SQL> select * from orange.t1;


============================
11g
============================
11g : 그리드 (저장영역그리드 + DB 그리드 + 응용프로그램 그리드 + Grid Control)


# Utility Computing!
 공공서비스 대규모의 Computing

Grid Cloud

* Grid Computing
  - Pooling         : ASM RAC WAS
    작은것 어려개로 큰것 처럼 사용
  - Virtualization  : ASM RAC WAS EMGridControl
    디스크의 위치를 가상으로 지정하여 쉽게 교체 할수 있도록 함
    (we made DATA,FRM.. )
  - Provisioning    : ASM RAC WAS
    alter disk group data...
    사용하여 리소스를 DATA -> FRM 으로 반대로 이동이 가능

# 1-4
  - Host 환경
    Putty 등으로 접속
  - CS 환경
    sqldeveloper, sqlplus 등으로 접속
  - nTier 환경
    WAS 등의 Server 를 통해 접속

# 1-21
'<<프로세스 구조>>'
  I.I 서버프로세스는 서버가 있는 곳에서 뜸
    서버프로세스에서 PGA 사용
    PGA, SGA 는 같은 기계의 메모리
    SGA 는 같이 쓰는 메모리
    PGA 는 혼자 쓰는 메모리
    ipc : 두개의 process 가 데이터를 공유 공유메모리


  I.I 인스턴스의 모양을 지배하는게 파라미터 initprod, spfileprod ..
    SGA 와 PGA 의 공간 배분
      OLP 성 어플리케이션이 많아 server process 를 거치지 않으면 8:2
        SGA_MAX_SIZE=6G   //변경 불가능 최대 허용치 STATIC
        SGA_TARGET=6G     //실제 사용량 수시로 변경 가능
        PGA_AGGREGATE_TARGET=2G (쓸때마다 할당받고 반납하고)
      OLAP 분석용 어플리케이션의 접속이 많으면 5:5
        PGA 에 통계 SORT AREA에 데이터를 저장해놓고 모자르면 temp disk 에 넣어서 읽고 쓰고 함
        DISK 를 사용하면 전체적으로 느려지기 때문에 PGA 를 크게 할당함
      10G 부터는 자동으로 할당 가능
        MEMORY_MAX_TARGET   //확보
        MEMORY_TARGET       //실제 사용량 수시로 변경

    SHOW PARAMETER SGA/PGA
    SHOW PARAMETER MEMORY


  I.I Database 에서는 Spread (파일을 퍼트리는 것) 가 중요
  I.I SGA 는 Right Size 가 중요
    여러명이 공유해서 사용하는데 뒤져야 하는 공간이 늘어나기 때문에 무조건 늘린다고 좋은것이 아니다.
    PGA 는 크면 좋음 달라고 하는것 다 줌 (?) 혼자씀

  I.I Shared Pool 에 파싱한 문장들이 들어있음 캐싱 v$sql
    데이터베이스 버퍼캐시 에 최근에 질의한 table 정보 캐싱
      많은 사람이 요청시 줄을 세워서 Shared Pool 을 사용하도록 함

  I.I ASMM
    SGA, PGA
    SGA_MAX_SIZE
    PGA_AGGREGATE_TARGET
  I.I AMM
    AUTO 자동관리
    MEMORY_MAX_TARGET


__
