


============================================
 11장 오라클 데이터베이스 감사(audit) 구현
============================================

- Mandatory auditing          : alert_SID.log, ?/rdbms/audit
- Standard database auditing  : audit_trail 파라미터 및 audit 명령
- Value-based auditing        : 트리거
- Fine-grained auditing (FGA) : dbms_fga 패키지
- DBA auditing                : sys 감사


### Mandatory auditing
  너무 중요해서 따로 이야기를 안해도 남는 파일
  - alert_SID.log : 행동에 대한 중요한 에러들
  - ?/rdbms/audit : 로그인한 기록이 남음

### Standard database auditing
  audit_trail 파라미터 및 audit 명령
  (이번챕터의 가장중요한 부분)
  뭔가 의심스러울때
  누가 언제 어떤작업을 한지는 알 수 있음
  BUT! 어떤 작업을 했는지 구체적인 내용은 보기 힘듬

  # Standard database auditing

    [oracle@ora11gr2 audit]$ export ORACLE_SID=prod
    [oracle@ora11gr2 audit]$ sqlplus / as sysdba
    SQL> show parameter audit_trail

  	NAME                                 TYPE        VALUE
  	------------------------------------ ----------- ------------------------------
  	audit_trail                          string      NONE

    SQL> alter system set audit_trail=db scope=spfile;
      -- 스테닉 파라미터 두가지를 하면 감사 모드가 됨 (감사준비)
    SQL> startup force

    -- SQL 명령어 로 설정
    SQL> audit table;               --> Statement auditing
      -- table 이라는 명령어가 들어가는 명령어 감사
    SQL> audit select any table;    --> System-privilege auditing
      -- 권한을 주면 감사해라
    SQL> audit update on phi.t1;    --> Object-privilege auditing
      -- 객체 감사

    SQL> conn system/oracle
    SQL> create table t2012 (no number);
      -- 이 명령의 기록이 남음
    SQL> select * from phi.t1;
      -- 남의 테이블을 막 질의함 객체 권한에 걸림
    SQL> update phi.t1 set c2=200 where c1=2001;
    SQL> commit;

    - Query로 확인하세요.

      select * from DBA_AUDIT_OBJECT;
      select * from dba_audit_trail;

    SQL> conn / as sysdba

    -- 감사 기능 해제
    SQL> noaudit table;
    SQL> noaudit select any table;
    SQL> noaudit update on phi.t1;
    -- 감사 기능 모드에서 빠져나옴
    SQL> alter system set audit_trail=none scope=spfile;
    SQL> startup force


### Value-based auditing
  트리거
  어떤 작업을 했는지 구체적인 내용은 보기 힘든 점을 보안
  테이블의 해당 컬럼을 업데이트를 하고나면 begin - end 가 돌아감
  사용자, 시간, 컬럼, 변경내용 등 남김


### Fine-grained auditing (FGA)
  dbms_fga 패키지
  정책을 정함
  포커스를 더 좁힘
  Defines:
    – Audit criteria
    – Audit action
  DBMS_FGA.ADD_POLICY
    예) audit_condition=> 'department_id=10' 10번부서이면
  구체적인 조건에 해당하면 기록을 남겨라


### DBA auditing
  sys 감사
  sys user 가 하는행위는 기본적으로 감사대상이 아님
  AUDIT_SYS_OPERATIONS = true 로 설정
  open 이 되어야만 감사 기록을 남길 수 있는데 sys 는 반듯이 db 밖에 os file 에 남도록 해야함
  AUDIT_FILE_DEST 위치에 지정해줌

* 감사가 실패하면 감사대상이 실패
  예) 권한 감사 Create session >
  system tablespace 에 aud$ 기록됨
  혹시 감사 설정을 하고 관리를 못해서 aud$ 가 꽉차면 aud$ 공간이 커짐
  system tablespace 에 공간을 다 차지해버리면
  해당 권한에 대한 Create session 감사 기록을 남길수 없고 아애 접속이안됨
    해결> sys가 하는 일은 감사 대상이 아니기 때문에 sys 는 로그인이 되기때문에 sys로 접속해서 공간을 비우거나 늘려줌


============================================
 12장 Database Maintenance
============================================

# 용어

  o Performance?

  o Tuning?

  o Server Tuning?

	(진단 결과를 해석할 능력이 있으면서)
	목표에 맞는 Performance가 발휘되도록
	시스템의 여러 요소를 조절해 가는 과정

  전제 조건들
    1. 최소한의 HW 사양
    2. 부하이 분산
    3. 최소한의 SQL Tuning

  o SQL Tuning?

	(특정 SQL이 처리되는 가장 좋은 경로를 알고 있으면서)
	optimizer가 최적의 실행계획을 선택하도록 유도하는 과정.

	- optimizer statistics 관리 : dbms_stats 패키지
	- index                     : 생성과 활용
	- 대안적 저장구조            : partitioned table, clustered table, IOT, MView ...
      일상의 대부분은 데이터는 클러스터링 되어 있다.(분류)
      저장 구조를 변경해서 찾는 유저의 요구를 쉽게 찾을 수 있도록 구조를 새로 만듬
  - 파라미터                   : optimizer_*** 및 일반 파라미터
	- Hint                      : Good, Gray, Bad 같은 분류를 하기도 합니다. : http://goo.gl/y23g8
      참고하되 최선을 찾아서 실행계획을 선택한다.
	- SQL 재작성                : 꾸준한 SQL 작성 능력 향상 계획이 필요합니다.
	- 기타                      : STA, SAA, TCF, Stored outline, SQL Profile ...

  (* index, hashing : 많은데이터에서 빠르게 찾는 방법)

## SQL Tuning 실습
  sql 문이 어떻게 하면 더 빨리 수행할 수 있을지
  최적의 실행계획을 선택하도록 유도하는 과정

  # Autotrace 기능 설정

    [orcl:~]$ . oraenv
    ORACLE_SID = [orcl] ? orcl

    [orcl:~]$ sqlplus / as sysdba
    SQL> startup force

    SQL> set autot on
    SP2-0618: Cannot find the Session Identifier.  Check PLUSTRACE role is enabled
    SP2-0611: Error enabling STATISTICS report

    해결하기>
    SQL> get ?/sqlplus/admin/plustrce.sql
       19  set echo on
       20  drop role plustrace;
       21  create role plustrace;
       22  grant select on v_$sesstat to plustrace;
       23  grant select on v_$statname to plustrace;
       24  grant select on v_$mystat to plustrace;
       25  grant plustrace to dba with admin option;
     SQL> sta ?/sqlplus/admin/plustrce.sql

     SQL> grant plustrace
          to public;

     SQL> alter user scott
          identified by tiger
          account unlock;

     SQL> alter user sh
          identified by sh
          account unlock;

  # Scott 유저로 확인
    SQL> conn scott/tiger

    SQL> set timing on
    SQL> set autotrace on

    SQL> select *
         from emp
         where empno = 7788;

  # SH 유저로 확인
    SQL> conn sh/sh

    SQL> set timing on
    SQL> set autotrace on

    SQL> select CUST_FIRST_NAME,
                CUST_LAST_NAME
         from customers
         where CUST_FIRST_NAME like 'K%';

          1470  consistent gets

    SQL> save t001.sql

    SQL> select count(*)
    from customers;

    SQL> desc user_indexes

    SQL> ed ind.sql

      select  table_name,
              column_name,
              index_name
      from user_indexes
      where table_name = '&1';

    SQL> @ind CUSTOMERS

    SQL> create index cust_first_name_idx on customers(cust_first_name);

    -- 인덱스를 만들고 수행하면 사용 데이터 블럭이 줄어듬
    SQL> @t001

         127  consistent gets

    SQL> select /*+ full(c) */
                CUST_FIRST_NAME,
                CUST_LAST_NAME
         from customers c
         where CUST_FIRST_NAME like 'K%';

    select CUST_FIRST_NAME, CUST_LAST_NAME, s.quantity_sold, s.amount_sold
    from sales s, customers c
    where s.cust_id=c.cust_id and c.cust_first_name like 'K%';

  # 조인 문장 테스트

    SQL> select count(*)
         from sales;

    SQL> select c.CUST_FIRST_NAME,
                c.CUST_LAST_NAME,
                s.quantity_sold,
                s.amount_sold
         from sales s, customers c
         where s.cust_id = c.cust_id
         and   c.CUST_FIRST_NAME like 'K%';

         1944  consistent gets

    SQL> save t002.sql

    SQL> @ind SALES

    SQL> create index sales_cust_id_idx
         on sales(cust_id);

         => 에러 발생 : ORA-01408: 열 목록에는 이미 인덱스가 작성되어 있습니다

    SQL> create index sales_cust_id_idx
         on sales(cust_id, quantity_sold, amount_sold);

    SQL> @t002

         => 실행 계획에 변화가 없을 수 있습니다.

    SQL> alter session set optimizer_mode = first_rows_1;
    SQL> @t002

                418  consistent gets

        ------------------------------------------------------------
        | Id  | Operation                    | Name                |
        ------------------------------------------------------------
        |   0 | SELECT STATEMENT             |                     |
        |   1 |  NESTED LOOPS                |                     |
        |   2 |   TABLE ACCESS BY INDEX ROWID| CUSTOMERS           |
        |*  3 |    INDEX RANGE SCAN          | CUST_FIRST_NAME_IDX |
        |*  4 |   INDEX RANGE SCAN           | SALES_CUST_ID_IDX   |
        ------------------------------------------------------------

    SQL> alter session set optimizer_mode = all_rows;
    SQL> @t002

               1944  consistent gets

        ------------------------------------------------------------
        | Id  | Operation                    | Name                |
        ------------------------------------------------------------
        |   0 | SELECT STATEMENT             |                     |
        |*  1 |  HASH JOIN                   |                     |
        |   2 |   TABLE ACCESS BY INDEX ROWID| CUSTOMERS           |
        |*  3 |    INDEX RANGE SCAN          | CUST_FIRST_NAME_IDX |
        |   4 |   PARTITION RANGE ALL        |                     |
        |   5 |    TABLE ACCESS FULL         | SALES               |
        ------------------------------------------------------------

    옵티마이져 모드를 first_rows_1 로 하면
      nested loop 이용
      나도 인덱스 상대방도 인덱스로 조인
    옵티마이져 모드를 all rows 로 변경하면
      hash join 으로 변경되어 있음
      나는 인덱스 상대방은 테이블 전체로 조인함

    Join의 방식은 3가지가 있습니다.
      Nested Loop Join - 중첩반복
      Merge Join - 정렬병합
      Hash Join - 해시매치
      출처: http://sonim1.tistory.com/108 [피와 살이되는 블로그]



  # optimizer statistics
  Optimizer Statistics(옵티마이저 통계)는 데이터베이스 모든 오브젝트에 대한 자료를 모아 기술한 통계
  딕셔너리(Data Dictionary)에 저장되며 이 통계정보를 바탕으로 오라클 옵티마이저는 SQL문장 실행을 위한 효율적인 실행계획을 만들어 낸다.

    SQL> set autotrace off

    -- 수집할 당시의 ROW개수 | 소비한블럭개수 | 사용안한블럭 | 평균여유공간 | 마이그레이션이나체인이일어난수
    SQL> select table_name, NUM_ROWS, BLOCKS, EMPTY_BLOCKS,
                AVG_SPACE, CHAIN_CNT, AVG_ROW_LEN
         from user_tables
         order by 1;

    SQL> alter session set optimizer_mode = all_rows;
      -- all_rows 를 수행하면 nested loop 이 실행됨

    SQL> exec dbms_stats.delete_schema_stats(user)
      --  optimizer statistics 가 삭제됨

    SQL> @t002

         NESTED LOOPS

    SQL> exec dbms_stats.gather_schema_stats(user)
      --  optimizer statistics 가 생성

    SQL> @t002

         NESTED LOOPS

    SQL> select /*+ use_hash(s, c) */
                c.CUST_FIRST_NAME,
                c.CUST_LAST_NAME,
                s.quantity_sold,
                s.amount_sold
         from sales s, customers c
         where s.cust_id = c.cust_id
         and   c.CUST_FIRST_NAME like 'K%';


    * Hint
      /*+ full(tablename) */ full table 스캔해라(권고)


-- Consistent Gets – a normal reading of a block from the buffer cache. A check will be made if the data needs reconstructing from rollback info to give you a view consistent at a point in time {so it takes into account your changes and other people’s changes, commited or not) but most of the time a reconstruction is not needed, The block is just got from the cache.





_____
