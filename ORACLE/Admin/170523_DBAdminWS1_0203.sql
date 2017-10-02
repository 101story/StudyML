

============================================
 2장 Installing your Oracle Software
============================================

Welcome to The Oracle FAQ
http://www.orafaq.com/

## Database Area Flash|Fast Recovery Area
  << Oracle Managed File 과 관련이 있음
* Database Area : db_create 파라미터가 가리키는 위치
* Recovery Area : db_recovery 파라미터가 가리키는 위치

SQL> alter system set db_create_file_dest='..../mola'
데이터파일
SQL> show parameter db_create
log_dest_1
log_dest_2
컨트롤,이두로그파일
2개다 value 값을 주면 백업되어 다른한곳에 생김
위치를 지정해 주지 않으면 데이터파일 위치에 전부 생김
SQL> show parameter db_recovery

create tablespace 하면

redo
  UMF user managed file
  사용자가 위치를 지정하여 파일이 생성된 것
o1_mf_..
  OMF oracle managed file
  mola 밑에 db 밑에 datafile 에 파일이 들어 가 있음
  오라클이 자동으로 만들 파일

alter database add logfile;

* OMF 사용: Area 를 잡아줌! CMD 할때 위치 지정을 안함!

Area 를 잡아 주지 않으면 UMF 방식만 가능하다. 반듯이 datafile 과 위치를 지정해 줘야 한다.
Area 를 잡으면 위치를 지정하지 않아도 UMF, OMF 가 된다.
OMF 를 하고 싶으면 Area 잡아주고 자동으로 생기게함
  drop tablespace dbname 를 하면 파일도 동시에 사라짐
  alter database drop logfile group 5 하면 파일도 사라짐
OMF 가 아닌 UMF 경우
  메타데이타만 없어지고 os 파일이 남아 있음 os 의 rm 으로 지워야 됨 including contents and datafiles 을 해야 지워짐
  redo log 파일은 직접 해당 위치를 찾아서 파일을 지워야 한다.



OMF 백업결과를
db_recovery_file_dest_size
는 원래 크기가 중요하진 않다.(?)
dest 위치 잡아 주기

아카이브 로그 모드
백업
Oracle Recovery Manager (RMAN)
rman target /
backup database;

dml ddl 이 이뤄지고 있어도 백업이 됨
.bkp 압축 파일이 생김
backupset 폴더 밑에

* 할당 방식
  > BLOCK
    - ASSM (권장)   - 자동 세그먼트 공간 관리(ASSM, Automatic Segment Space Management)
    - MSSM          - 수동 세그먼트 관리(MSSM, Manual Segment Space Management)
  > EXTENT
    - LMT (권장)    - CREATE TABLESPACE DEFAULT
    - DMT           - 옵션지정
  > FILE
    - OMF (권장)    - AREA 지정
    - UMF
  > STORAGE
    - ASM (권장)    - GI 설치 DISK 그룹 설정 ..
    - FILE SYSTEM

* BACKUP AND RECOVERY 전략
  (전) DISK TO TAPE
  (현)-> DISK(Database Area) TO
        DISK(3일이 안지난데이터 Recovery Area) TO TAPE


* 백업복구 구조 단계
  환경)
  인스턴스       orcl/prod, asm
  설치소프트웨어 DBMS/GI/OS
  DISK          DATA, FRA
  TAPE
  1. orcl 인스턴스에
    db_create, db_recovery 설정
  2. orcl 인스턴스의 sqlplus 에서 create tablespace 또는 alter data add logfile
  3. orcl 인스턴스의 rman 을 이용 backup database (또는 tablespace, datafile)
    DISK DATA -> FRM 에 backup database 를 함
  4. orcl 인스턴스의 rman 을 이용 backup Recovery Area
    DISK FRM -> TAPE 에 backup Recovery Area 를 함

## 실습
# Database Area vs (Flash|Fast) Recovery Area  >>  Oracle Managed File

  [orcl:~]$ . oraenv
  ORACLE_SID = [orcl] ? prod

  [prod:~]$ sqlplus / as sysdba

  SQL> alter system set db_create_file_dest         = '/u01/app/oracle/oradata/mola/';
  SQL> alter system set db_create_online_log_dest_1 = '/u01/app/oracle/oradata/mola/';
  SQL> alter system set db_create_online_log_dest_2 = '/u01/app/oracle/oradata/mola/';

  SQL> show parameter db_create

  NAME                                 TYPE        VALUE
  ------------------------------------ ----------- ------------------------------
  db_create_file_dest                  string      /u01/app/oracle/oradata/mola/
  db_create_online_log_dest_1          string      /u01/app/oracle/oradata/mola/
  db_create_online_log_dest_2          string      /u01/app/oracle/oradata/mola/
  db_create_online_log_dest_3          string
  db_create_online_log_dest_4          string
  db_create_online_log_dest_5          string

  SQL> create tablespace hjts;
  SQL> alter tablespace hjts add datafile size 10m;

  NAME
  ----------------------------------------------------------------------
  ...
  /u01/app/oracle/oradata/mola/hnts01.dbf                                 << UMF (User Managed File)
  /u01/app/oracle/oradata/mola/hnts02.dbf                                 << UMF
  /u01/app/oracle/oradata/mola/PROD/datafile/o1_mf_hjts_dl72wnvr_.dbf     << OMF (Oracle Managed File)
  /u01/app/oracle/oradata/mola/PROD/datafile/o1_mf_hjts_dl72xnfc_.dbf     << OMF

  SQL> drop tablespace hjts;

  SQL> alter database add logfile;
  SQL> select group#, member from v$logfile;

      GROUP# MEMBER
  ---------- --------------------------------------------------------------------
         ... ...
           4 /u01/app/oracle/oradata/prod/redo04_a.log                          << UMF
           4 /u01/app/oracle/oradata/mola/redo04_b.log                          << UMF
           5 /u01/app/oracle/oradata/mola/PROD/onlinelog/o1_mf_5_dl731pqf_.log  << OMF
           5 /u01/app/oracle/oradata/mola/PROD/onlinelog/o1_mf_5_dl731ptr_.log  << OMF

  SQL> alter database drop logfile group 5;

  SQL> alter system set db_recovery_file_dest_size = 4G;
  SQL> alter system set db_recovery_file_dest = '/u01/app/oracle/oradata/prod_dontouch/';

  SQL> show parameter db_recovery

  NAME                                 TYPE        VALUE
  ------------------------------------ ----------- ------------------------------
  db_recovery_file_dest                string      /u01/app/oracle/oradata/prod_dontouch/
  db_recovery_file_dest_size           big integer 4G

  SQL> archive log list
  Database log mode              Archive Mode
  Automatic archival             Enabled

  SQL> exit

  [prod:~]$ rman target /

  RMAN> backup database;

    Starting backup at 23-MAY-17
    using target database control file instead of recovery catalog
    allocated channel: ORA_DISK_1
    ....
    input datafile file number=00001 name=/u01/app/oracle/oradata/prod/system01.dbf
    input datafile file number=00002 name=/u01/app/oracle/oradata/prod/sysaux01.dbf
    input datafile file number=00003 name=/u01/app/oracle/oradata/prod/undotbs01.dbf
    input datafile file number=00004 name=/u01/app/oracle/oradata/prod/dhts01.dbf
    input datafile file number=00005 name=/u01/app/oracle/oradata/prod/dhts02.dbf
    input datafile file number=00006 name=/u01/app/oracle/oradata/mola/hnts01.dbf
    input datafile file number=00007 name=/u01/app/oracle/oradata/mola/hnts02.dbf
    ....
    channel ORA_DISK_1: backup set complete, elapsed time: 00:00:02
    Finished backup at 23-MAY-17

  RMAN> list backup;

    List of Backup Sets
    ===================
    BS Key  Type LV Size       Device Type Elapsed Time Completion Time
    ------- ---- -- ---------- ----------- ------------ ---------------
    1       Full    193.51M    DISK        00:00:21     23-MAY-17
            BP Key: 1   Status: AVAILABLE  Compressed: NO  Tag: TAG20170523T160853
            Piece Name: /u01/app/oracle/oradata/prod_dontouch/PROD/backupset/2017_05_23/o1_mf_nnndf_TAG20170523T160853_dl7r05w9_.bkp
      List of Datafiles in backup set 1
      File LV Type Ckp SCN    Ckp Time  Name
      ---- -- ---- ---------- --------- ----
      1       Full 507754     23-MAY-17 /u01/app/oracle/oradata/prod/system01.dbf
      2       Full 507754     23-MAY-17 /u01/app/oracle/oradata/prod/sysaux01.dbf
      3       Full 507754     23-MAY-17 /u01/app/oracle/oradata/prod/undotbs01.dbf
      4       Full 507754     23-MAY-17 /u01/app/oracle/oradata/prod/dhts01.dbf
      5       Full 507754     23-MAY-17 /u01/app/oracle/oradata/prod/dhts02.dbf
      6       Full 507754     23-MAY-17 /u01/app/oracle/oradata/mola/hnts01.dbf
      7       Full 507754     23-MAY-17 /u01/app/oracle/oradata/mola/hnts02.dbf

    BS Key  Type LV Size       Device Type Elapsed Time Completion Time
    ------- ---- -- ---------- ----------- ------------ ---------------
    2       Full    7.55M      DISK        00:00:04     23-MAY-17
            BP Key: 2   Status: AVAILABLE  Compressed: NO  Tag: TAG20170523T160853
            Piece Name: /u01/app/oracle/oradata/prod_dontouch/PROD/backupset/2017_05_23/o1_mf_ncsnf_TAG20170523T160853_dl7r12x7_.bkp
      SPFILE Included: Modification time: 23-MAY-17
      SPFILE db_unique_name: PROD
      Control File Included: Ckp SCN: 507770       Ckp time: 23-MAY-17

  RMAN> exit

  [prod:~]$


============================================
 3장 Creating an Oracle Database Using DBCA
============================================

* Databases 종류 : OLTP(Online transaction processing), DW(조회, 질의..), 기타

* DB 설치할때 거의 바꿀 수 없는 것 : Block Size (절대X), Character Set (바꾸기힘듬)

  Character Set scanner 변경할때 손상될수 있는 데이터 확인

  잘모르겠으면
  shared_pool_size 은 절반
  Character set 은 unicode

  unicode 한글 3 byte 주로 한글이 들어가면 용량을 많이 잡아먹음

* 인코딩 정보
  레지스트 NLS_LANG 에서 인코딩 정보를 정함
  echo $NLS_LANG
  NLS_LANG=랭귀지_테레토리.인코딩스킴
  export NLS_LANG=american_japan.ko16mswin949


> select * from v$nls_valid_values;


service name
sid
  -> DB 가 많지 않다면 동일하게 하는 것이 편하다.

## instance_name VS service_names

  SQL> show parameter name

    NAME                                 TYPE        VALUE
    ------------------------------------ ----------- ------------------------------
    db_file_name_convert                 string
    db_name                              string      orcl
    db_unique_name                       string      orcl
    global_names                         boolean     FALSE
    instance_name                        string      orcl
    lock_name_space                      string
    log_file_name_convert                string
    service_names                        string      orcl


alter system set service_names ='prod, abc.co.kr, haha';

파라메터 값을 바꾸고 보면 리스터 상태에 인스턴스 들이 해당 이름으로 떠있는 것을 볼 수 있다.
리소스별로 자원을 다르게 하거나 모니터링을 하기 위함

> sqlplus system/oracle@192.168.56.101:1521/abc.co.kr
  abc.co.kr 서비스 이름으로 prod 인스턴스에 접속이 가능하다.

클라이언트 세팅은
  tnsnames.ora 에 service_name=abc.co.kr

* instance_name 은 다 다르게 고유
* service_names 그때그때 같게 또 여러개 가능
* client 에서 각각 다른 머신의 리스너에 특정 DB 인스턴스를 연결받을 수 있다. (해당 리스너에 해당 DB 인스턴스 정보가 있다면)
* service_names 을 정해주는 이유
  Pooling         계산 능력을 배분할 수 있다.
  Virtualization  특정 머신에 붙지 않고 계산만 할 수 있으면 된다.
  Provisioning    더 많은 자원이 필요한 것에 많은 배분 해줄 수 있다.


oracle database server 의 instance 를 open 시킴

EMCA dbcontrol
DB Control

디비삭제
rm -rf $ORACLE_BASE/oradta/orcl


## 실습

  SQL> col DESCRIPTION noprint
  SQL> col PROPERTY_VALUE format a60
  SQL> select * from database_properties;

  SQL> select * from v$nls_valid_values
       where parameter = 'CHARACTERSET'
       order by 2;

# instance_name vs service_names

  SQL> show parameter name

  NAME                                 TYPE        VALUE
  ------------------------------------ ----------- -----------------------
  instance_name                        string      prod
  service_names                        string      prod

  SQL> alter system set service_names = 'prod, abc.co.kr, puhaha';

	## 다음 내용은 참고용입니다. 실습용이 아닙니다.

	  C:\Users\student> notepad C:\instantclient_12_1\tnsnames.ora

	nemam =
	  (DESCRIPTION =
	    (ADDRESS_LIST =
	      (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.56.101)(PORT = 1521))
	      (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.56.102)(PORT = 1521))
	      (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.56.103)(PORT = 1521))
	    )
	    (CONNECT_DATA =
	      (SERVICE_NAME = orcl)
	    )
	  )

	  C:\Users\student>sqlplus system/oracle@nemam


  __
