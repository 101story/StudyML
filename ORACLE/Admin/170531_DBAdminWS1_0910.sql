
============================================
 9장 데이터 동시성 관리
============================================

-- 경합을 없애주기 위한 방법

## Latch VS Lock
Latch 걸쇠
Latch 의 종류
SQL> select event#, name from v$event_name
         where name like 'latch:%';

- latch: cache buffers chains
버퍼 캐시(Buffer cache)에서 특정 블록을 탐색하고자 하는 프로세스는 cache buffers chains 래치를 획득해야 한다. 이 과정에서 경합이 발생하면 latch: cache buffers chains 이벤트를 대기하게 된다.

- latch: cache buffers lru chain
버퍼 캐시(Buffer cache)에서 프리 버퍼와 더티 버퍼를 탐색하고자 하는 프로세스는 cache buffers lru chain 래치를 획득해야 한다. 이 과정에서 경합이 발생하면 latch: cache buffers lru chain 이벤트를 대기하게 된다.

- latch: shared pool
Shared Pool의 힙(Heap)영역에서 새로운 청크(Chunk)를 할당받고자 하는 프로세스는 shared pool 래치를 획득해야 한다. 이 과정에서 경합이 발생하면 latch: shared pool 이벤트를 대기한다.

- latch: library cache
Library Cache 영역을 탐색하고자 하는 프로세스는 library cache 래치를 획득해야 한다. 이 과정에서 경합이 발생하면 latch: library cache 이벤트를 대기한다.

- latch: redo copy
DML에 의한 변동사항을 리두 버퍼(Redo buffer)에 기록하고자 하는 프로세스는 작업의 전 과정 동안 redo copy 래치 획득해야 한다. 이 과정에서 경합이 발생하면 latch: redo copy 이벤트를 대기한다.

*  LATCH(래치) 와 LOCK(락) 1
  http://tawool.tistory.com/237

*                  LATCH VS LOCK
  Queuing 의 여부    X       O     -- 한줄서기
  보다 엄격한 독점    O       X

  예) shared pool latch
  메모리를 할당 받기 위해서 프로세스들이 기다리는데
  운좋게 순서가 맞은 프로세스가 할당 받게함
  _spin_count N바퀴 돌고 다시 할당 가능 여부 확인


* 특징
  - LATCH
    독점, 짧게 독점하고 마는 경우 메모리
  - LOCK
    공유가능, 데이터

  -- 실제로 발생한 이벤트
  select event from v$system_event order by 1

* TM Lock


### 분류

 - http://me2.do/FHBXi3pA

 - Exclusive : I have it and you can not have it.
   Share     : I have it and you can share it with me.
               But if you try to get it exclusively,
               I will not let you.

 - Lock Mode : None, Null, RS, RX, S, SRX, X
                0     1    2   3   4   5   6

 - v$lock 및 v$resource

* resource
  -- 자원을 사용하기 시작하면
  TM table resource
  TX row/transaction resource

  resource:lock => 1:N
  select * from v$resource wehre type in('TM', 'TX');
  select * from v$lock wehre type in('TM', 'TX');
  RX 공유 가능계열의 lock (3)

  Lmode 어떤모드로 점유하고 있는지
    기다리면 0 request 에 숫자가 늘어남
    원래 점유한 애는 block 이 늘어남

* 여러 프로세스가 같은 리소스에 접근하여 작업을 하면
    리소스는 늘어나지 않고
    락은 사용자 마다 늘어남


# v$lock 및 v$resource

  [session 0] - 관리자
    SQL> alter user scott identified by tiger account unlock;
    SQL> ed lock.sql

       select * from v$resource where type in ('TM', 'TX');
       select * from v$lock where type in ('TM', 'TX');

    SQL> @lock

  [session 1]

    OS] sqlplus scott/tiger

    SQL> drop table t1 purge;

    SQL> create table t1
         as
         select empno, sal
         from emp;


    SQL> update t1
         set sal = 1000
         where empno = 7782;
         -- t1 리소스가 되고 RX Lcok (3) 이 걸림
         -- TM, TX

  [session 0]

    SQL> @lock

  [session 2]

    SQL> update t1
         set sal = 2000
         where empno = 7900;
         -- 같은 테이블의 다른 row
         -- table 은 그대로 리소스이고
         -- row 에 대한 리소스만 늘어남
         -- lock 정보는 다 추가됨
         -- 총 3개의 리소스(테이블, 로우, 로우), 4개의 락

  [session 0]

    SQL> @lock
      ADDR             TYPE        ID1        ID2
      ---------------- ---- ---------- ----------
      000007FF3E6FDFB0 TM        21147          0
      000007FF3E6FF520 TX       589850        533
      000007FF3E7046D0 TX       262153        533


      ADDR             KADDR                   SID TYPE        ID1        ID2      LMODE    REQUEST      CTIME      BLOCK
      ---------------- ---------------- ---------- ---- ---------- ---------- ---------- ---------- ---------- ----------
      000000001B3DBBD8 000000001B3DBC38         91 TM        21147          0          3          0        141          0
      000000001B3DBBD8 000000001B3DBC38         67 TM        21147          0          3          0        178          0
      000007FF3C4672F8 000007FF3C467370         91 TX       262153        533          6          0        141          0
      000007FF3C4A8008 000007FF3C4A8080         67 TX       589850        533          6          0          5          0


  [session 3]

    SQL> update t1
         set sal = 1500
         where empno = 7782;
         -- 같은 row 를 접근한 row에 대한 기다리는 락 1개만 늘어남
         -- 리소스는 그대로

  [session 0]

    SQL> @lock
      ADDR             TYPE        ID1        ID2
      ---------------- ---- ---------- ----------
      000007FF3E6FDFB0 TM        21147          0
      000007FF3E6FF520 TX       589850        533
      000007FF3E7046D0 TX       262153        533


      ADDR             KADDR                   SID TYPE        ID1        ID2      LMODE    REQUEST      CTIME      BLOCK
      ---------------- ---------------- ---------- ---- ---------- ---------- ---------- ---------- ---------- ----------
      000007FF3E6803A0 000007FF3E6803F8        161 TX       589850        533          0          6         25          0
      000000001B3DCC10 000000001B3DCC70         91 TM        21147          0          3          0        241          0
      000000001B3DCC10 000000001B3DCC70        161 TM        21147          0          3          0         25          0
      000000001B3DCC10 000000001B3DCC70         67 TM        21147          0          3          0        278          0
      000007FF3C4672F8 000007FF3C467370         91 TX       262153        533          6          0        241          0
      000007FF3C4A8008 000007FF3C4A8080         67 TX       589850        533          6          0        105          1

  [session 4]

    SQL> alter table t1
         add (col1 number);
         -- S 락을 검
         -- 다른 세션에 의해서 락이 걸려 있기 떄문에 DDL 임에도 불구하고 커밋이 되지 않음
         -- 다른 락이 풀리면 자동으로 커밋됨

  [session 0]

    SQL> @lock
      ADDR             TYPE        ID1        ID2
      ---------------- ---- ---------- ----------
      000007FF3E6FDFB0 TM        21147          0
      000007FF3E6FF520 TX       589850        533
      000007FF3E701108 TX       655377        778
      000007FF3E7046D0 TX       262153        533


      ADDR             KADDR                   SID TYPE        ID1        ID2      LMODE    REQUEST      CTIME      BLOCK
      ---------------- ---------------- ---------- ---- ---------- ---------- ---------- ---------- ---------- ----------
      000007FF3E6803A0 000007FF3E6803F8        161 TX       589850        533          0          6         84          0
      000007FF3E680640 000007FF3E680698        115 TX       589850        533          0          4         13          0
      000000001B3DCC10 000000001B3DCC70         91 TM        21147          0          3          0        300          0
      000000001B3DCC10 000000001B3DCC70        161 TM        21147          0          3          0         84          0
      000000001B3DCC10 000000001B3DCC70         67 TM        21147          0          3          0        337          0
      000000001B3DCC10 000000001B3DCC70        115 TM        21147          0          3          0         13          0
      000007FF3C4672F8 000007FF3C467370         91 TX       262153        533          6          0        300          0
      000007FF3C4A8008 000007FF3C4A8080         67 TX       589850        533          6          0        164          1
      000007FF3C4BD9B8 000007FF3C4BDA30        115 TX       655377        778          6          0         13          0

  -- 추가 --
  [session 1]
    SQL> rollback
      -- table 과 row 에 걸려 있는 락이 하나씩 줄어듬

  [session 2]
    SQL> rollback
      -- 리소스가 1개(row 에 관한 것만) 줄고 락은 2개 줄고
      -- 전부다 commit 또는 rollback 하면 더이상의 자원과 락은 없음

AKA as known as

## lock Case
  * table1 FK -> table2 PK
    t1 의 FK 에 해당하는 t2 의 row 를 삭제 하게 되면
    t1 에 S 락이 걸려 t1, t2 전부 DML 이 불가한 상태가 된다.
      해결) t1 에 FK 를 index 로 만들면 index 에 락이 걸리게 되기 때문에 t1 에 DML 을 할 수 있게 된다.

  * table1 PK <- table2 FK1(on delete cascade) | FK2 -> table3 PK
    t1 의 row 를 삭제 하게 되면 t2 에 SPX 락이 걸림 (S 락을 허용하지 않음)
    t3 에서 row 를 삭제 하려고 하면 S 락을 t2 에 걸어야 하는데 못걸어 삭제가 되지 않는다.


## oracle escalate 를 하지 않음
  자동으로 획득한 lock 은 다른 트렌젝셩과 잠재적 충돌을 최소화 하기 위해 항상 가장 낮은 lock 레벨을 선택함
  ‘Lock Escalation’이란 관리할 Lock 리소스가 정해진 임계치를 넘으면서 로우 레벨 락이 페이지, 익스텐트, 테이블 레벨 락으로 점점 확장되는 것을 말한다.
  http://www.dbguide.net/db.db?cmd=view&boardUid=148215&boardConfigUid=9&categoryUid=216&boardIdx=138&boardStep=1

## Lock 종류 (일부)
  - Row Share(RS) : lock 된 테이블에 대한 동시 엑세스를 허용하지만 세션에 배타적 엑세스를 위해 전체 테이블의 lock 하는 것을 금지
  - Row Exclusive(RX) : share 모드에서도 lock 하는 것을 금지 데이터 갱신, 삽입, 또는 삭제 시 자동으로 획득됨, 여러번 읽고 한번 쓸수 있음
  - Share(S) : 동시 쿼리는 허용하지만 lock 된 테이블에 대한 갱신은 금함 여러번 읽을 수 있지만 쓸 수는 없다.
  - Share Row Exclusive(SRX) : 전체 테이블을 쿼리하는데 사용되며 다른 유저가 테이블의 행을 쿼리 하는 것을 허용하지만 share 모드에서 락을 하거나 행을 갱신하는 것은 금지
  - Exclusive(X) : lock 된 테이블에서의 쿼리는 허용하지만 해당 테이블에서의 다른 작업은 금지함 테이블을 삭제하려면 필요

## lock 세션 kill (SID, 시리어 번호)
  SQL> alter system kill session '144,8982' immediate;



============================================
 10장 언두 데이터 관리
============================================

* undo segment
  select 에 대한 정보 있음


# MVCC

  http://terms.co.kr/MVCC.htm

# AUM

  SQL> create undo tablespace 이름 datafile '...';
  SQL> alter system set undo_management = auto;
  SQL> alter system set undo_tablespace = 이름;
  SQL> show parameter undo

	NAME                                 TYPE        VALUE
	------------------------------------ ----------- ------------------------------
	undo_management                      string      AUTO
	undo_retention                       integer     900
	undo_tablespace                      string      UNDOTBS02

# 관련 쿼리

  select * from dba_rollback_segs;
  -- 언두 세그먼크 관련 정보
  select * from v$rollstat;
  -- 언두 세그먼크 extents 정보
  select * from dba_undo_extents;


* segment
  table(현시점의 데이터)
  index(rowid)
  undo(과거시점의 데이터)
  temp(임세데이터)
  전부

* 순환사용
  redo log buffer
  undo segment : extents 를 순환사용함

* Undo segment 할당
  TBS(tablespace) : undo segment 를 전문적으로 보관
  undo segment header
  transaction table (여러개의 slot)

  어느 언두 세그먼트를 이용할지 결정
  언두 세그먼트의 트렌젝션에 기록함 (획득)
  트렌젝션id 가 생김

  data block 의 header 에 transaction slot 이 있고
  transaction slot 에 undo segment 의 header 의 정보가 있음
  트렌젝션 id 가 생기고 나면 data block 의 header 에 해당 undo segment 실제 위치가 저장됨
  data block 의 row header 는 내가 어느 transaction slot 인지 가리키고 있음

  buffer cache
  redo log buffer cache

  롤백 세그먼트 중에 undo 세그먼트를 할당 받음

  datafile-----
    system
    SYSAUX
    undo
    temp

  커밋
    데이터가 실제로 들어있는 블럭 헤더와 실제 로우, 언두 세그먼트(트렌젝션아이디) 헤더에 다시 씀 커밋된 정보로 변경함
    헤더에 들어 있는 트렌젝션 슬롯도 변경
    일부만 내려가있는 상태라면
    메모리에 있는 헤더만 정리하고 (데이터, 언두세그먼트, 언두블럭)
    파일은 건들이지 않는다.
    커밋됐다고 함
    그때까지 리두엔트리를 모두 내려쓰고
    데이터 버퍼캐시의 정보를 갱신하고
    끝냄
  롤백
    헤더도 다시 다 정리하고
    커밋안했는 애들을 다시 메모리에 올려서 다시 정리함
    커밋 보다 더 오래 걸림

  block cleanout
    블럭의 헤더 정리, 로우의 헤더 정보 정리
  delayed block cleanout
    커밋하고 메모리는 정리되고 파일은 정리 안됐을때
    파일에 있는것을 정리하는것
    정리 되지 않은 애들을 애들이 실제 정리되려면 유저가 다음에 해당 부분을 접근했을때 다시 정리함


    [ delayed block cleanout ]
    ITL(Interested Transaction List) 특정 블록을 변경하고자 하는 트랜잭션의 목록

    - long transaction으로 변경한 일부 data block은 메모리에 있고
      일부 data block은 data file에 기록되어 있는 상황에서
      commit을 수행한다면,

    - transaction이 변경한 data block중 file에 기록된 block의 ITL entry는
      전혀 수정하지 않으며, undo segment header의 transaction(TX) table에만
      해당 transaction에 대해서 commit 정보를 기록한다.

    - 이후 다른 transaction이 select나 dml(update/delete/insert) 작업을
      수행하여 앞의 항목에서 언급한 block을 access하는 순간 그 block내에
      commit되지 않은 transaction 정보가 ITL entry를 가지고 있으면,
      ITL entry의 내용 가운데 xid, uba 등을 이용하여 필요한 undo segment를
      찾고 block cleanout작업을 시작한다.

      commit시점에 block에 commit상태를 정리하지 않고 이후 그 블럭이 다시
      access될 때 cleanout이 이루어지기 때문에 delayed block cleanout이라고
      부른다.

    - rollback은 cleanout이 delay되지 않는다. (HW.B)

    - 비정상 shutdown으로 인해 rollback이 필요한 블럭이 file에 있는 경우
      cleanout을 위해 메모리로 읽어 올리는 작업은 instance recovery를
      통해서 수행하고 cleanout은 on-demand rollback 등을 이용한다. (HW.B)

    - block cleanout시에는 해당 block의 ITL entry의 내용을 보고 undo segment header를
      찾고, undo segment header의 TX table을 참조하여 해당 data block의 ITL entry를
      변경한다. 즉, undo segment의 TX table에 해당 transaction정보를 확인한 후 이미
      commit된 상태이면 block내의 ITL entry에도 status를 C로 변경하고 lock 정보도
      clean시키는 등의 cleanout작업을 수행한다.

    - 이러한 cleanout의 내용을 redo로 generage한다.
      redo record를 생성하지 않으면 이후에 recovery가 필요하여 수행된 경우,
      cleanout시켜야 할 block들이 많아질 수 있다.

    - cleanout에 대한 undo는 생성하지 않는다.
      cleanout 도중 문제가 발생한다면 다시 수행하면 된다.

    출처 : http://kr.forums.oracle.com/forums/thread.jspa?threadID=464663&tstart=939
    참고 : Transaction Internals in Oracle 10gR2 (98 ~ 114)



  undo transaction 은 작업이 계속 되면 하나에 계속 쓰되 다 쓰면 에러남
  steal 할수가 있어서 다른 undo segment 의 자원을 스틸해 올 수 있다.


* System Commit Number (SCN)
  Commit이 발생하면 해당 트랜잭션은 고유한 번호를 부여 받고 관리 된다. 그 고유한 번호를 오라클에서는 SCN이라고 부른다.
  변화가 있을때 마다 변경
  리두엔트리, 리두가 남은 시분초 누가 먼저 남았는지 의지하기엔 위험해서 내부적인 순서를 부여 SCN 이라함
  블럭 헤더에 SCN 이 들어감 블럭에 변경을 반영
    DB 전체 SCN 전체 블럭 중 가장 최근값을 가짐
    1,2,3,5 SCN 을 갖는 블럭이 4개 있을때 DB SCN 은 5

### undo data
  롤백, 읽기 일관성, 실패한 트렌젝션 복구
  한트렌젝션은 한언두만 이용
  하나의 언두세그먼트에 여러 트렌젝션도 가능하나 (비추)
  언두데이터는 언두세그먼트에 들어가고
  언두세그먼트는 언두테이블스페이스에 들어감

## undo tablespace
  마운트상태에서 undo tablespace 복구해야됨
  하나의 인스턴스에만 배정될수 있다.
  디비하나에 여러 인스턴스 이면 각각 하나의 undo tablespace 필요함
  pool (공유) : 내가 독점적으로 쓰고 반납하면 그때 다시 갔다 쓰고
  하나의 디비에 여러 undo segment 가 있고 pool 되어 사용되고 반납된다. (순환버퍼처럼)

## 언두 VS 리두
  직접 만드는 데이터에 변경이 일어나면 변경전 데이터 언두
  변경 내역 데이터 리두
  언두 언두세그먼트 (플레쉬 백 테크놀러지)
  리두 리두로그파일 아카이브 복구

  테이블 데이터(최신), 언두(이전), 리두(변경내역)
  3종류의 데이터

## 언두 관리
  순환사용됨
  테이블스페이스 설정, undo_management auto
  DML 에러 : 언두 공간이 더 이상 없을 때
    언두 공간 확보
    트렌젝션 종료를 빠르게함
  Select 에러
    sql tuning
    언두 공간확보
    undo retention 파라미터 설정

* 읽기 일관성
  명령이 시작된 시점의 데이터를 끝날때까지 보는것
  트렌젝션 수준의 읽기 일관성
  트렌젝션 시작된 시점의 데이터를 끝날때까지 보는것

* Undo 케이스
  쿼리 시작
  - 다른 세션이 DML 하고 커밋안함
    쿼리가 시작된 시점에 블럭의 SCN 을 보고 SCN 바뀐걸 보고 undo 를 가져옴
  - 다른 세션이 DML 하고 커밋함
    쿼리가 시작된 시점에 블럭의 SCN 을 보고 SCN 바뀐걸 보고 undo 를 가져옴 (여전히 undo 데이터를봄 - 쿼리가 시작한 시점의 데이터로 간주)
  - 다른 세션이 DML 하고 커밋하고 언두를 계속 다른애들이 이용, 전혀 다른 트렌젝션이 언두 공간을 재이용
    쿼리가 시작한 뒤 바뀐데이터는 옛날 언두 데이터를 보는데 바뀌어 있다. 쿼리가 에러남 ora-1555 snapshot too old (언두 데이터가 사라져서, 읽기 일관성을 유지 할수 없어서, 날린 쿼리가 너무 오래 수행되서 읽기 일관성을 유지하는 언두 공간이 사라져서)

* undo retention 파라미터
  언두 테이블스페이스의 익스텐츠 종류
  - 엑티브 익스텐츠 : 진행중인 트렌젝션이 있는 익스텐츠
  - 인엑티브 익스텐츠 : 커밋, 롤백 다 끝난 상태 공간을 보호하지 않음 (읽기 일관성 목적은 필요할수도 있지만...)
  자기가 있는 언두 세그먼트 공간이 전부 엑티브 한경우
  다른 세그먼트에 있는 인엑티브 익스텐츠의 공간을 스틸함 (읽기 일관성 보다 DML 을 우선으로 함)
  --이럴때!! ---
  undo retention 900 초라면 900초를 기준으로 900초보다 오래된 언두부터 주고 다 주고 나면 작은것도 줌 (순서대로 줌) 오래된 애들중엔 운에 따라서 줌
  1800초 가 가장긴 쿼리이면 최소 1800 초 후에 것만 가져갈수 있도록 함
  expired indextive extent 를 steal
  그래도 없으면 unexpired indextive extent
  (어린아이의 기준을 어떻게 줄것인지 18살 이하라고 하면 19살 이상부터어른 이런 기준 : undo retention 이 expired 의 기준)
  ALTER TABLESPACE undotbs1 RETENTION GUARANTEE;
    unexpired 를 steal 할수 없도록 함
    (읽기 일관성을 DML 보다 중요하게 여김)








_____
