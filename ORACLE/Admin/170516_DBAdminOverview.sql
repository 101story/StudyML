
OCP-DBA 자격증

## Oracle Server Architecture
http://www.ramprasath91.in/2015/11/oracle-server-architecture.html

## Process 구조
https://docs.oracle.com/cd/E11882_01/server.112/e40540/process.htm#CNCPT902


## 구성
* Database : doc, Document, file 생성한다.
* DBMS : DMS, MSWord 설치한다.
* Oracle Datebase Server :
  Database(Datafile, Redo log File, Control File)
  + Instance (Memory:SGA, Background Process:BGP)

  - DB : Instance
      1 : 1
      1 : N -> RAC (9i)
      N : 1 -> Multi Tenant Database (12c)

  - Oracle Server 는 동일한 원격지에서 접속하는것에 응대할수 없다. -> 리스너(1531)를 이용 여러개 가능

  - 서버접속
    > sqlplus 유저/암호@IP(머신)포드번호(리스너)/XE

* spawn(알을까다)
  Application 자원 구동/정지/점검 하기 위한 별도의 'actions'


* SQL Plus : Oracle Server 에 기본서버(환경변수 oracle_sid)에 접속하여 쿼리를 실행하기 위한 도구
  export oracle_sid  = xe

* Daemon : 자동으로 많은 Process 를 띄우는 것을 통칭함

* GI : 스토리지 관리
  GI(ASM + Oracle Restart) + Single Instan
  Oracle Grid Infrastructure : The Oracle Grid Infrastructure for a standalone server is the Oracle software that provides system support for an Oracle database including volume management, file system, and automatic restart capabilities.
  https://docs.oracle.com/cd/E18185_01/doc/install.112/e16763/oraclerestart.htm
  ASM(Raid 방식을 구현) raw device의 빠른 장점과 File system의 편한 장점을 살려 스토리지 관리 방식

* 아카이브 : 파일이 사라지지 않음

* Oracle Server Name
  - Instance Name : 고유 이름 (권진희)
  - Service Name :  Like 역할에 따른 다수의 이름 (오라클 강사님, 501호 학생, ... )
    Oracle Instructor 불러주세요 -> 여러 오라클 강사님 중 한분이 할당 될 수 있음 (대처 될 수 있음)


## 서버, 리스너 보기 명령어
  ps -ef|grep pmon : 구동하고 있는 서버 보기
  ps -ef|grep smon : 구동하고 있는 서버 보기
  ps -ef|grep lsnr : 구동하고 있는 리스너
  lsnlctr dbca netmgr

## Process
  - User Process : User 가 원할떄 실행 / 종료
  - Server Process (Shadow) : User Process 가 시작될때 같이 시작되고 같이 죽음
  - Background Process : Startup / Shatdown
  - Others : 리스너 ..


oracle ware 누구나 다운받아 사용 할 수 있음

===========================
  Oracle Datebase Server
===========================
## Oracle Datebase Server : Database + Instance

  * Database
    - Datafile : 데이터, 일정한 단위의 공간(block:기본8K)으로 나눠져 있음, 표의 형태
      block : 저장의 최소단위, IO 의 최소단위
      표 : 사용자의 최소단위
      -> User Data : 우리가 만든표 emp ..
      -> Meta Data : 자동으로 관리를 위해 생성되는 표 obj$ tab$ ..
    - Redo log file : 했던짓을 다시하는 파일
    - Control File : 메타데이터 관리형 파일

  * Instance
    - System Global Area:SGA
    - Background Process:BGP


* 테이블 생성 정보 확인
> select * from user_objects where object_type = 'TABLE'

View : Named Select
select
  from tables : 내껏만
  from all_tables : 내꺼와 남이 나한테 권한준것
  from dba_tables : 모든 테이블


## 백업과 복구
Backup : 복사 (기본 2번)
  logical
    Export/import, Data Pump, SQL Trace, ..
  phygical
    os 명령어, RMAN, ...

3rd party : 다른회사의 프로그램을 이용해서 복구

Failuer 가 생겼을때 해결방법
  -> 버리기
  -> Resore : 복원 백업한 시점으로 복원
  -> Recover : 복구 백업 이후에 변경한 것들을 복구 (Redo log file 최소 2개이상)
    - Complete Recovery : 복원하고 가지고 있는 Redo log file 끝까지 복구 완전복구
    - Incomplete Recovery : 복원하고 가지고 있는 Redo log file 요까지 복구 불완전복구

## Redo log file (총2벌이라고 가정)
  - WAL (write ahead log) : 데이터가 바뀌기 전에 로그를 남기고 바꿈
  - online redo log file / offline redo log file
  - noarchivelog mode :
    online log 파일 하나 쓰고 다 쓰면 다름 2번째 online log 사용 (스위치 logfile)
    2개 다 쓰고 나면 1번째 online log 에 덮어 씌워짐
    복구가 힘듬
  - archivelog mode :
    존재하는 2개의 online log 파일을 다 쓰고 나면 1번 파일은
    지정위치로 offline log 파일로 백업해 두고 다시 online log 재 사용함
    alter system switch logfile 수동으로 offline log 백업해 둠
    archivelog 파일(offline redo log file)도 2벌로 백업해둠
  - archiver : 자동 파일 복사 프로세스

## Control file
  : 어떤 데이터가 해당 인스턴스에 해당하는 데이터인지 저장되어 있음
  3쌍둥이 백업되어 있다. 3중 이상 해둠

* Memory Structure
  - SGA
  - PGA
* Process Structure
  - User Process
  - Server Process (Shadow, Foreground)
  - Background Process: PMON, SMON(monitor), DBWin ...
  Other
* Storage Structure
  - phygical
    -> Database File : Data file, Redo log(online), Control
      Database 안에 존재하는 중요파일
    -> Other Key File : Paramager pw diana.. archiver file
      기타 중요 파일
  - Logical : Tablespace, Segment, Extent, Block

## 이름 규칙
소문자 n
Snnn S000 S001 ...
Dnnn D000 D001 ...


###########################
 Oracle Server 설치 툴이용
###########################

## 11gWS1 sg2 단원2 GI, DBMS 설치 ###
1. GI | DBMS 설치
  GI : Store 를 관리
    sqlplus
    dbca (DB Config Access)
  DBMS : DB 를 관리
    sqlplus
    asmca (ASM Config Access)

2. +ASM : GI 설치하면서 만든 인스턴스 생성
  Data
    4개의 디스크 그룹
    High | Normal | External
    3중  | 2중    | 1중  (백업)
    - 미러를 상용하여 normal 로 선택하면 총 디스크의 1/2 사용가능한다.
    데이터를 넣으면 spread 되어서 2개의 디스크에 쓰이고 2개의 디스크에 백업된다.
  FRA
    4개의 디스크 그룹
    External 1중 4개의 디스크를 그대로 사용
3. 자동으로 환경변수 잡아주기
  /oracle/bin/oraenv
    - shall script 파일
    - 환경변수를 변경해줌
  /etc/oratab 파일
    경로에서 sid 로 부팅시켜줌
    oracleSID:ORACLE_HOME:N
    +ASM:/u01/..../grid:N
    -- 또는
    export oracle_sid = +ASM
    export oracle_home = /..../grid
    명령어 실행으로 잡아줘야함
  - SID 를 바꿔주면 해당 SID 로 oracle_home 을 자동으로 설정되어 있는 값으로 넣어줌

## 11gWS1 sg2 단원3
orcl DB 인스턴스
Data 디스크 안에 생김 spread 2종


--??? 무슨소리지
Spread
SAME
Strike
And
Mea(미어)
Raid : 작은 물량으로 백업 많이 해서 미러 복사 파일은 다 퍼져 있음


__
