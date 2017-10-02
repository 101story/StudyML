
프로그램: 해야할 일을 미리 기술해 놓은 것

#### SQL 분류, select 보기 ####

** SQL 환경 설정 보기
>show all
linesize, pagesize 조정하기
>set linesize 200
>set pagesize 40

** 마지막에 수행한 명령어
>list 또는 l

** 마지막 수행항 명령어 수행
>run, r,
>/  (명령어 안보여주고 수행)

** SQL
https://en.wikipedia.org/wiki/SQL@QUERIES
Queries allow the user to describe desired data

** SQL 주석
--

** SQL 분류
DDL : 데이터 정의 CREATE, ALTER, DROP, RENAME, TRUCATE, COMMENT
DML : 데이터 제어 INSERT, UPDATE, DELETE, MERGE, SELECT
TCL : COMMIT, ROLLBACK, SAVEPOINT
DCL : GRANT, REVOKE

DDL, DCL 은 자동 커밋됨

Transction : DML 의 모음

** 다른 유저의 테이블 보기
SQL> select * from DREAM30.friends;

** select statement
select
from
where
group by
having
order by

//실행순서는 그떄 그떄 다르다.
//select 문장을 작성하거나 해석할 떄 권장 순서
select deptno, sum(sal) --4 (mandatory)
from emp                --1 (mandatory)
where sal >=1000        --2
group by deptno         --3
having sum(sal) >=2000  --5
order by deptno;        --6

** where 절 이해
candidate row (후보행)을 검증해서 T,F,N 가운데 하나를 리턴하는 절
where 절이 T 를 리터해야 후보행이 리턴된다.

select *
from emp
where sal >=1500;

** SQL 쿼리 결과 데이터 리턴풀
운반단위
>show array

** Null
0, space 도 아니다.
null 과 null 은 비교 할수 없다. (모른다.)
산술연산 -> null
비교연산 -> null
논리연산 -> 진리표

//하나만 F 여도 전부 F
T and N = N
F and N = F
N and N = N
//하나만 T 여도 전부 T
T or N = T
F or N = N
N or N = N

SQL> select * from emp where comm=null; --엉터리
SQL> select * from emp where comm is null; --제대로

SQL> select * from emp where sal >= 1500 and job='SALESMAN';

** 실행계획보기
>set autot on
>set timing on

** join
from 절의 테이블의 갯수가 2개 이상
//가능한 모든 경우의 수로 join 시킴
//꼭 나쁜건 아님 행을 복제 시켜야 하는 경우 사용함 from 절에 나오는 table의 row 갯수의 곱만큼 복사 시킴
SQL> select *
  2  from emp, dept;
row14*row4=56 개 결과

more than one (1개 초과: 2개이상)

* 조인은 곱셈 연산이다!

  select count(*)
  from (select level as no from dual connect by level <= 100),
       (select level as no from dual connect by level <= 100),
       (select level as no from dual connect by level <= 100);

//56번의 비교로 T 결과를 리턴함
SQL> select *
from emp, dept
where emp.deptno = dept.deptno
order by 1;

** alias 별명 붙이기
//총 70번의 수행이 됨
> select *
from emp e, salgrade s
where e.sal >= s.losal and e.sal <= s.hisal
order by 1;

> select s.grade, count(*), avg(e.sal)
from emp e, salgrade s
where e.sal >= s.losal and e.sal <= s.hisal
group by s.grade
order by grade desc;

//띄어쓰기 사용시 " " 이용
> select s.grade, count(*), avg(e.sal) as "sal avg"
from emp e, salgrade s
where e.sal >= s.losal and e.sal <= s.hisal
group by s.grade
order by grade desc;

단!!) 컬럼명에 사용한 별칭은 group by 에서 사용할 수 없다.

이퀴조인, 넌이퀴조인, 셀프조인
EQUJOIN, NON-EQUJOIN, OUTER JOIN, SELF JOIN

** 용어
select *
from emp e, dept d            -- Join Statement
where e.deptno = d.deptno     -- Join Predicate
and e.sal >= 1000             -- Non-Join Predicate
and e.job = 'MANAGER'         -- Non-Join Predicate
and d.deptno = 10             -- Non-Join Predicate(Single-Row Predicate)
order by 1;

from 절 join statement
where 절 join predicate
조건 non-join predicate
결과가 한개인 조건 non-join predicate(single row predicate)

조인조건 = 조인 수로부 = 조인 연산자

** Oracle Syntax
  - Equi join : 조인의 연산자가 =
  - Non-Equi join : 조인의 연산자가 >=
  - Self join : 자기 자신과의 조인
  - Outer join : 값이 부족한 부분까지 추가로 보여줌(+)

      [1] Oracle Syntax
          - Equi join
          - NonEqui join
          - Self join
          - Outer join

      [2] SQL:1999 Syntax
          - Cross join
          - Natural join
          - Join Using
          - Join On
          - Outer join

cf.상호 관련 서브쿼리로 해결
  select empno, ename, mgr, (select ename from emp where empno = e.mgr) as ename
   from emp e;


  (4) Outer join
   select *
   from emp w, emp m
   where w.mgr = m.empno (+)
   order by 1;


** 문제 누적합 구하기

# 문제.누적합 구하기
       A          B      누적
-------- ---------- ---------
    7369        800       800
    7499       1600      2400
    7521       1250      3650

select *
from (select empno a, sal b
      from emp
      where rownum<=3);

> drop table t1;
> create table t1
as
select empno c1, sal c2
from emp
where rownum<=3;

SQL> select * from t1 a, t1 b;

        C1         C2         C1         C2
---------- ---------- ---------- ----------
      7369        800       7369        800
      7369        800       7499       1600
      7369        800       7521       1250
      7499       1600       7369        800
      7499       1600       7499       1600
      7499       1600       7521       1250
      7521       1250       7369        800
      7521       1250       7499       1600
      7521       1250       7521       1250

> select a.c1, a.c2, sum(b.c2) as cumulative
from t1 a, t1 b
where a.c1 >= b.c1
group by a.c1, a.c2
order by 1, 2;

** 컬럼 출력 길이 조절
SQL> col first_name format a10
SQL> SELECT first_name from employees;

** 널값 먼저 정렬
SQL> select empno, ename, sal, comm, deptno
  2  from emp
  3  order by comm nulls first;

** 리터럴
SQL> select ename ||' works ' || job from emp;

** between
//begin date와 end date 사이에 20070302가 있는 것
SQL> select * from t1_history
where '20070302' between begin_date and end_date

** 부서가 20, 50, 80 인 사람 구하는 다양한 방법
SQL> select employee_id, last_name, department_id from employees
  2  where department_id=20
  3  union all
  4  select employee_id, last_name, department_id from employees
  5  where department_id=50
  6  union all
  7  select employee_id, last_name, department_id from employees
  8  where department_id=80;

  SQL> select employee_id, last_name, department_id from employees
    2  where department_id in (20,50,80);

** having 절
5명 이상 근무하는 부서 및 인원수 쿼리
SQL> select deptno, count(*)
  2  from emp
  3  group by deptno
  4  having count(*) >=5
  5  order by count(*);

SQL> select deptno, count(*)
  2  from emp
  3  where count(*) >= 5
  4  group by deptno;
where count(*) >= 5
      *
ERROR at line 3:
ORA-00934: group function is not allowed here

SQL> select deptno, count(*)
  2  from emp
  3  group by deptno
  4  having count(*) >= 5;

    DEPTNO   COUNT(*)
---------- ----------
        30          6
        20          5
//having 절의 경우 전체 데이터를 집단화 하고 연산을 수행하게 된다.

** Like 문법
Like : % (zero or many)
       _ (only one)
  SQL> select ename from emp where ename like 'M%';

  ENAME
  ----------
  MARTIN
  MILLER

  SQL> select ename from emp where ename like '_A%';

  ENAME
  ----------
  WARD
  MARTIN
  JAMES

** 날짜 포맷 맞추기
alter session set nls_date_format='YYYY/MM/DD';

** 테이블 완전히 지우기
> drop table t1 purge;

** distinct
중복제외(unique와 비슷)
SQL> select distinct comm from emp;

** scott 유저 사용하기
C:\Users\student>copy ic.bat scott.bat
      1개 파일이 복사되었습니다.
C:\Users\student>notepad scott.bat
scott/tiger

대용량 데이터베이스 도서


__
