
============================================
 12장 Database Maintenance 계속
============================================
DBA 의 가장 중요한 일!!! 백업 >>> 다음이 Optimizer stat 관리
Optimizer 여러가지를 생각해서 best 를 선택하는것
Optimizer Statistics 데이터베이스와 여러 데이터에 대해서 묘사하는 데이터의 덩어리

### Optimizer Statistics
  sql.bsq -> cat alog.bsql dba_ 테이블
  실시간 수집되지 않는다.
  dbms_ouput : 패키지소속 서브프로그램 확인
  dbms_stats
    set, put 계열
    gather, delete 계열
      .GATHER_DATABASE_STATS .GATHER_SCHEMA_STATS 등
      .gather_stats_job : 저녁 10시부터 아침 8시까지 자동으로 통계정보를 수집함
        수동 수집 -> .GATHER_TABLE_STATS('user', 'table')
  수동으로는 gater_.. 을 해야 수집함
  데이터가 현격하게 바뀔때 DBA가 수시로 해줌

  dba_tab_col_statistics 컬럼별 통계
    https://docs.oracle.com/cd/B19306_01/server.102/b14211/optimops.htm#i82005
    13.4.1.3 Estimating
    The estimator generates three different types of measures:
      selectivity : 선택도
      cardinality : 실행계획의 rows 데이터 딕셔너리의 옵티마이져 stats 를 계산해서 나옴 파스 단계에서 보이는 것
      cost : 실행계획의 cost
        RBO rule-based optimizer
          데이터의 상황도 모르고 통계값도 모르고 연산식이나 순서로 실행계획을 판단 =, >, 먼저오는 조건 등
        CBO cost-based optimizer

    모든 컬럼의 값은 고르게 분포되어 있다 (가정)
    가정이 맞지 안을 경우 극복을 위해 추가로 histogram 도 모음
    CBO(cost-based optimizer) 가
      최소한 4가지 이상의 실행계획을 계산해보고 가장 낮은 방법을 선택
      측정 방식
      > selectivity
        colum stats 확인
        empno = 65 1000 개의 데이터중에 1개면 0.001 %
        ename = 'mark' 동일 이름 1/500 0.002 %
        sal >= 1500 3000-1500+1/3000(최고가)-0+1(전범위) 0.5%
        이런식으로 연산을 해서 empno 로 index 에서 찾고 나머지 2개로 찾아 가져옴
      > cardinality
        선택도 * table 의 행수
        empno = 65 1000 개의 데이터중에 1개면 0.001 % * table's row#'
        colum stats 와 table stats 를 확인
          select * from emp e, salse s
          where empno = 65 and ename = 'mark' and sal >= 1500
          and s.empno = e.empno and sales_date = '2017.11.11'
        sales 데이터가 1억건 유일값 10000
        sales_date = '2017.11.11'  1/10000 = 0.0001 인데 table 행수를 곱하면 0.0001 * 1억 하면 훨씬 숫자가 커짐
        nested loops 출발은 emp -> 도착은 salse
        emp empno (pk) index -> salse 의 empno (fk) index 확인

  참고)
  http://adenkang.tistory.com/10
  http://wiki.gurubee.net/pages/viewpage.action?pageId=1343519
    # selectivity
      선택도 특정 조건을 만족할 확률을 말한다.
      {Adjusted Cardinatliy = Base Cardinality * Selectivity}의 공식을 따른다.
      Selectivity : "선택도"이다. 특정 조건(Predicate)을 만족할 확율이다. Selectivity는 Density와 달리 고정된 값이 아니라 조건에 따라 바뀌는 값이다. (Density는 1/NDV로 표현 Histogram이 없을 때는 무조건 Density는 1/NDV로 표현되지만, Histogram을 수집하게 되면 분포도를 고려한 Density가 Dictionary 정보에 입력된다.)
      만일, Column c1의 Density가 0.1이라고 하더라도 {c1 = 1 }, {c1 = :b1}, {c1 between 1 and 10 }, {c1 etween :b1 and :b2 } 조건의 Selectivity는 모두 다르다.

      NDV는 Number of Distinct Value의 약자로, 특정 Column에 unique한 값이 얼마나 있는지를 얘기하는 것이다. 예를 들면 A column에 값이 {1, 2, 3, 4, 5, 6, 7, 8, 9} 가 존재한다면 NDV는 9가 되는 것이다.
      dept = :b1 의 Selectivity는 1/NDV = 1/3 = 0.3333
      dept = :b1 or code = :b2의 Selectivity는 (1/3) + (1/3) - (1/3)*(1/3) = 0.555
      dept = :b1 and code = :b2의 Selectivity는 (1/3)*(1/3) = 0.111
      Selectivity는 Density와 유사한 이해가 되서 헷갈리는 개념이다. Density는 Column의 밀도를 계산한 것이라면 Selectivity는 predicate에 따라서 달라지는 값이다.

    # cardinality
      Cardinality는 집합의 크기를 의미한다.
      즉 집합에 속하는 원소의 수가 100개라면 { Cardinality(집합)=100 } 과 같이 표현된다. Tabel t1의 전체 Row수가 10,000개 라면 {Cardinality(t1) = 10000}이 된다.
      만일, Where t1.c1=1이라는 조건이 주어지고 해당 조건을 만족하는 Row수가 1,000개라면 {Cardinality(t1) = 1000}이 된다.

      Cardinality는 Selectivity * Number of Rows이다. 실제로 주어진 predicate에 의해서 추출되는 row 수를 의미한다.
      위의 예에서 dept = :b1의 Cardinality는 8*1/3 = 2.6 이 되는 것이다.

      정확한 Cardinality 예측은 Optimizer가 최적의 execution plan을 선택하는데 가장 중요한 요인이다.

  # Selectivity와 Cardinality

    Understanding Statistics
    http://docs.oracle.com/cd/B28359_01/server.111/b28274/stats.htm#i37048

    Understanding the Query Optimizer
    http://docs.oracle.com/cd/B28359_01/server.111/b28274/optimops.htm#i82005


===============================
 실행 계획에 익숙해지기
===============================

# access predicate vs filter predicate

  [orcl:~]$ . oraenv
  ORACLE_SID = [orcl] ? orcl

  [orcl:~]$ sqlplus / as sysdba
  SQL> startup force

  SQL> conn scott/tiger

  SQL> ed ind.sql

       set verify off

       col TABLE_NAME format a20
       col COLUMN_NAME format a30

       select table_name,
              column_name,
              index_name
       from user_ind_columns
       where table_name = '&1';

  SQL> @ind EMP

  SQL> set linesize 400
  SQL> set autot trace explain

  SQL> select * from emp
       where empno = 7788
       and sal >= 2000;

      Execution Plan
      ----------------------------------------------------------
      Plan hash value: 2949544139

      --------------------------------------------------------------------------------------
      | Id  | Operation                   | Name   | Rows  | Bytes | Cost (%CPU)| Time     |
      --------------------------------------------------------------------------------------
      |   0 | SELECT STATEMENT            |        |     1 |    87 |     2   (0)| 00:00:01 |
      |*  1 |  TABLE ACCESS BY INDEX ROWID| EMP    |     1 |    87 |     2   (0)| 00:00:01 |
      |*  2 |   INDEX UNIQUE SCAN         | PK_EMP |     1 |       |     1   (0)| 00:00:01 |
      --------------------------------------------------------------------------------------

      Predicate Information (identified by operation id):
      ---------------------------------------------------

         1 - filter("SAL">=2000)
         2 - access("EMPNO"=7788)

  *** 필터 조건을 엑세스 조건으로 튜닝

  SQL> create index emp_empno_sal_idx
      on emp(empno, sal);
  SQL> set autot off
  SQL> @ind EMP

      TABLE_NAME           COLUMN_NAME                    INDEX_NAME
    -------------------- ------------------------------ ------------------------------
    EMP                  EMPNO                          EMP_EMPNO_SAL_IDX
    EMP                  SAL                            EMP_EMPNO_SAL_IDX
    EMP                  EMPNO                          PK_EMP

  SQL> select empno, rowid from emp order by 1,2;
  SQL> select empno, sal, rowid from emp order by 1,2;
  SQL> select * from emp;
  -- 총 인덱스가 4개 empno, sal, rowid

  SQL> SET AUTOT TRACE EXPLAIN

  SQL> select * from emp
    where empno = 7788
    and sal >= 2000;

      Predicate Information (identified by operation id):
      ---------------------------------------------------

         2 - access("EMPNO"=7788 AND "SAL">=2000 AND "SAL" IS NOT NULL)

* 인덱스 탐색 방법
  쿼리
    select * from emp
    where deptno = 20
    and sal >= 2000;
  1000명의 20번 부서의 대부분의 사람이 월급이 2000이 안된다
  2명 존재
  > deptno 단일 인덱스라면
    index 테이블의 20번 rowid  1000 개를 찾음 (access)
    emp 테이블에 가서 20번 부서의 사원들을 하나하나 찾아서 sal 정보를 봄 (filter)
  > deptno, sal 복합 컬럼 인덱스라면
    index 테이블에 20번 rowid 1000 개 중 sal >= 2000 인 2개의 rowid 를 찾아 emp 테이블에서 가져옴
    필터를 사용하지 않는다.


==============================
  튜닝 보고서 (예시)
==============================
  1.증상

    다음 쿼리가 16초 수행되었다.

    SQL> select * from emp
         where deptno = 20
         and sal >= 2000;

  2.분석

    선택도가 넓은 deptno만 액세스 조건으로 사용되고
    선택도가 좁은 sal이 필터 조건으로 사용되어 시간이
    필요이상으로 소용됨을 확인했다.

    Predicate Information (identified by operation id):
    ---------------------------------------------------

       1 - filter("SAL">=2000)
       2 - access("EMPNO"=7788)

  3.튜닝

    선택도가 좁은 sal이 액세스 조건으로 사용될 수 있도록
    인덱스의 구조를 수정했다.

     SQL> create index emp_empno_sal_idx
         on emp(empno, sal);

    그로 인행
    실행 계획이 ... 바뀌었고
    수행 시간이 ... 줄었다.



### Performance Statistics
  v$

==============================
  ### STATISTICS 분류
==============================
> 옵티마이져가 일을하는데 사용하는 Statistics

 o Optimizer Statistics : DBA_***  -> 노력하세요 -> DBMS_STATS 패키지 -> 11gNF : gather_stats_job
    gather_stats_job (주기적으로 자동으로 optimizer stats 를 수집)

  	~ Database stats : Table, column, Index (스키마, 전체 DB .. 단위) - 내부

  	    o GATHER_DATABASE_STATS : 현실성이 없음
          exec dbms_stats.set_table_prefs('SH','SALES','STALE_PERCENT','13'); 현실성을 갖게 해줌 새로생긴 기능
          하나하나 테이블 마다 특징을 속성처럼 잡아줌
          테이블 단위로 속성을 지정해줌
  	    o GATHER_DICTIONARY_STATS
  	    o GATHER_FIXED_OBJECTS_STATS
  	    o GATHER_SCHEMA_STATS
  	    o GATHER_TABLE_STATS
  	    o GATHER_INDEX_STATS

  	~ System stats : IO, CPU 에 관한 정보 - 외부

  	    o GATHER_SYSTEM_STATS

 o Performance Statistics : V$***   -> 즐기세요    -> 누적,휘발 문제
                                                        * 극복 -> user-managed snapshot
                                                              -> utlbstat.sql 및 utlestat.sql
                                                              -> statspack
                                                              -> 11gNF : AWR + MMON + ADDM,ASH
                                                                      저장소 + 수집가 + 분석가
  .
      * 종류
        ~ Activity : v$statname, v$sysstat, v$sesstat, v$mystat
          > 했던 행위들에 대한 지표
      	~ Wait     : v$event_name, v$system_event, v$session_event, v$session(v$session_wait)
          > 내가 알고 싶은 지점의 변수값 확인 같이 기다림들이 있는 곳의 수치들
      	~ Others   : v$latch, v$lock, v$sgastat, v$pgastat, v$sql, v$libarycache, v$filestat, ...
          > 이상징후가 있을때 봐야 하는 지표들


  * v$ 의 문제는 휘발성, 누적
  * v$ 의 문제 해결
    - user-managed snapshot : 그때 그때 v$ 값들을 저장하는 다른 테이블을 만들어 둠, 사용자가 쿼리 만들고 파일 만들어서 사용
      할일이 많지만 유연함
      셋업, 스냅샷, 분석 다 해야함
    - utlbstat.sql 및 utlestat.sql : 오라클에서 제공하는 쿼리로 그때 그때 수치값을 파일로 저장
      편하긴 하나 명백한 일정한 이슈가 있을때만 대응가능 (예-새로운 어플을 붙일때 전후), 다른 관점으로 분석을 하고 싶을때 원데이터가 없어 문제가 됨, 보고서 해석이 쉽지 않음
      셋업, 스냅샷은 해주고 분석은 해야함
    - statspack : 일정시간에 한번씩 수동이든 자동이든 스냅샷을 찍을 수 있다.
      셋업, 스냅샷은 해주고 분석은 해야함
    - 11gNF : AWR + MMON + ADDM,ASH : 비용이 많이 듬
      셋업, 스냅샷, 분석까지 해줌
  * activity, wait 는 늘 주시하는 지표 늘 발생하는 것들
  * baseline (정상일때의 기준치:사람의정상혈압) 을 만들어 두면 정해진 시간이 지나도 스냅샷이 지워지지 않는다.
    basic, typical, all
  * Metric : Performance stats 의 누적 상태를 단위시간을 줘서 (유저당...) 분해함 주요 공간 사용량, 누적 통계의 변화율
  * Threshold : metric 값이 비교되는 경계 값 임계점
  * cost 모델 : 옵티마이져가 가장 효울적인 경로를 결정하는데 사용되는 알고리즘 (표현식 및 조건, 객체 및 시스템통계, 데이터액세스방법, 테이블조인방법 등을 가지고 정함)

  * job = what + when (program + schedule)
    gather_stats_prog
    dbms_stats.gather_stats_prog 프로시저에 안에 ...
    gather_stats_job
  * statictics_level 를 typical 또는 all 로 선언하면 optimizer statistics 자동화 기능이 켜짐 (basic 자동화 끄기)

  * SQL> EXEC dbms_stats.gather_system_stats('NOWORKLOAD');
    workload, NOWORKLOAD

  * awr 은 sys 꺼 (sysman 아님)
  * AWR 안에 MMON(수집가) 이 자동으로 스냅샷을 찍어주고 있음
    oracle은 C 언어, SGA 메모리 구조체
  * ADDM(분석가) : 클라이언트 내부에서 신경쒀줘야 하는 프로세스
    awr 스냅샷 생성 후 마다 실행되어
    instance 모니터링하고 병목 지점을 잡아주기도 하고 결과를 저장
    ADDM 결과 : Impact 가 100% 가 아닌 이유 지속적인 영향도 띄엄띄엄 순간순간 영향을 준 영향도 등으로 보면됨

  * Advisory : 가상으로 메모리를 줄이면 어떻게 될지 늘리면 어떻게 될지에 대한 시뮬레이션 값을 가지고 있다.
    예) shared pool advisor : 현재 pool 을 늘렸을때 주렸을때의 결과를 가지고 있음

  * SQL Advisor (java 의 drive class(메인이 있는 클래스) 같이 다른 함수를 사용해서 동작함)
    권고 사항(4가지 + 기타)
      optimizer statistics 을 다시 수집해라 통계가 정확한지
      turn sql plan (sql profile)
      index 새로운 인덱스를 생성해야 하는지
      restructure sql SQL 구문의 튜닝이 필요한지
  * CBO (optimizer) -> STA (SQL Turning Advisor) : CBO 가 잡지 못한 것들은 STA 가 잡아줌, SAT 는 자기한테 넘어온 문장을 CBO 를 튜닝 모드로 바꾸고 문장을 넘겨줌 다시 CBO 에서 결과를 받아서 처리 (결국 일하는건 optimizer)
  * 옵티마이져
    - normal : 빠른결정: optimizer stats, index, 대안적 저장구조, ... 확인사항 들이 잘 되어있든 안되어 있든 따지지 않고 판단함
    - tuning (ato) : 튜닝모드
    - 확인사항
      > optimizer stats 다이나믹 샘플링 현재 순간에 아주 소량만 꺼내어서 확인 실제 데이터와 많이 바뀌었는지 확인
      > index invisible CBO 가 고려하지 않는 인덱스 이 세션에서 만큼은 invisible 인덱스도 고려하도록 alter 시킴
      > SQL profile (Hint 의 모음)
      ...
  * SAA (SQL Access Advisor)
    테이블이나 인덱스에 대한 권고
    튜닝데상 문장을 한거번에 CBO 한테 받으면 STA 는 한개씩 권고를 하는데 전체적으로 성능이 좋아 지는 것은 아니다.
    SAA 는 권하는건 몇개 없는데 전체가 좋아 질 수 있는 해법을 제시한다.
    하나하나에 대한 깊은 권고를 하지는 않는다.
  * 11g 에서 자동화 된 (개입해서 보지 않아도, 자동 sql 튜닝이 알아서 잘하다가 잘 안될때만, 메모리 총량만 주고 경고만 받고 총량만 재조정을 해줌)

  user managed 백업 복구

  * GIYF google is your friend
    RTFM 메뉴얼을 읽어라
    BAAG 이럴꺼야 라고 짐작한건 다 틀렸다
