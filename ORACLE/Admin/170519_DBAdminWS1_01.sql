
============================================
 0장
============================================

# Recommended Related Training Courses:

  - http://me2.do/xofl9J7W : 한국 오라클 교육센터
  - http://me2.do/5ojccFYB : Oracle Database 11g: Administration Workshop II Release 2
  - http://me2.do/FQKvv9yP : Oracle Database 11g: Backup and Recovery Workshop
  - http://me2.do/F0BvvEe7 : Oracle Database 11g: Performance Tuning Release 2
  - http://me2.do/FJRXdpve : Oracle Grid Infrastructure 11g: Manage Clusterware and ASM

# Related Documents

  - http://me2.do/5BOXXt5k

# Oracle DBMS Installation

  - Single Instance, Multiple Instance
  - GI(ASM + Oracle Restart) + Single Instance
  - GI(ASM + Oracle Clusterware) + Multiple Instance

# Oracle Database 10gR2, 11gR2 Installation On Enterprise Linux 4.0

  - http://gseducation.blog.me/20093164977

# Pre-Built Developer VMs (for Oracle VM VirtualBox)

  http://www.oracle.com/technetwork/community/developer-vm/index.html

============================================
 1장
============================================

* http://docs.oracle.com/cd/B10501_01/server.920/a96524/c01_02intro.htm#20385
  http://docs.oracle.com/cd/E11882_01/server.112/e25789/intro.htm#i68236

* Databse
* DBMS
* Oracle Database Server = Database + Instance

* Performance ≒ 수행, 실행, 공연, 성능 ...
* Tuning      ≒ 조정, ...

* Architecture

  Oracle Server - Database = Datafile + Redo log file + Control file (cf.Other key files)
                - Instance = SGA + BGP

  Startup 순서 : shutdown --> nomount --> mount --> open
                          ↑          ↑        ↑
                           P           C         D,R

  Block(Primary block 또는 Standard block)

  WAL(Write ahead log)
  Noarchivelog mode / Archivelog mode

  User process
  Server process(= Shadow process, Foreground process)
  BGP(Background process : PMON, SMON, DBWn, LGWR, CKPT, ARCn, MMON, ADDM, ...)

  Recursive SQL

  SQL 처리 과정

    - http://docs.oracle.com/cd/E11882_01/server.112/e25789/sqllangu.htm#CHDDAGAA
    - Select 수행 순서
    - DML 수행 순서 + Commit + Instance Recovery (+ DBWn 및 LGWR의 사명)

  DBWR와 LGWR가 내려쓰는 경우              : http://cafe.naver.com/gsinternet/24
  Mechanics of Instance and Crash Recovery : http://cafe.naver.com/gsinternet/25

===========================
== Logical Storage
===========================

  Tablespace - Segment - Extent - Block

  I.I 정의:
    Table index sequence PROCEDURE ... 은 다 오프젝트
    Table, index, undo, partition, ... 는 Segment (공간을 자지하는 객체 )

    Tablespace is a Container
    Segment is space occupying object
    Extent is continuous block
    Block 2k, 4k, 8k... 최소단위 disk blocks 을 모아놓은 것

    공간 할당 시나리오 :
      - 처음 생성 시
      segment=0개
      extent=2개 - 어제만든 Tablespace 1 개에 Datafile 이 2개 만듬
      SQL> create tablespace dhts
           datafile '/u01/app/oracle/oradata/prod/dhts01.dbf' size 10m,
                    '/u01/app/oracle/oradata/prod/dhts02.dbf' size 10m
                    autoextend on next 10m maxsize 100m;
      Logical structure!!!!!!

      database --= data file -- os file =-- oracle data block
      database --= tablespace ...= segment --= extemt --= oracle data block
      data file --= extent
      그림있음!!

      tablespace란?!         is container
      segment란?!            sapce occupying object
      extent 란?!            continuous block
      oracle data block 란?  최소단위 (I/O, Storage)


      Database 만든 직후 - Segment = 0
                       - Extent = 2, tablespace --= datafile --= extent 이니까 가능하다.
                       tablespace ...= segment --= extent --= block

                       meta data 안에서 이루어 지는 일!!!!!!!

                       header 가지고 있네!!, tablespace에!!

                       fet$ _______________    <- update
                            _______________

                            // create table emp 하면
                       uet$ emp 0, ... 10, 8    <- insert후 위 fet$ meta data "update"

                            // insert table emp 하면
                       uet$ emp 1, ... 19, 8    <- insert후 위 fet$ meta data "update"

                       이러면, segment = 1 extent = 4 된다. # 원래 2개 + 작업한 거 2개

                       // create table dept 하면
                       uet$ dept 0 ... 28, 8    <- insert후 위 fet$ meta data "update"

                       // insert emp 하면
                       uet$ emp 2 ... 37, 8    <- insert후 위 fet$ meta data "update"

                       이러면, segment = 2, extent = 6 된다.

                       - fet$ dba_free_space
                       - uet$ dba_extents

      - table 생성
      Fet$ row 가 2개 (table dba_free_space)
        원래 가지고 있는 초기공간 정보 table 이 생길때마다 업데이트됨
        정보 update 를 하는대 경합이 벌어짐
      Uet$ emp table 공간 extent 할당 (dba_extents)
        emp 가 할당된 공간을 다 사용하면 extent 를 다시 할당
          -> segment 는 1개 Extent 는 4개 (사용된거 2개 사용안된거 2개)
        dept table 생성 extent 할당
        emp 할당된 공간을 또 다 사용하고 extent 를 다시 할당
          -> segment 는 2개 (emp, dept) Extent 는 6개 (사용된거 4개 사용안된거 2개)

  I.I 관계:
    Tablespace 는 여러개의 Segment 를 가질 수도 있고 없을 수도 있다.
    Tablespace 는 여러개의 Datafile 가질수 있다.
    Datafile 은 1 개의 OS Page 를 가진다.
    Datafile 은 여러개의 Extent 를 가진다.
    Block 은 여러개의 OS Page 를 갖는다.
    Segment 를 제외한 나머지는 필수적으로 1개 이상 있어야 한다.

  > 조회 쿼리문
    select username from dba_users order by 1;
    select * from dba_segments where owner = 'SH' and segment_name = 'TIMES';
    select * from dba_extents  where owner = 'SH' and segment_name = 'TIMES';
    select * from dba_free_space;
    col SEGMENT_NAME FORMAT A30
    select OWNER, SEGMENT_NAME, SEGMENT_TYPE, BLOCKS, EXTENTS
      from dba_segments
      where OWNER = 'SH';
    select SEGMENT_NAME, EXTENT_ID, FILE_ID, BLOCK_ID, BLOCKS
      from dba_extents
      where OWNER = 'SH' and segment_name = 'TIMES';


* 실습

  OS] . oraenv

  ORACLE_SID = [oracle] ? orcl

  192.168.56.101
  주소로 접속

  관리자 홈페이지에
  sys/oracle connect as 에 sysdba 로 변경해서 접속

  영문으로 보는게 좋음
  Tablespace example sh소유의 정보 확인
  extent map 클릭
  Fet$ free space
  segment_name times

  임의로 테이블 스페이스에 datafile 만들어 봄
  create tablespace



About SQL Processing
https://docs.oracle.com/database/121/TGSQL/tgsql_sqlproc.htm#TGSQL176

== selec 문 수행 과정
==========================================

** PGA 하는 일 (sql 문을 던지면)
  > parse
    syntax > semantic (recursive sql) > 동일 문장 찾기(과거에 수행한적이 있는지)
      찾으면 바로 execute
      못찾으면 optimization 어떻게 잘 찾을까
      (건너뛰면 softparse / 수행하면 hardparse)
      recursive sql:
      CTE는 SELECT, INSERT, UPDATE, DELETE 또는 CREATE VIEW 문 하나의 실행 범위 내에서 정의되는 임시 결과 집합이라고 볼 수 있다.
      재귀적 CTE를 참조하는 쿼리를 재귀 쿼리
  > execute
    read 메모리 또는 디스크에서 데이터를 찾음
    v$bh 를 뒤져서 caching 이 되었는지 봄
  > fetch
    go get it
    select 에서만 동작
    정렬 sort order by group by ...

** SGA 하는 일
  shared pool
    library cache : hard parse 를 줄이기 위해서 존재
      최근에 질의한 내용들이 들어가 있음
      SQL문 수행과 관련된 모든 정보 저장
      Library Cache Object(LCO) : 라이브러리 캐시에 저장되는 정보의 단위
      실행가능한 LCO : 실행가능
        Package, Procedure, Function, Trigger
        Anonymous PL/SQL Block, Object LCO : object 정보
        Table Definition, View Definition, Form Definition
    data dictionary cache : 메타데이터에 대한 disk i/o 를 줄이기 위함
      data dictionary cache (=rowcache v$row) 메타데이터의 row 가 들어옴 에 들어감
  data buffer chash : buffer 데이터 블럭(메타데이터, user데이터 등..)에대한 디스크 io 를 줄이기 위함
    datafile 에 있는 데이터를 buffer cache 에 넣었다가 사용된적이 있으면 data dictionary cache 넣음
    buffer 와 block 의 사이즈는 동일

** DATABASE
  datafile : block

==========================================
== DML 문 수행 과정
==========================================
1. update emp set sal = ...
2. rollback
3. 읽기 일관성
  a 라는 사람이 update 를 하고
  b 가 select 를 하면 commit 이 되지 않았기 때문에
  다른 사람이 변경한 내용은 buffer cache 에서 old 버퍼를 이용해서 옛날 결과물을 던져줌 (옛날 값을 가지고 있음) MVCC

** PGA 하는 일 (sql 문을 던지면)
  > parse
    syntax -> semantic (recursive sql) -> 동일 문장 찾기(과거에 수행한적이 있는지)
    -> optimization
  > execute
    안쓰고 있는 undo 블럭과 data 블럭을 datafile 에서 찾아서 buffer cache 에 둠
    buffer cache 에서 raw level lock 을 함
    redo 엔트리가 생김 : WAL 내가 무엇을 할꺼라고 남기고 차면 redo log file 로 넘김 복구 할때만 사용 함
    undo 블럭 수정 : rollback 했을 때 데이터를 되돌림
    data 블럭 수정

** SGA 하는 일
  shared pool
  data buffer chash
    '읽기 일관성 일어나는 일'
      XCurrent (Exclusive): 기본블럭 모든 DML 은 xcur 에 걸림 (확정되지 않은 최신)
        변경되지 않은 값은 undo 블럭에 있음
        A 라는 사용자가 71번 블럭 1번 ROW 를 update : XCurrent 블럭
      CR (Consistent read): DMS 한 사용자가 아닌 다른사용자가 1번 파일의 71번 블럭을 읽으면
        71번 블럭의 ROW 의 과거 값을 조합 하여 질의를 만들어주는 블럭
        B 라는 사용자가 71번 블럭 3번 ROW 를 select : CR 블럭
      v$bh 를 질의 하면 블럭 번호가 같음
      FREE(최초의상태) -> PINNED 내가 쓰겠다고 핀된 상태 <-> CLEAN
      재이용 가능 상태 CLEAN
      Dirty buffer : PINNED 상태에서 원본과 내용이 달라진 버퍼
        CLEAN 이 되어야 사용가능 (원본과 내용이 같아지는 행위: rollback 또는 DBwriter 가 원래 자리에 씀)
      PINNED -> Dirty -> CLEAN
      락을 걸고 DML 을 시작함
      UNDO DATA 블럭을 만듬
      Current 블록 : 디스크로부터 읽혀진 후 사용자의 갱신사항이 반영된 최종 상태의 원본 블록
      CR 블록 : Current 블록에 대한 복사본. CR블록은 여러 버전이 존재할 수 있지만 Current 블록은 오직 한 개
      사용자 A의 Undo XCurrent B 사용자가 DML 을 하게 되면 B 사용자의 undo 블럭과 A 사용자의 XCurrent 블럭을 사용하게 됨
      사용자 C가 동일한 블럭에 대해서 select 를 하게 되면 CR 블럭이 생기고 A,B 사용자의 변경 이전 상태를 볼 수 있도록 함
      한블럭에 여러 사용자가 UPDATE SELECT ... 한경우 각 사용자의 UNDO 블럭, CR 블럭과 동시에 최신상태를 유지하는 Current 블럭이 존재함
  Redo log buffer
  Large pool
  -- 데디케이티드 1 : 1 인경우만 생각했는데 아닌 경우
    shared 의 역할을 나눠가짐
    shared pool 의 경합을 줄임
    병렬처리를 한다던지 할때...
    9i 이전 : 하나의 shared pool latch로 전체 관리 (latch 놓아주지 않음 걸어 놓음)
    9i 이후 : shared pool을 여러 개의 sub pool로 나누어 관리할 수 있게되면서 latch도 7개까지 사용 가능
    동시 사용자가 순간적으로 과도한 하드파싱 부하를 일으킨다면 shared pool latch에 대한 경합 현상 발생 가능
    목적 : library cache에 저장된 정보를 빠르게 찾고 저장
  Java pool
    server-side program 으로 Java 나 PLSQL 사용 가능


** DATABASE
  datafile : block
    undo : undo segment 또는 rollback segment 라고 부름
      v$rollname 테이블에 메타데이터에 대한 dml 발생시 보관하는 undo 데이터
      변경전 데이터를 전문적으로 임시로 보관하는 공간
      테이블 약 10 정도 있음
      show parameter undo
      v$transaction 현재 진행중인 트렌젝션 내용 중 xidusn(undo segment number)
      v$rollstat 조회

==========================================


* BG 프로세스
  서버프로세스 의 작업에 의해서 birty, redo 엔트리가 생김
  > pmon(iter) 는 user process 가 갑자기 죽은 곳의 메모리를 해제해줌 clean up
    리스너에 dynamic 서비스 등록
    아무일도 하지 않는 접속을 끊고 clean up 시킴
  > smon 자기 자신에 대한 모니터링 자신의 복구를 함
    temp tablespace (segment) 임시 테이블 을 만들어 공간을 만들어 사용하는데 shutdown 을 하게 되면 그 공간을 smon 이 지움
  > dbwriter dml 을 던지면 변경이 되고 datafile 로 내리는 역할
  > logwriter 로그 스위치
  > archiver 로그 스위치가 되면 아카이브 시키는 역할
    딱 한가지 경우(로그스위치) 에만 수행
  > dbwriter(birty buffer), logwriter(redo log buffer)
    모아서 database 에 내려쓰는 역할 (DBWR와 LGWR가 내려쓰는 경우 위 URL)
    서버프로세스가 buffer 공간을 사용할 수 있도록 비워줌
    Redo 가 내려가야만 Dirty 버퍼가 내려갈 수 있음 (복구에 필요한걸 먼저 하고 data 에 씀)
  > checkpointer (CKPT)
    dbwriter 와 한팀으로 dbwriter 에게 내리는 신호를 보내는 역할
    모든 redo log file 은 한개 (잘라서 사용)
    dbwriter 가 작업을 끝내면 datafile, controlfile 의 header 에 기록
    복원 할 때 checkpoint 보다 redo log 가 더 미래의 정보를 가지고 있다면 redo 를 수행
  > recover 하나이상의 트렌젝션이 2개 이상의 DB 에 접속했을 때 끊어진 것을 자동으로 롤백시킴
  > GI oracle restart
    OS init -> GI Wrapper -> GI Deamons and Process ...
    죽으면 살려줌


프로세스를 깨우는 방법 timeout, signal


오라클 트랜잭션(Transaction) 이해
http://www.exemwiki.com/?p=3183

디스크에 데이터를 담을 때는 다 table 의 형태로 담음
메모리 상에서는 다른 자료구조를 사용하여 담음
system, sysaux, undo 는 database 가 생성될 때 마다  자동으로 생성됨


LCO libary cache object

hash key 값
  문장을 아스키값을 이용해 함수로 변경 시킨 값
  DML 문장들이 규칙을 가지고 연결 되어 있음 어쩌다보니 아스키값이 같거나 함수 적용 결과가 같이사 library cache 에 리스트로 서로 연결되어 있음

동일 문장 찾기
  아스키값을 구하고 결과로 libary cache 에 있는 list 값을 뒤짐
  리스트를 발견 후 글자:글자 비교를 하여 찾거나 optimazetion 을 함
  대소문자 스페이스 까지도 전부 같은 것을 찾음 (parse 에 부담을 줄여야함)

optimazetion
  메모리를 할당 받아야 하는데 할당 받는 것도 순서대로 받음 shared pool latch
optimazer
  query optimazer is built-in Database software


오라클을 힘들게 하는 것
  hard parse 가 많아지면 shared pool latch 가 많아짐


ENQ TX... user 들의 명령이 처리가 되어야 하는데 각 단계에서 멈추는 순간을 v$session 을 이용하여 확인 가능


아카이브 파일이 꽉차면 redo log file 도 꽉차고 redu 엔트리도 멈추고 모든 동작을 할 수 없게됨

sga 의 memory 덤프를 떠놓고 trace file 에 넣을 수 있음

hive, pig 가 sql 문을 java 문장으로 변경하여 hadoop 으로 던져 수행하게 됨


shared_pool_size
DB_cache_size
log_buffers
Large_pool_size
Java_pool_size
Streams_pool_size
  -> MM, MMON Process 가 메모리 조정을 알아서 해줌
  파라메터 설정은 않하고 SGA_TARGET 게만 해주면 Process 들이 구동됨
  하한값을 개별로 정할 수 있다.



set prompte "&_user@&_connect_identifi..>"

select * from v$sgastat where pool = 'shared pool';

select sql_text from v$sql where rownum <=3;
parsing_user_id =

desc dba_users
select user_id, username from dba_users;
select sql_text from v$sql where parsing_user_id = 32;

select * from dba_objects where owner = 'ORANGE';

select * from v$bh wehre objd=13016;
여러개의 블럭들이 캐싱되어 있음을 알 수 있다.



* 내용 확인 : 용어 이해를 위한 예제이므로 가볍게 여기세요.

  print_table 프로시져 소스코드 : http://cafe.naver.com/gsinternet/157

  set serveroutput on
  exec print_table('select * from v$database')
  exec print_table('select * from v$instance')

  exec print_table('select * from v$sga')
  exec print_table('select * from v$bgprocess')

  select * from v$sgastat;
  select * from v$bgprocess order by 1;

  exec print_table('select * from v$controlfile')
  exec print_table('select * from v$logfile')
  exec print_table('select * from v$datafile')



ASM
 이식성이 높은 고성능 파일 시스템

ASM Allocation Unit
  하나의 Disk 그룹에 AU 로 쪼개져 있음
Extent
  au 묶음

___
