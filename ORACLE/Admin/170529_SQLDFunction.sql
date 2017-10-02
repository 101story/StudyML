


▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒                                            ▒
▒ Analytic Functions and Their Uses          ▒
▒                                            ▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒

====================================
 [0] Analytic Function 소개
====================================

 # http://docs.oracle.com/cd/E11882_01/server.112/e25554/analysis.htm#i1007779

 - Analytic Function과 SQL Model은 첫번째 쿼리 결과를 이용해서 다음 처리를
   수행한다는 점에 비슷하다. 이점은 subquery factoring도 그렇다.

 - Processing order

   Query processing using analytic functions takes place in three stages.
   First,  all joins, WHERE, GROUP BY and HAVING clauses are performed.
   Second, the result set is made available to the analytic functions, and all their calculations take place.
   Third,  if the query has an ORDER BY clause at its end, the ORDER BY is processed to allow for precise output ordering.

 - 종류

   Ranking :

	RANK, DENSE_RANK, ROW_NUMBER
	NTILE, CUME_DIST, PERCENT_RANK

   Windowing :

	SUM, AVG, MIN, MAX, COUNT, VARIANCE, STDDEV, and new statistical functions.
	FIRST_VALUE, LAST_VALUE

   Reporting :

	SUM, AVG, MIN, MAX, COUNT, VARIANCE, STDDEV, and new statistical functions.
	RATIO_TO_REPORT

   LAG/LEAD :

	LAG
	LEAD

   FIRST/LAST :

	FIRST_VALUE
	LAST_VALUE
	NTH_VALUE   : 11gR2_NF

   LISTAGG Function : 11gR2_NF

   FIRST/LAST Functions

   Inverse Percentile      : 생략
   Hypothetical Rank       : 생략
   Linear Regression       : 생략
   Statistical Aggregates  : 생략
   User-Defined Aggregates : 생략

   WIDTH_BUCKET Function

   Partition Join Syntax   : 10gNF
   (Partitioned Outer Join)

   Pivoting Operations     : 11gR1

/**  SQL Developer 시험 대비 **/
==============================
SQL for Analysis and Reporting
==============================
* 분석함수 해석
  1. where, group by, having 까지 먼저 수행되고
  2. 그 결과 받아서 Analytic Functions 이 수행되고
  3. 문장의 마지막 order by 가 수행됨

* Analytic Functions
- Windowing   범위 (3일 이동평균?)
- Reporting   Windowing 과 비슷
- LAG/LEAD
- FIRST/LAST  나바로위? 를 옆에 둠

## Ranking Function
* rank() over (order by col desc) : 랭킹 순위를 구해줌 (동률은 한번 생략하고 1,2,2,4)
* dence_rank() over (order by col desc) : 동률 처리 (1,2,2,3)
* row_number() over (order by col desc) : 동률 없이 순서대로 순위 처리 (1,2,3,4)

* partition by 데이터를 나누어라
  break on deptno skip 1 -- 부서 번호 1번만 출력하기
  RANK() OVER (PARTITION BY deptno ORDER BY sal DESC) : deptno 부서별로 로 나눈뒤 rank 를 수행해라

* NTILE : 1/n 해서 얘가 어디쯤에 있는지
  파티션별 전체 건수를 argument 값으로 n 등분한 결과이다.
  정확하게 나누어 떨어지지 않을 경우 앞쪽 구간에 로우를 할당한다.
  http://docs.oracle.com/cd/E11882_01/server.112/e25554/analysis.htm#autoId7
* CUME_DIST : 누적백분률
  파티션별 전체 건수에서 현재 행보다 작거나 같은 건수에 대한 누적 백분율을 구한다.
  The range of values for CUME_DIST is from greater than 0 to 1.
  http://docs.oracle.com/cd/E11882_01/server.112/e25554/analysis.htm#autoId5  --> row counts  : dense_rank
* PERCENT_RANK : 0~1 까지의 순위별 백분률
  파티션별 윈도우에서 제일 먼저 나오는 것을 0으로, 제일 늦게 나오는 것을 1로 하여, 순위별 백분율을 구한다.
  PERCENT_RANK returns values in the range zero to one.
  http://docs.oracle.com/cd/E11882_01/server.112/e25554/analysis.htm#autoId6  --> rank values : dense_rank


## Windowing
order by 의 유

  누적합
  * rows 2 pretanding(following) : 이동 누적합 (나랑 내앞의 2개, 3개의 누적합)

  * range 2 : 나를 기준으로 위아래 2 (범위)

  * 서브쿼리펙터링
    with t as (select * from emp)
    selet ...

## Reporting
order by 의 무

  스칼라서브쿼리 : 딱 한건씩 나오는
  select deptno, ename, sal, (selec sum(sal) from emp) as 총계 from emp;

  select deptno, ename, sal,
    sum(sal) over (partition by deptno order by sal desc, ename) as sum1
  from emp;

  select deptno, ename, sal,
    avg(sal) over () as 전체평균,
    avg(sal) over (partition by deptno) as 부서별평균
  from emp;


-----------------------------------
> RANK, DENSE_RANK, ROW_NUMBER    <
-----------------------------------

# 문제 : 부서별 상위 3위까지 구하세요.

select deptno, empno, ename, sal
from emp
order by sal desc;

select deptno, empno, ename, sal,
       rank()       over (order by sal desc) as rank
from emp;

select deptno, empno, ename, sal,
       rank()       over (order by sal desc) as rank,
       dense_rank() over (order by sal desc) as dense_rank
from emp;

select deptno, empno, ename, sal,
       rank()       over (order by sal desc) as rank,
       dense_rank() over (order by sal desc) as dense_rank,
       row_number() over (order by sal desc) as row_number
from emp;


select deptno, empno, ename, sal,
       rank()       over (partition by deptno
                          order by sal desc)        as rank,
       dense_rank() over (partition by deptno
                          order by sal desc)        as dense_rank,
       row_number() over (partition by
                          deptno order by sal desc) as row_number
from emp;


create or replace view v1
as
select deptno, empno, ename, sal,
       rank()       over (partition by deptno
                          order by sal desc)        as rank,
       dense_rank() over (partition by deptno
                          order by sal desc)        as dense_rank,
       row_number() over (partition by
                          deptno order by sal desc) as row_number
from emp;

select * from v1;

break on deptno skip 1

select * from v1;

select * from v1 where rank       <= 3;
select * from v1 where dense_rank <= 3;

      ---------

# Null 값이 포함된 경우

  - NULLs are treated like normal values.
  - Also, for rank computation, a NULL value is assumed to be equal to another NULL value

select deptno, empno, ename, sal, comm
from emp
order by comm desc;

select deptno, empno, ename, sal, comm
from emp
order by nvl(comm, -1) desc;

   --

select deptno, empno, ename, sal, comm, rank() over (order by comm desc) as rank
from emp;

select deptno, empno, ename, sal, comm, rank() over (order by comm desc nulls last) as rank
from emp;

------------------------------------
>  NTILE, CUME_DIST, PERCENT_RANK  <
------------------------------------

   drop table t1 purge;

   create table t1
   as
   select level as no
   from dual
   connect by level <= 10;

   select no, ntile(2) over (order by no) as ntile2,
              ntile(4) over (order by no) as ntile4
   from t1;

   select no, ntile(1) over (order by no) as ntile1,
              ntile(2) over (order by no) as ntile2,
              ntile(3) over (order by no) as ntile3,
              ntile(4) over (order by no) as ntile4,
              ntile(5) over (order by no) as ntile5,
              ntile(6) over (order by no) as ntile6,
              ntile(7) over (order by no) as ntile7,
              ntile(8) over (order by no) as ntile8,
              ntile(9) over (order by no) as ntile9,
              ntile(10) over (order by no) as ntile10
    from t1;

    select no, cume_dist()    over (order by no) as cume_dist,
               percent_rank() over (order by no) as precent_rank
    from t1;

    ==> 함수 결과를 이해해 봅시다.

    select 1/10, 1/9 from dual;

    select no, c, p, no*c, no*p
    from (select 1/10 c, 1/9 p from dual) a,
         (select level as no from dual connect by level <= 10) b;

(1) 사원 전체를 대상으로

    clear break

    select deptno, empno, ename, sal
    from emp
    order by sal desc;

    select deptno, empno, ename, sal, cume_dist()    over (order by sal desc) as cume_dist,
                                      percent_rank() over (order by sal desc) as precent_rank
    from emp;

    ==> 함수 결과를 이해해 봅시다.

    select 1/14 c, 1/13 p from dual;

    select no, c, p, no*c, no*p
    from (select 1/14 c, 1/13 p from dual) a,
         (select level as no from dual connect by level <= 14) b;

(2) 부서별로 나누어서

    break on deptno skip 1

    select deptno, empno, ename, sal, cume_dist()    over (partition by deptno order by sal desc) as cume_dist,
                                      percent_rank() over (partition by deptno order by sal desc) as precent_rank
    from emp;

    clear break

========================================
 [2] Windowing과 Reporting
========================================

   - Windowing : order by [windowing_clause]가 있는 경우, partition by는 옵션
     Reporting : order by [windowing_clause]가 없는 경우, partition by는 옵션

   - Windowing과 Reporting 공통

	SUM, AVG, MIN, MAX, COUNT,
	VARIANCE, STDDEV,
	and new statistical functions.

   - Windowing 전용

	FIRST_VALUE, LAST_VALUE

   - Reporting 전용

	RATIO_TO_REPORT


[예제 1 : SUM 함수]

◆ Reporting

select deptno, ename, sal
from emp;

select deptno, ename, sal, (select sum(sal) from emp) as 총계
from emp;

select deptno, ename, sal,
       sum(sal) over () as 총계,
       sum(sal) over (partition by deptno) as 부서총계
from emp;

◆ Windowing

clear break

select deptno, ename, sal,
       sum(sal) over (order by sal desc, ename) as sum1
from emp;

select deptno, ename, sal,
       sum(sal) over (order by sal desc, ename
                      rows 2 preceding) as sum1
from emp;

   --

break on deptno skip 1

select deptno, ename, sal,
       sum(sal) over (partition by deptno
                      order by sal desc, ename) as sum1
from emp;

select deptno, ename, sal,
       sum(sal) over (partition by deptno
                      order by sal desc, ename
                      rows 2 preceding) as sum1
from emp;


[예제 2 : AVG 함수]

◆ Reporting

clear break

select deptno, ename, sal,
       avg(sal) over () as 전체평균,
       avg(sal) over (partition by deptno) as 부서별평균
from emp;

  cf.Scalar subquery로도 쉽게 구할 수 있습니다.

     select deptno, ename, sal,
            (select avg(sal) from emp) as 전체평균,
            (select avg(sal) from emp where deptno = e1.deptno) as 부서별평균
     from emp e1
     order by deptno;

◆ Windowing

clear break

select deptno, ename, sal,
       avg(sal) over (order by sal desc, ename) as avg1
from emp;

break on deptno skip1

select deptno, ename, sal,
       avg(sal) over (partition by deptno
                      order by sal desc, ename) as avg1
from emp;

select deptno, ename, sal,
       avg(sal) over (partition by deptno
                      order by sal desc, ename
                      rows 2 preceding) as avg1
from emp;

문제 : 주가를 분석해서 3일 이동평균을 구하세요.

     drop table t1 purge;
     create table t1
     as
       select decode(mod(level, 15), 0, 15, mod(level, 15)) as no,
              case when level <= 15 then 'A'
                   when level <= 30 then 'B'
                   when level <= 45 then 'C'
              end as stock,
              to_date('20111201') + mod(level - 1, 15) as day,
              round(dbms_random.value(100, 150)) as price
       from dual
       connect by level <= 45;

     select stock, no, day, price
     from t1;

     break on stock skip 1
     col stock format a10

     select stock, no, day, price, avg(price) over (partition by stock
                                                    order by day range 2 preceding) as "3일 이동 평균"
     from t1;

     col stars format a60

     with t as (
                select stock, no, day, price, avg(price) over (partition by stock
                                                               order by day range 2 preceding) as day3
                from t1)
     select stock, no, day, price, day3, rpad('*', round(day3/5), '*') as stars
     from t;


[예제 3 : MAX, MIN 함수]

◆ Reporting

break on deptno skip 1

select deptno, ename, sal,
       max(sal) over () as 전체최대,
       max(sal) over (partition by deptno) as 부서별최대,
       min(sal) over () as 전체최소,
       min(sal) over (partition by deptno) as 부서별최소
from emp;

clear break

◆ Windowing

select deptno, ename, sal,
       max(sal) over (order by sal desc) as 전체최대,
       min(sal) over (order by sal desc) as 전체최소     --> 엉터리 : Window의 개념을 읽어봅시다. : http://goo.gl/zOTtR
from emp;

select deptno, ename, sal,
       max(sal) over (order by sal desc) as max1,
       min(sal) over (order by sal desc) as min1,        --> 엉터리
       min(sal) over (order by sal)      as min2,        --> 제대로
       min(sal) over ()                  as min3         --> 제대로
from emp;

break on deptno skip1

select deptno, ename, sal,
       max(sal) over (partition by deptno
                      order by sal desc)   as max1,
       min(sal) over (partition by deptno
                      order by sal)        as min1,
       min(sal) over (partition by deptno) as min2
from emp;

select deptno, ename, hiredate, sal,
       max(sal) over (partition by deptno
                      order by hiredate
                      rows 2 preceding) as max1,
       min(sal) over (partition by deptno
                      order by hiredate
                      rows 2 preceding) as min1
from emp;


[예제 4 : COUNT 함수]

◆ Reporting

break on deptno skip 1

select deptno, ename, sal, hiredate,
       count(*) over () as count1,
       count(*) over (partition by deptno) as count2
from emp;

clear break

◆ Windowing

select deptno, ename, sal, hiredate,
       count(*) over (order by hiredate) as count1
from emp;

break on deptno skip1

select deptno, ename, sal, hiredate,
       count(*) over (partition by deptno
                      order by hiredate) as count1
from emp;

select deptno, ename, sal, hiredate,
       count(*) over (partition by deptno
                      order by hiredate
                      rows 2 preceding) as count1
from emp;

-- 각 사원을 기준으로 최근 100일 입사자수
select deptno, ename, sal, hiredate,
       count(*) over (partition by deptno
                      order by hiredate
                      range 100 preceding) as count1
from emp;

clear break

col range format a15

-- 각 사원을 기준으로 본인의 급여보다 50이하 적거나 150이하로 많은 급여를 받는 사원수를 나타내세요.
select deptno, ename, sal, (sal - 50)||' ~ '||(sal + 150) range,
       count(*) over (order by sal
                      range between 50 preceding and 150 following) as count1
from emp;


[예제 5 : FIRST_VALUE, LAST_VALUE 함수]
 > 숫자가 아니여도 가능

◆ Reporting

break on deptno skip 1

select deptno, ename, sal,
       first_value(sal) over () as fv1,                      --> 결과를 보면 Windowing이 필요한 이유를 알 수 있다.
       first_value(sal) over (partition by deptno) as fv2
from emp;

clear break

  cf.Scalar subquery로도 쉽게 구할 수 있습니다.

     select deptno, ename, sal,
            (select min(sal) from emp) as fv1,
            first_value(sal) over (partition by deptno) as fv2
     from (select deptno, ename, sal
           from emp
           order by deptno, sal) t;

◆ Windowing

break on deptno skip 1

select deptno, ename, sal,
       first_value(sal) over (order by sal) as fv1,
       first_value(sal) over (partition by deptno order by sal) as fv2,
       last_value(sal)  over (order by sal) as lv1,                     --> 버그 : http://gseducation.blog.me/20095625332
       last_value(sal)  over (partition by deptno order by sal) as lv2  --> 버그
from emp
order by deptno, sal;

select deptno, ename, sal,
       last_value(sal) over (order by sal range between unbounded preceding and unbounded following) "회사최고",
       last_value(sal) over (order by sal desc range between unbounded preceding and unbounded following) "회사최저",
       last_value(sal) over (partition by deptno order by sal range between unbounded preceding and unbounded following) "부서최고",
       last_value(sal) over (partition by deptno order by sal desc range between unbounded preceding and unbounded following) "부서최저"
from emp
order by deptno, sal;

clear break

	질문 : min과 first_value의 차이점?

             select deptno, ename, sal,
                    first_value(ename) over (order by sal) as fv1
             from emp
             order by deptno, sal;

             select deptno, ename, sal,
                    first_value(ename) over (partition by deptno order by sal) as fv2
             from emp
             order by deptno, sal;

[예제 6 : RATIO_TO_REPORT 함수]
  >> 리포팅 전용 함수
◆ Reporting

break on deptno skip 1

-- 회사전체, 부서전체 급여에서 본인이 차지하는 비율을 나타내세요.
select deptno, ename, sal,
       sal/(select sum(sal) from emp) as ratio1,
       ratio_to_report(sal) over ()   as ratio1,          -- function 사용
       sal/(select sum(sal) from emp where deptno = e1.deptno) as ratio2,
       ratio_to_report(sal) over (partition by deptno)         as ratio2  -- function 사용
from emp e1;

clear break

◆ Windowing

select deptno, ename, sal,
       ratio_to_report(sal) over (order by sal) as ratio1,
       ratio_to_report(sal) over (partition by deptno order by sal) as ratio2
from emp e1;

--> 에러 : ORA-30487: ORDER BY를 여기에 사용할 수 없습니다


========================================
[3] LAG/LEAD
========================================
  >> 이전 이후 값과의 연산

* ORDER BY가 필수이다. 그러므로 Windowing 계열인 셈이다.

select deptno, sum(sal) as sum_sal
from emp
group by deptno
order by sum_sal;

select deptno, sum(sal) as sum_sal,
       lag(sum_sal) over ()            --> 에러 : ORA-30485: 윈도우 지정에 ORDER BY 표현식이 없습니다
from emp
group by deptno;

-- 나를 기준으로 나의 앞에 있는 값
  select deptno, sum(sal) as sum_sal,
         lag(sum(sal)) over (order by sum(sal)) as prev_value
  from emp
  group by deptno;

-- lag(sum(sal), 나의 몇번째 앞, 없으면 0을 넣어라)
  select deptno, sum(sal) as sum_sal,
         lag(sum(sal), 1, 0) over (order by sum(sal)) as prev_value
  from emp
  group by deptno;

  select deptno, sum(sal) as sum_sal,
         lag(sum(sal), 2, 0) over (order by sum(sal)) as prev_value
  from emp
  group by deptno;

-- 나를 기준으로 나의 뒤에 있는 값
  select deptno, sum(sal) as sum_sal,
         lead(sum(sal), 1, 0) over (order by sum(sal)) as next_value
  from emp
  group by deptno;

   --------
-- 부서별로 나눠보기
  break on deptno skip 1

  select deptno, empno, ename, sal
  from emp
  order by deptno;

  select deptno, empno, ename, sal, lag(sal, 1, 0) over (partition by deptno order by sal) as prev_value
  from emp
  order by deptno;

  with t as
  (
  select deptno, empno, ename, sal, lag(sal, 1, 0) over (partition by deptno order by sal) as prev_sal
  from emp
  order by deptno
  )
  select deptno, empno, ename, sal, prev_sal, sal - prev_sal as diff
  from t;


========================================
[4] NTH_VALUE
========================================

질의 결과에서 n번째 위치한 값 구하기

clear break

select deptno, sal, nth_value(sal, 3) over () "그냥 3번째에 위치한 값"
from emp;

select deptno, sal, nth_value(sal, 2) over (order by sal) "2번째에 위치한 값"
from emp;

break on deptno skip 1

select deptno, sal, nth_value(sal, 2) over (partition by deptno order by sal desc) "2위"
from emp;

clear break

select deptno, sal,
       nth_value(sal, 1) over (partition by deptno order by sal desc) "1위",
       nth_value(sal, 2) over (partition by deptno order by sal desc) "2위",
       nth_value(sal, 3) over (partition by deptno order by sal desc) "3위"
from emp;

select deptno,
       nth_value(sal, 1) over (partition by deptno order by sal desc) "1위",
       nth_value(sal, 2) over (partition by deptno order by sal desc) "2위",
       nth_value(sal, 3) over (partition by deptno order by sal desc) "3위"
from emp;

with t as (
select deptno,
       nth_value(sal, 1) over (partition by deptno order by sal desc) "1위",
       nth_value(sal, 2) over (partition by deptno order by sal desc) "2위",
       nth_value(sal, 3) over (partition by deptno order by sal desc) "3위"
from emp
)
select * from t
where "3위" is not null;

with t as (
select deptno,
       nth_value(sal, 1) over (partition by deptno order by sal desc) "1위",
       nth_value(sal, 2) over (partition by deptno order by sal desc) "2위",
       nth_value(sal, 3) over (partition by deptno order by sal desc) "3위"
from emp
)
select distinct deptno, "1위", "2위", "3위"
from t
where "3위" is not null;

   ---

break on deptno skip 1


select deptno, job, min(sal)
from emp
group by deptno, job
order by deptno, job;

select deptno, job, min(sal),
       nth_value(job, 2) over (partition by deptno)      "2위 Job",
       nth_value(min(sal), 2) over (partition by deptno) "2위 최저급여"
from emp
group by deptno, job;

clear break


========================================
[5] LISTAGG
========================================

위에서 아래로 -> 왼쪽에서 오른쪽으로

col empnos format a100

select empno
from emp
order by empno;

select listagg(empno, '/') within group () as empnos
from emp;

  --> 에러 : ORA-30491: 누락된 ORDER BY 절

select listagg(empno, '') within group (order by empno) as empnos
from emp;

select listagg(empno, ' ') within group (order by empno) as empnos
from emp;

select listagg(empno, '/') within group (order by empno) as empnos
from emp;

select listagg(ename, '/') within group (order by empno) as empnos
from emp;

select listagg(empno||','||ename, ' or ') within group (order by empno) as empnos
from emp;

select listagg(empno||','||ename, ' or ') within group (order by empno) over (partition by deptno) as empnos
from emp;

   ---------

select deptno, listagg(empno||','||ename, ' or ') within group (order by empno) over (partition by deptno) as empnos
from emp;

select distinct deptno, listagg(empno||','||ename, ' or ') within group (order by empno) over (partition by deptno) as empnos
from emp
order by deptno;

   ---------

col ename format a10
col enames format a40
col colleagues format a100

select deptno, avg(sal) avg_sal
from   emp
group by deptno
order by deptno;

select deptno, avg(sal) avg_sal, listagg(ename, ',') within group (order by sal desc) as enames
from   emp
group  by deptno
order by deptno;

   ---------

select deptno, ename, sal
from   emp
order by deptno, ename;

select deptno, ename, sal, listagg( ename, ',') within group (order by ename) over (partition by deptno) as colleagues
from   emp
order by deptno, ename;

# 필수 참고 : http://www.oracle-base.com/articles/misc/StringAggregationTechniques.php#listagg


========================================
[6] FIRST/LAST functions
========================================

- 특정한 함수를 의미하는 것이 아니고, 함수의 사용방법을 의미한다.
- FIRST, LAST는 그 자체로는 함수는 아니며 분석 함수에서 사용하는 키워드이다.

- 이 두 키워드는 다른 분석 함수와 같이 사용되어 특정 그룹에 따라 맨 처음 로우를 추출한다.
 단순히 최대값이나 최소값을 추출하는 것이 아니라 최대 혹은 최소값을 가진 로우를 추출하는 것이다.

aggregate_function KEEP ( DENSE_RANK FIRST|LAST ORDER BY expr [ DESC | ASC ] [NULLS { FIRST | LAST }]
                                                      [, expr [ DESC | ASC ] [NULLS { FIRST | LAST }]]... )
                          [OVER query_partitioning_clause]

[A] 컬럼을 기준으로 정렬해서 [B] 컬럼의 값의 MIN, MAX, SUM, AVG, COUNT, VARIANCE, STDDEV을 구할 수 있다는 것이 다르다.

  -----

select empno, ename, sal, job
from emp
order by job;

select empno, ename, sal, job, min(sal) KEEP (DENSE_RANK FIRST ORDER BY job) over (partition by job) as min_sal
from emp
order by job;

  -----


drop table t1 purge;
create table t1 as select * from emp;
update t1 set job = 'CLERK' where job <> 'CLERK';

select empno, ename, sal, job, deptno
from t1
order by deptno;

select empno, ename, sal, job, deptno, min(sal) KEEP (DENSE_RANK FIRST ORDER BY job) over (partition by deptno) as min_sal
from t1
order by deptno;

  -----

* 다른 함수와의 비교

  [1] 방법 1

      select deptno, first_value(ename) over (partition by deptno order by sal desc, ename) fv
      from emp;

      select deptno, max(fv)
      from (select deptno, first_value(ename) over (partition by deptno order by sal desc, ename) fv
            from emp)
      group by deptno;

  [2] 방법 2

      select deptno, max(ename) keep (dense_rank first order by sal desc, ename ) fv
      from emp
      group by deptno;

  -----

문제 : 부서별 최대 급여자, 최소 급여자

      DEPTNO ENAME             SAL ENAME             SAL
  ---------- ---------- ---------- ---------- ----------
          10 KING             5000 MILLER           1300
          20 SCOTT            3000 SMITH             800
          30 BLAKE            2850 JAMES             950

    해법 1. 전통방식

      select deptno, max(sal), min(sal)
      from emp
      group by deptno
      order by deptno;

      -- 10자리 월급10자리이름
      select deptno, lpad(sal, 10)||ename, lpad(sal, 10)||ename
      from emp
      order by 1, 2;

      select deptno, max(lpad(sal, 10)||ename), min(lpad(sal, 10)||ename)
      from emp
      group by deptno
      order by 1, 2;

      with t as (select deptno, max(lpad(sal, 10)||ename) as max, min(lpad(sal, 10)||ename) as min
                 from emp
                 group by deptno)
      select deptno, max, max, min, min from t
      order by deptno;

      with t as (select deptno, max(lpad(sal, 10)||ename) as max, min(lpad(sal, 10)||ename) as min
                 from emp
                 group by deptno)
      select deptno,
             substr(max, 11)    as max_ename,
             substr(max, 1, 10) as max_sal,
             substr(min, 11)    as min_ename,
             substr(min, 1, 10) as min_sal
      from t
      order by deptno;

    해법 2.
      -- 월급으로 역순 상위 이름, 월급
      -- 월급으로 상위 이름, 월급
      col max_ename formant a20
      col max_sal formant 999999
      col min_ename formant a20
      col min_sal formant 999999
      select deptno,
             max(ename) keep (dense_rank first order by sal desc) as max_ename,
             max(sal)   keep (dense_rank first order by sal desc) as max_sal,
             max(ename) keep (dense_rank first order by sal) as min_ename,
             max(sal)   keep (dense_rank first order by sal) as min_sal
      from emp
      group by deptno;

========================================
[7] WIDTH_BUCKET Function
========================================

http://docs.oracle.com/cd/E11882_01/server.112/e25554/analysis.htm#BCFHJBCE

- NTILE        : equiheight buckets(histogram), rows
  -- 높이가 같은것 높이균영 히스토그램 (구간을 동일하게 두고 값을 맞춤)
  https://sites.google.com/site/smcgbu/home/gongbu-iyagi/ntile
- WIDTH_BUCKET : equiwidth  buckets(histogram), values
  -- 넓이가 같은것 넓이균형 히스토그램 (일반 히스토그램)

예제 1 :

   select empno, ename, sal, width_bucket(sal, 1000, 4000, 4) as width_bucket,
                             ntile(4) over (order by sal) as ntile
   from emp;

     EMPNO ENAME                       SAL WIDTH_BUCKET      NTILE
  ---------- -------------------- ---------- ------------ ----------
      7369 SMITH                       800            0          1
      7900 JAMES                       950            0          1
      7876 ADAMS                      1100            1          1
      7521 WARD                       1250            1          1

      7654 MARTIN                     1250            1          2
      7934 MILLER                     1300            1          2
      7844 TURNER                     1500            1          2
      7499 ALLEN                      1600            1          2

      7782 CLARK                      2450            2          3
      7698 BLAKE                      2850            3          3
      7566 JONES                      2975            3          3

      7788 SCOTT                      3000            3          4
      7902 FORD                       3000            3          4
      7839 KING                       5000            5          4

예제 2 : http://docs.oracle.com/cd/E11882_01/server.112/e25554/analysis.htm#i1007452


========================================
[8] Partition Join Syntax
========================================
  >> Partition outer Join
  -- 분석과는 상관없는 아웃터 조인

http://docs.oracle.com/cd/E11882_01/server.112/e25554/analysis.htm#i1014934

  drop table t_times purge;

  -- 달력
  create table t_times
  as
  select to_date('20111201') + level - 1 as day
  from dual
  connect by level <= 10;

  drop table t_sales purge;

  -- 상품이 팔린 날짜
  create table t_sales
  as
  select to_date('20111201') + level - 1 as day, 'A' as gubun, ceil(dbms_random.value(100, 200)) amt from dual connect by level <= 10
  union all
  select to_date('20111201') + level - 1 as day, 'B' as gubun, ceil(dbms_random.value(100, 200)) amt from dual connect by level <= 10;

  delete from t_sales where amt between 120 and 160;

  select * from t_times;
  select * from t_sales;

  -- 보고 싶은 내용 : 날짜는 그대로 순서대로 나오고 상품이 팔린 부분에만 값이 들어가 있는 형태
    -- 2017년1월1일 a 상품 10개
    -- 2017년1월2일

  -- 일반 조인
    -- 팔린 날짜 기준으로 나옴
    select *
    from t_sales s JOIN t_times t ON s.day = t.day;

  -- Outer Join
    -- 팔린 날짜 외 다른 날짜도 노출함
    select *
    from t_sales s RIGHT OUTER JOIN t_times t ON s.day = t.day;

  -- Partitioned Outer Join
    -- 테이블 전부가 아니고 구분컬름의 값으로 나누어서 그 테이블의 일부와 테이블을 연결해라 A 와 달력, B 와 달력 outer 조인 시킴
    -- 단 RIGHT OUTER JOIN 으로 모든 날짜를 노출
    select *
    from t_sales s Partition By (gubun) RIGHT OUTER JOIN t_times t ON s.day = t.day;

    select *
    from t_times t LEFT OUTER JOIN t_sales s Partition By (gubun) ON s.day = t.day;

========================================
[9] Pivoting Operations
========================================
>> 행과 열의 교체

-----------------------------------
> 가로, 세로 바꾸기 일반적 해법   <
-----------------------------------
  >> select min(sal) KEEP (DENSE_RANK FIRST ORDER BY sal) aa,
  min(n_sal) KEEP (DENSE_RANK FIRST ORDER BY sal) nsal ,
  min(nn_sal) KEEP (DENSE_RANK FIRST ORDER BY sal) nnsal
  from
  (select sal,
    lead(sal) over (order by sal) as n_sal,
    lead(sal,2) over (order by sal) as nn_sal from t1);
  --- 행 -> 열
  select no, decode(no, 1, s1), decode(no, 2, s2), decode(no, 3, s3)
  from (select rownum as no, sal s1, sal s2, sal s3
      from t1);

      -- 복제된 행을 수직으로 압축시킴 max
  select max(decode(no, 1, s1)) m1, max(decode(no, 2, s2)) m2, max(decode(no, 3, s3)) m3
  from (select rownum as no, sal s1, sal s2, sal s3
      from t1);

  --- 열 -> 행
  drop table t1 purge;

  create table t1 as
  select max(decode(no, 1, s1)) m1, max(decode(no, 2, s2)) m2, max(decode(no, 3, s3)) m3
  from (select rownum as no, sal s1, sal s2, sal s3
      from emp where rownum <=3);

  select *
  from t1,
    (select level no
    from dual
    connect by level <=3) n;

    -- 복제된 열을 수평으로 압축시킴 decode
  select decode(no, 1, m1,
                    2, m2,
                    3, m3) as col
  from t1,
    (select level no
    from dual
    connect by level <=3) n;


(1) 위에서 아래로 --> 좌에서 우로

  col sawon format a20

  create or replace view top3
  as
  select deptno, empno||' '||rpad(ename, 10)||' '||sal as sawon, rank
  from (select deptno, empno, ename, sal,
               row_number() over (partition by deptno order by sal desc) as rank
        from emp)
  where rank <= 3;

  select deptno, sawon, sawon, sawon, rank
  from top3;

  select deptno, decode(rank, 1, sawon) "First", sawon, sawon, rank
  from top3;

  col first  format a30
  col second format a30
  col third  format a30

  select deptno, decode(rank, 1, sawon) "First", decode(rank, 2, sawon) "Second", decode(rank, 3, sawon) "Third"
  from top3;

  select deptno, min(decode(rank, 1, sawon)) "First", min(decode(rank, 2, sawon)) "Second", min(decode(rank, 3, sawon)) "Third"
  from top3
  group by deptno;

  select deptno, min(case rank when 1 then sawon end) "First", min(case rank when 2 then sawon end) "Second", min(case rank when 3 then sawon end) "Third"
  from top3
  group by deptno;

  create or replace view top_three
  as
  select deptno, min(case rank when 1 then sawon end) First, min(case rank when 2 then sawon end) Second, min(case rank when 3 then sawon end) Third
  from top3
  group by deptno;

  select * from top_three;

    ------

(2) 좌에서 우로 --> 위에서 아래로

  select empno, ename, '    ' as col1, no
  from emp e, (select level as no from dual connect by level <= 2) n
  order by no, empno;

  select empno, ename, decode(no, 1, empno) as col1, no
  from emp e, (select level as no from dual connect by level <= 2) n
  order by no, empno;

  select empno, ename, decode(no, 2, ename) as col1, no
  from emp e, (select level as no from dual connect by level <= 2) n
  order by no, empno;

  select empno, ename, decode(no, 1, to_char(empno), 2, ename) as col1, no
  from emp e, (select level as no from dual connect by level <= 2) n
  order by no, empno;

     ----

  select *
  from top_three t, (select level as no from dual connect by level <= 3) n
  order by deptno, no;

  select deptno, first, second, third, decode(no, 1, first, 2, second, 3, third) as sawon, no
  from top_three t, (select level as no from dual connect by level <= 3) n
  order by deptno, no;

  select deptno, decode(no, 1, first, 2, second, 3, third) as sawon, no
  from top_three t, (select level as no from dual connect by level <= 3) n
  order by deptno, no;

--------------------
> Pivot 예제       <
--------------------

  * Syntax : http://docs.oracle.com/cd/E11882_01/server.112/e26088/statements_10002.htm#CHDCEJJE

  (1)

  select --> 예제 시작
    deptno, sum(sal)
  from emp
  group by deptno
  order by deptno;

  (2)

  select --> 피벗 적용
    *
  from (select deptno, sal from emp)
        PIVOT (sum(sal) FOR deptno IN (10 as d10, 20 as d20, 30 as d30));
      -- deptno 별 sum(sal)

    ■ 피벗의 비밀 : http://ukja.tistory.com/183  --> select * from table(dbms_xplan.display_cursor(null, null, 'allstats all last'));

       select deptno, CASE WHEN ("DEPTNO"=10) THEN "SAL" END d10, CASE WHEN ("DEPTNO"=20) THEN "SAL" END d20, CASE WHEN ("DEPTNO"=30) THEN "SAL" END d30
       from emp
       order by deptno;

       select sum(CASE WHEN ("DEPTNO"=10) THEN "SAL" END) d10, sum(CASE WHEN ("DEPTNO"=20) THEN "SAL" END) d20, sum(CASE WHEN ("DEPTNO"=30) THEN "SAL" END) d30
       from emp
       order by deptno;

  drop table t1 purge;

  create table t1
  as select * from (select deptno, sal from emp)
                    PIVOT (sum(sal) FOR deptno IN (10 as d10, 20 as d20, 30 as d30));
  select * from t1;

  (3)

  select --> JOB 컬럼 추가, 위치 무관, QT 확인 요망
    *
  from (select job, deptno, sal from emp)
        PIVOT (sum(sal) FOR deptno IN (10 as d10, 20 as d20, 30 as d30))
  order by job;

           select job, sum(CASE WHEN ("DEPTNO"=10) THEN "SAL" END) d10, sum(CASE WHEN ("DEPTNO"=20) THEN "SAL" END) d20, sum(CASE WHEN ("DEPTNO"=30) THEN "SAL" END) d30
           from emp
           group by job
           order by job;

  select --> Null 값을 0으로 대체
    job, nvl(d10, 0), nvl(d20, 0), nvl(d30, 0) as d30
  from (select job, deptno, sal from emp)
        PIVOT (sum(sal) FOR deptno IN (10 as d10, 20 as d20, 30 as d30))
  order by job;

  (4)

  select --> to_char(hiredate, 'YYYY') 컬럼 추가, QT 확인 요망
    *
  from (select job, to_char(hiredate, 'YYYY') as YYYY, deptno, sal from emp)
        PIVOT (sum(sal) FOR deptno IN (10 as d10, 20 as d20, 30 as d30))
  order by job, YYYY;

           select job, to_char(hiredate, 'YYYY') as YYYY, sum(CASE WHEN ("DEPTNO"=10) THEN "SAL" END) d10, sum(CASE WHEN ("DEPTNO"=20) THEN "SAL" END) d20, sum(CASE WHEN ("DEPTNO"=30) THEN "SAL" END) d30
           from emp
           group by job, to_char(hiredate, 'YYYY')
           order by job;

  (5)

  select --> avg(sal) 추가, 컬럼 alias 필수 , QT 확인 요망
    *
  from (select job, to_char(hiredate, 'YYYY') as YYYY, deptno, sal from emp)
        PIVOT (sum(sal) as sum_sal, avg(sal) as avg_sal FOR deptno IN (10 as d10, 20 as d20, 30 as d30))
  order by job, YYYY;

           select job, to_char(hiredate, 'YYYY') as YYYY,
                       sum(CASE WHEN ("DEPTNO"=10) THEN "SAL" END) d10_SUM_SAL,
                       avg(CASE WHEN ("DEPTNO"=10) THEN "SAL" END) d10_AVG_SAL,
                       sum(CASE WHEN ("DEPTNO"=20) THEN "SAL" END) d20_SUM_SAL,
                       avg(CASE WHEN ("DEPTNO"=20) THEN "SAL" END) d20_AVG_SAL,
                       sum(CASE WHEN ("DEPTNO"=30) THEN "SAL" END) d30_SUM_SAL,
                       avg(CASE WHEN ("DEPTNO"=30) THEN "SAL" END) d30_AVG_SAL
           from emp
           group by job, to_char(hiredate, 'YYYY')
           order by job;

  (6)

  select --> DEPTNO and YYYY
    *
  from (select job, deptno, to_char(hiredate, 'YYYY') as YYYY, sal
        from emp
        where  to_char(hiredate, 'YYYY') in ('1981', '1982'))
  order by job, deptno, yyyy;

  select --> DEPTNO and YYYY, QT 확인 요망
    *
  from (select job, deptno, to_char(hiredate, 'YYYY') as YYYY, sal
        from emp
        where  to_char(hiredate, 'YYYY') in ('1981', '1982'))
  PIVOT (sum(sal) as sum_sal FOR (deptno, YYYY)
                              IN ((10, '1981') as d10_1981, (10, '1982') as d10_1982,
                                  (20, '1981') as d20_1981, (20, '1982') as d20_1982,
                                  (30, '1981') as d30_1981, (30, '1982') as d30_1982))
  order by job;

           select job,
                   sum(CASE WHEN ("DEPTNO"=10 and to_char(hiredate, 'YYYY') = '1981') THEN "SAL" END) d10_1981_SUM_SAL,
                   sum(CASE WHEN ("DEPTNO"=10 and to_char(hiredate, 'YYYY') = '1982') THEN "SAL" END) d10_1982_SUM_SAL,
                   sum(CASE WHEN ("DEPTNO"=20 and to_char(hiredate, 'YYYY') = '1981') THEN "SAL" END) d20_1981_SUM_SAL,
                   sum(CASE WHEN ("DEPTNO"=20 and to_char(hiredate, 'YYYY') = '1982') THEN "SAL" END) d20_1982_SUM_SAL,
                   sum(CASE WHEN ("DEPTNO"=30 and to_char(hiredate, 'YYYY') = '1981') THEN "SAL" END) d30_1981_SUM_SAL,
                   sum(CASE WHEN ("DEPTNO"=30 and to_char(hiredate, 'YYYY') = '1982') THEN "SAL" END) d30_1982_SUM_SAL
           from emp
           group by job
           order by job;


  # 문제 : 다음과 같은 결과를 만드세요.

  DNAME             'CLERK'  'MANAGER' 'PRESIDENT'  'ANALYST' 'SALESMAN'
  -------------- ---------- ---------- ----------- ---------- ----------
  ACCOUNTING              1          1           1          0          0
  RESEARCH                2          1           0          2          0
  SALES                   1          1           0          0          4

  select *
  from (select e.job, d.dname, e.empno
        from emp e, dept d
        where e.deptno = d.deptno);

  select *
  from (select e.job, d.dname, e.empno
        from emp e, dept d
        where e.deptno = d.deptno)
        pivot (count(empno) for job in ('CLERK','MANAGER','PRESIDENT','ANALYST','SALESMAN'));

--------------------
> Unpivot 예제     <
--------------------

        D10        D20        D30   <-- deptno
 ---------- ---------- ----------
       8750      10875       9400   <-- sum_sal


 DEP    SUM_SAL
 --- ----------
 D10       8750
 D20      10875
 D30       9400

select * from t1;

select * from t1
UNPIVOT (sum_sal FOR deptno IN (D10 as 10, D20 as 20, D30 as 30));

- http://cafe.naver.com/eduoracle/451
- http://docs.oracle.com/cd/E11882_01/server.112/e25554/analysis.htm#BCFHHHHF

==============================
SQL for Modeling
==============================

https://sites.google.com/site/smcgbu/home/gongbu-iyagi/modeljeolseupeuledeusiteuhyungnaenaegi
엑셀의 스프레드시트의 연산과 같은 기능

SQL Model.sql

==============================
Hierarchical Queries
==============================
계층질의를 쉽게 할수 있도록 해줌
psedo column
level

# SQL 작성 및 해석 권장 순서
  from        --1
  where       --4
  start with  --2
  connect by  --3

# Top-down
  --나를 기준으로 위에서부터 아래 방향
  select level, e.*
  from emp e
  start with empno = 7839   -- 제일 꼭대기에서 시작
  connect by PRIOR empno = mgr; -- 나와 나의 mgr 을 비교해서 붙임

  col emp_no format a20
  col empno noprint
  -- 레벨에 따라서 들여쓰기 시킴
  select level, lpad(e.empno, level*4, ' ') as emp_no, e.*
  from emp e
  start with empno = 7839
  connect by PRIOR empno = mgr;

# bottom-up
  --나를 기준으로 아래에서부터 위 방향
  select level, lpad(e.empno, level*4, ' ') as emp_no, e.*
  from emp
  start with empno = 7839   -- 제일 꼭대기에서 시작
  connect by empno = PRIOR mgr; -- 나와 나의 mgr 을 비교해서 붙임

한건 한건을 비교할때 마다 모든 컬럼을 full scan 해야 함
create index mgr
인덱스를 이용해서 바로바로 찾을 수 있도록 함

# Tree walking
top-down
  empno -  mgr
      1 -  null   1 level
      2 -   1     이전행이 1 인 값들이 2 level
      3 -   1     이전행이 1 인 값들이 2 level
      4 -   2     이전행이 2 인 값들이 3 level
      5 -   4     이전행이 4 인 값들이 4 level
      6 -   4     이전행이 4 인 값들이 4 level


# Branch 자르기 VS Node 자르기

branch 자르기
해당 노드부터 만들지 않기

node 자르기
모두 다 만든다음에 한 노드만 제외


# 정렬
  -- 계층성을 유지 하면서 레벨별로만 월급순 정렬
  siblings by

-- 이름을 계층 별로 만들어 주기
sys_connect_by_path(ename, '/')


from dual
connect by
는 나중에

# Connect by level < n 패턴
select dummy
from dual;

-- 무한 루프에 빠짐
-- rownum, level 은 동일하다 rownum 버그가 있어 level 을 사용한다.
select rownum, level, dummy
from dual
connect by dummy = dummy;

select rownum, level, dummy
from dual
connect by dummy = dummy and level <= 100;
  --> where 1=1 and 100>2 조건에서 1
  --> dummy = dummy and 조건 삭제


___
