
===========================
 11장 View, Sequence, Index, Synonym
===========================

어제 시퀀스, VIEW 내용 추가

Table : 데이터가 순서 없이 저장된다.
    해결법
    - Oracle 은 Hashing 을 해서 여기저기 넣어 놓는다.
    - Partition .... 등 으로 해결
    - ROWID 64진법, 6 Object 3 File 6 Block 3 Row
Index : Rowid 를 전문적으로 보관
View : 쿼리문을 보관
Sequence : 숫자값을 보관
Synonym : 별명


도서관     database
열람실     tablespace
책장       datafile
책장한칸   block
책         row

Data file
  SYSTEM.DBF 파일
  블럭이라는 공간으로 데이터들이 나눠져 있음 2k 4k 8...
  create table 를 하면 몇개의 블럭을 사용하여 테이블의 공간을 만들어둠
  insert 를 할때 hasing 을 통해 공간에 채워 넣음
  테이블에 데이터는 순서없이 저장됨

----------------------
## View
----------------------
-- 구문 -------
CREATE [OR REPLACE] [FORCE|NOFORCE] VIEW view
[(alias[, alias]...)]
AS subquery
[WITH CHECK OPTION [CONSTRAINT constraint]]
[WITH READ ONLY [CONSTRAINT constraint]];

  OR REPLACE
    뷰가 이미 있는 경우 다시 생성합니다.
  FORCE
    기본 테이블의 존재 여부에 관계없이 뷰를 생성합니다.
  NOFORCE
    기본 테이블이 있는 경우에만 뷰를 생성합니다(기본값).
  view
    뷰의 이름입니다.
  alias
    뷰의 query에서 선택한 표현식의 이름을 지정합니다. (alias의 수와 뷰에서선택한 표현식의 수가 일치해야 합니다.)
  subquery
    완전한 SELECT 문입니다. (SELECT 리스트에 열의 alias를 사용할수 있습니다.)
  WITH CHECK OPTION
    뷰에서 액세스할 수 있는 행만 삽입하거나 갱신할 수 있도록 지정합니다.
  constraint CHECK OPTION
    제약 조건에 할당되는 이름입니다.
  WITH READ ONLY
    현재 뷰에서 DML 작업을 수행하지 못하도록 합니다.
-------------
  - Named select
  - Query Transformation
  - 집합의 무한 확장
  - Simple vs Complex
    Simple : 단순하게 테이블에 있는 값을 그대로 다 뷰에 넣음. 뷰에 dml 을 하면 원래 테이블에도 dml 이 됨
    Complex : 원 테이블 데이터를 가공하여 새로운 컬럼으로 뷰를 생성함. 대부분 dml 을 할 수 없다. 테이블에 데이터가 업데이트 되지 않음.
  - 데이터 딕셔너리에 저장됨

## 장점 ##
  - 복합 query 를 단순화 함.
  - 데이터 독립성이 제공 : 뷰가 변경이 되어도 테이블의 구조를 변경할 일이 없다.
  - 데이터 엑세스 제한
  - 동일한 데이터의 다른 뷰 제공

>> Simple 뷰

create or replace view 부서
as
select deptno 부서번호, dname 부서이름, loc 지역
from dept;

create or replace view v1
as
select empno, ename, job, deptno
from emp;

create or replace view v2
as
select empno, ename, job, sal, hiredate, deptno
from emp;

select * from 부서;

grant select
on v1
to public;

select * from dream30.v1;

grant select
on v2
to dream01, dream02;

>> Complex 뷰
create or replace view v3
as
select empno, sal, comm, sal*12 + nvl(sal, 0) as ann_sal
from emp;

// 컬럼명을 새롭게 줘야 한다.
create or replace view v4 (dno, sumsal, avgsal, cnt, stddev, variance)
as
select deptno, sum(sal), avg(sal), count(*), stddev(sal), variance(sal)
from emp
group by deptno;

select * from v3;

select * from v4;

// table 이 update 되면 view 에서 사용한 max, min 같은 값들이 자동 update 된다.
SQL> create or replace view v1 as select max(deptno) max from t1;
View created.
SQL> insert into t1 values ('50', 'AMORANG', 'SEOUL');
1 row created.
SQL> select * from v1;
         MAX
  ----------
          50

* DML 이 가능한 view
key preserved table
n:1 조인의 경우 n은 업데이트 되지 않지만 1은 가능하다.
(다시 찾아 보기!!!)

create or replace view v5
as
  select e.empno, e.enmae, e.sal, d.delpno, d.loc
  from emp e, dept d

>> update 가능 컬럼 확인
  * http://orapybubu.blog.me/40035845854
  user_updatable_columns

## user_views 뷰 확인
사용자가 만든 view 보기

alter table emp  add primary key(empno);
alter table dept add primary key(deptno);

create or replace view v5
as
select e.empno, e.ename, e.sal, d.deptno, d.loc
from emp e, dept d
where e.deptno = d.deptno;

select *
from user_updatable_columns
where table_name in ('V1','V2','V3','V4','V5');


# 뷰 확인

set long 2000

select view_name, text
from user_views;

show all
show long : long 타입은 80으로 되어 있다. 기본 2G 인데 너무 크기때문에 80으로 줄여줘 있음
set long 2000


n view
??? 머티리얼 뷰


# 11-14 뷰와 DML
* 뷰에 다음 항목이 포함되어 있으면 행을 제거, 수정, 추가 할 수 없습니다.
  – 그룹 함수
  – GROUP BY 절
  – DISTINCT 키워드
  – Pseudocolumn ROWNUM 키워드\
  - 표현식으로 정의되는 열 (추가, 수정만 되지 않음)
  - 뷰에서 선택되지 않은 기본 테이블의 NOT NULL 열 (추가만 되지 않음)

drop table t1 purge;
create table t1 as select * from dept;
 ---
create OR replace view dv1
  as select deptno, dname, loc from dept;
insert into dv1 values (50, 'MARKETING', 'SEOUL');
select * from t1;
 ---
create OR replace view dv2
  as
  select distinct deptno, dname, loc from dept;
delect from dv2
where deptno = 50; -- 에러남

drop table t1 purge;
create table t1 as select * from dept;

  --

create or replace view dv1
as
select deptno, dname, loc from t1;

insert into dv1 values (50, 'MARKETING', 'SEOUL');

select * from t1;

  --

create or replace view dv2
as
select distinct deptno, dname, loc from t1;

delete from dv2
where deptno = 50;   -- 에러 : ORA-01732: data manipulation operation not legal on this view

  --

create or replace view dv3
as
select deptno, initcap(dname) dname, loc from t1;

select * from dv3;

update dv3
set dname = 'HR'
where deptno = 30;  -- ORA-01733: virtual column not allowed here

update dv3
set loc = 'JEONJU'
where deptno = 30;

  --

//DML 이 적용되는 view 에서는 not null 조건이 있는 경우 값을 넣어 주지 않으면 에러남
alter table t1 modify(loc not null);

create or replace view dv4
as
select deptno, dname from t1;

insert into dv4
values (60, 'SECRET');  -- 에러

  ---

## WITH CHECK OPTION 절 사용
• WITH CHECK OPTION 절을 사용하여 뷰에 수행된 DML 작업이 뷰 영역에만 적용되도록 할 수 있습니다.
CREATE OR REPLACE VIEW empvu20
AS SELECT *
FROM employees
WHERE department_id = 20
WITH CHECK OPTION CONSTRAINT empvu20_ck ;
• department_id가 20이 아닌 행을 INSERT하거나 뷰에 있는 임의의 행에서 부서 번호를 UPDATE하려는 시도는 WITH CHECK OPTION 제약 조건에 위반되므로 실패합니다.

# 11-17 with check option
drop table t1 purge;

create table t1
as
select empno, deptno
from emp;

create or replace view v1
as
select empno, deptno
from t1
where deptno = 20
with check option constraint v1_deptno_ck;

select * from v1;

insert into v1
values (9999, 10);  -- ORA-01402: view WITH CHECK OPTION where-clause violation

select * from t1;


----------------------
## Sequence
----------------------
----------- 구문 -----------
  CREATE SEQUENCE sequence
  [INCREMENT BY n]
  [START WITH n]
  [{MAXVALUE n | NOMAXVALUE}]
  [{MINVALUE n | NOMINVALUE}]
  [{CYCLE | NOCYCLE}]
  [{CACHE n | NOCACHE}];

  sequence
    시퀀스 생성기의 이름입니다.
  INCREMENT BY n
    시퀀스 번호 사이의 간격을 지정하며, 여기서 n은 정수입니다.
    (이 절을 생략하면 시퀀스는 1씩 증가합니다.)
  START WITH n
    생성할 첫번째 시퀀스 번호를 지정합니다.
    (이 절을 생략하면 시퀀스는 1부터 시작합니다.)
  MAXVALUE n | NOMAXVALUE
    시퀀스가 생성할 수 있는 최대값을 지정합니다.  |
    오름차순 시퀀스의 경우 최대값 10^27을, 내림차순 시퀀스의 경우 –1을 지정합니다(기본 옵션).
  MINVALUE n | NOMINVALUE
    최소 시퀀스 값을 지정합니다.  |
    오름차순 시퀀스의 경우 최소값 1을, 내림차순 시퀀스의 경우 –(10^26)을 지정합니다(기본 옵션).
  CYCLE | NOCYCLE
    최대값이나 최소값에 도달한 후에 시퀀스를 계속 생성할지 여부를 지정합니다. (NOCYCLE이 기본 옵션입니다.)
  CACHE n | NOCACHE Oracle
    서버가 메모리에 미리 할당하고 저장하는 값의 개수를 지정합니다. (Oracle 서버는 기본적으로 20개의 값을 캐시합니다.)
-----------

* 만들어진 seq 는 다른 곳에서도 사용가능하고 다른 사람도 사용가능 하다.
* 간격이 발생할 수 있다.
  – 롤백이 발생하는 경우
  – 시스템 작동이 중단되는 경우
  – 시퀀스가 다른 테이블에서 사용되는 경우
* 증분값, 최대값, 최소값, 순환 옵션 또는 캐시 옵션은 변경 가능하다.
* 시퀀스 Pseudocolumn
  - NEXTVAL : 다음 시퀀스 값
  - CURRVAL : 사용하려면 해당 세션에서 NEXTVAL을 한번 사용해야 CURRVAL 을 사용가능 하다.
* 일부 유효성 검사가 수행 : 발생된 번호보다 max 를 작게 했다던가 하는것들

  * 채번
    1. 시퀀스 사용
    create sequence seq1 start with 100 increment by 1
      : 101, 102, 103, 104, ....
      by 10 : 100, 110, ....
    2. max 값 구해서 +1 : 트랜잭션 때문에 update 되지 않을 경우 고려
    3. 채번테이블 : lock 에 의해서 작업이 오래걸릴수 있다.

drop table t1 purge;
create table t1 (no number, name varchar2(10));

drop sequence seq1;
create sequence seq1
start with 1      -- 생략가능
increment by 1;   -- 생략가능
cache 20;        -- 한번에 숫자를 20개씩 뽑아 놓고 줌 default 20

insert into t1
values (seq1.nextval, '&user_input');

insert into t1
values (seq1.nextval, '&user_input');

select * from t1;

select seq1.CURRVAL from dual;



-----------------------
 Index
-----------------------
--- 구문 ------
CREATE [UNIQUE][BITMAP]INDEX index
ON table (column[, column]...);

UNIQUE 인덱스가 기반으로 하는 열의 값이 고유해야 함을 나타내려면 지정
BITMAP 각 행을 별도로 인덱스화하지 않고 각 구분 키에 대한 비트맵을 사용하여 인덱스 생성 비트맵 인덱스에서는 키 값과 연관된 rowid를 비트맵으로 저장
----------------
* 테이블의 데이터가 순서 없이 저장됨을 극복하기 위함
* 테이블과 전혀 다른 곳에 "정렬"해서 만들어 놓는다.
* Btree 구조로 되어 있다. (중간에서 찾고 다시 중간에서 찾는 방식)
  (Bitmap 인덱스도 있으나 나중에..)
* Rowid 가 들어 있어 값을 쉽게 찾을 수 있도록 한다.
* pk, uk 를 지원한다.
* fk 관련 lock 문제를 일부 해결할 수 있다.
* table 에 rowid 는 저장되어 있지 않지만 index 의 rowid 는 저장됨 (10byte 공간을 차지함)
* null 값이 들어갔는 커럼은 null 을 제외한 나머지만 index 로 생성한다.
* 자주 가공이 되는 컬럼에서는 사용하지 않는게 좋다.
(rowid = 포인터)
* 복합 인덱스 가능 함 (SQL 튜닝)
* Balanced Tree
  root                    50
  branch         20        |          70
                 40        |          90
  leaf     <20|20~40|40~50   50~70|70~90|90<
* where 절에 자주 나오는 값으로 index 를 생성

## 단점
  * table 이 update 될때 마다 해당 index 도 자동 변경되기 때문에 성능저하를 가져올 수 있다.
  * 잘못 만들면 검색 속도, DML 속도를 오히려 줄일 수 있다.
  * 많은 저장장소를 차지한다.

create index emp_deptno_idx
on emp(deptno);

select deptno, Rowid
from emp
order by 1, 2;

create index emp_jobid_idx
on emp(job);

select job, Rowid
from emp
order by 1, 2;

select rowid, e.* from emp e;


-----------------------
 Synonym
-----------------------
* 별칭 테이블, 뷰, 시퀀스, 프로시저 또는 다른 객체
--- 구문 -------
CREATE [PUBLIC] SYNONYM synonym
FOR object;
----------------

grant Synonym create
to public

create synonym sawon for emp;
select * from sawon;
drop synonym sawon;

SQL> create synonym d30v1 for dream30.v1;
Synonym created.

SQL> select * from d30v1;
       EMPNO     DEPTNO
  ---------- ----------
        7369         20
        7566         20
        7788         20
        7876         20
        7902         20

SQL> select * from tab;
  TNAME                          TABTYPE  CLUSTERID
  ------------------------------ ------- ----------
  BONUS                          TABLE
  COUNTRIES                      TABLE
  D1                             TABLE
  D30V1                          SYNONYM


===========================
 SQL for Aggregation in Data Warehouses
===========================
http://docs.oracle.com/database/122/DWHSG/toc.htm

ROLLUP, CUBE, GROUPING SETS
-----------------------
## ROLLUP
-----------------------
소계, 집계, 총계
* 컬럼이 n 개면 n+1 가지 결과가 리턴
* 컬럼이 나열 순서가 중요함
* 널값도 소계에 들어감
* rullup 에서 소계에 null 값이 들어감 (만들어진 null)

// 부서별 잡별 소계, 총계
> select deptno, job, sum(sal)
from emp group by deptno, job;

//잡별 소계
> select deptno, job, sum(sal)
from emp group by rollup (deptno, job);
    DEPTNO JOB         SUM(SAL)
    ---------- --------- ----------
        10 CLERK           1300
        10 MANAGER         2450
        10 PRESIDENT       5000
        10                 8750
        20 CLERK           1900
        20 ANALYST         6000
        20 MANAGER         2975
        20                10875
        30 CLERK            950
        30 MANAGER         2850
        30 SALESMAN        5600
        30                 9400
                          29025

-----------------------
## CUBE
-----------------------
* 컬럼이 n 개면 2^n 가지 결과가 리턴됨
* 컬럼의 나열 순서 상관 없음
* 가능한 조합 전부가 나옴

//전체 총계 및 소계
> select deptno, job, sum(sal)
from emp group by CUBE (deptno, job) order by 1,2,3;
    DEPTNO JOB         SUM(SAL)
    ---------- --------- ----------
        10 CLERK           1300
        10 MANAGER         2450
        10 PRESIDENT       5000
        10                 8750
        20 ANALYST         6000
        20 CLERK           1900
        20 MANAGER         2975
        20                10875
        30 CLERK            950
        30 MANAGER         2850
        30 SALESMAN        5600
        30                 9400
           ANALYST         6000
           CLERK           4150
           MANAGER         8275
           PRESIDENT       5000
           SALESMAN        5600
                          29025

-----------------------
## GROUPING SETS
----------------------
* () 총계

//부서별 소계
> select deptno, job, sum(sal)
from emp group by grouping sets ((deptno, job), (deptno), ());
  DEPTNO JOB                  SUM(SAL)
  ---------- ------------------ ----------
      10 CLERK                    1300
      10 MANAGER                  2450
      10 PRESIDENT                5000
      10                          8750
      20 CLERK                    1900
      20 ANALYST                  6000
      20 MANAGER                  2975
      20                         10875
      30 CLERK                     950
      30 MANAGER                  2850
      30 SALESMAN                 5600
      30                          9400
                                 29025
//전체 총계 및 소계
> select deptno, job, sum(sal)
from emp group by grouping sets ((deptno, job), (deptno), (job), ());
  DEPTNO JOB                  SUM(SAL)
  ---------- ------------------ ----------
      10 CLERK                    1300
      20 CLERK                    1900
      30 CLERK                     950
      20 ANALYST                  6000
      10 MANAGER                  2450
      20 MANAGER                  2975
      30 MANAGER                  2850
      30 SALESMAN                 5600
      10 PRESIDENT                5000
         CLERK                    4150
         ANALYST                  6000
         MANAGER                  8275
         SALESMAN                 5600
         PRESIDENT                5000
      10                          8750
      20                         10875
      30                          9400
                                 29025
-----------------------
# group by 에 사용되는 컬럼이 3개인 경우
-----------------------

// 샘플 데이터 만들기
성별을 가지는 각각 다른 sal로 테이블 만들어 주기
select *
from emp e, (select level as no
             from dual
             connect by level <= 2) t;

drop table t1 purge;

create table t1
as
select decode(no, 1, empno, empno+1000) as empno,
       ename,
       round(sal * (1 + dbms_random.value)) as sal,
       job,
       decode(no, 1, 'M', 'W') as gender,
       deptno
from emp e, (select level as no
             from dual
             connect by level <= 2) t;

select * from t1;


// 부서별, 잡별, 성별 평균 셀러리
select deptno, job, gender, avg(sal)
from t1
group by deptno, job, gender
order by 1, 2, 3;

>> ROLLUP
select deptno, job, gender, avg(sal)
from t1
group by rollup(deptno, job, gender);

>> GROUPING SETS
select deptno, job, gender, avg(sal)
from t1
group by grouping sets((deptno, job, gender), (deptno, job), (deptno, gender), (job, gender), (deptno), (job), (gender), ());

select deptno, job, gender, avg(sal)
from t1
group by grouping sets((deptno, job, gender), (deptno, job), (deptno), ());

>> CUBE
select deptno, job, gender, avg(sal)
from t1
group by cube(deptno, job, gender);

-----------------------
## Grouping 함수
-----------------------
* 행에서 소계를 형성하는 그룹을 찾는 데 사용

drop table t2 purge;

create table t2
as
select * from emp;

update t2
set job = null
where rownum = 1;

select * from t2;

>> grouping 함수를 사용하기 전
// null 값과 소계의 null 값이 구분 되지 않는다.
with : 본 쿼리가 들어가기 전에 마치 임시 테이블이 있는것 처럼 사용

select deptno, job, sum(sal)
from t2
group by rollup(deptno, job);

with t as (select deptno, job, sum(sal) sum_sal
           from t2
           group by rollup(deptno, job))
select *
from t
where deptno is not null
and job is null;

with t as (select deptno, job, sum(sal) sum_sal
           from t2
           group by rollup(deptno, job))
select deptno, job, max(sum_sal) as sum_sal
from t
where deptno is not null
and job is null
group by deptno, job;


>> grouping 함수 사용
// 집계 여부를 0 또는 1 로 반환
0 : 0 에 해당 하는 컬럼별 소계

select deptno, job, sum(sal), grouping(deptno), grouping(job)
from t2
group by rollup(deptno, job);

select *
from (select deptno, job, sum(sal), grouping(deptno) g_deptno, grouping(job) g_job
      from t2
      group by rollup(deptno, job))
where g_deptno = 0
and   g_job in (0, 1);

cf.
   select deptno, job, gender, avg(sal), grouping(deptno), grouping(job), grouping(gender)
   from t1
   group by cube(deptno, job, gender);


-----------------------
조합열 composite columns
-----------------------

* rollup 과 cube 에서 동작

ROLLUP (a, (b, c), d)
ROLLUP ((a, b, c, d)) : (a, b, c, d)과 전채 2가지 경우만 나옴

select deptno, job, gender, count(*)
from t1
group by rollup(deptno, (job, gender));

select deptno, job, gender, count(*)
from t1
group by rollup((deptno, job, gender));

-----------------------
연결된 그룹화 concatednated grouping
-----------------------
* group by a, rollup(b), cube(c) 1*2*2 : 총 4가지의 결과가 나옴
a의 경우의 수 * rollup(b)의 경우의 수 * cube(c) 만큼의 결과 출력

SELECT department_id, job_id, manager_id,
SUM(salary)
FROM employees
GROUP BY department_id,
ROLLUP(job_id),
CUBE(manager_id);

SELECT job_id, SUM(salary), grouping(job_id)
FROM employees
GROUP BY ROLLUP(job_id)

SELECT job_id, manager_id, SUM(salary), grouping(job_id), grouping(manager_id)
FROM employees
GROUP BY CUBE(job_id, manager_id) order by 1,2;

group by a, rollup(b), cube(c)
         a         b        c     -> a, b, c
                   ()       ()    -> a, b
                                  -> a, c
                                  -> a

group by grouping sets((a, b, c), (a, b), (a, c), (a))

>> http://docs.oracle.com/cd/E11882_01/server.112/e25554/aggreg.htm#i1007098

GROUP BY ROLLUP(calendar_year, calendar_quarter_desc, calendar_month_desc),
        ROLLUP(country_region, country_subregion, countries.country_iso_code,cust_state_province, cust_city),
        ROLLUP(prod_category_desc, prod_subcategory_desc, prod_name);

GROUP BY grouping sets ((calendar_year, calendar_quarter_desc, calendar_month_desc,... ),
                        (),
                        (), ...)

===========================
SQL for Analysis and Reporting
===========================
* 계층적 검색



===========================
SQL for Modeling
===========================


===========================
 첫번째 제목
===========================

-----------------------
 두번쨰 제목
-----------------------
