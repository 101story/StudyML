

### SQL*PLUS 툴 이해

SQL : DML, DDL, TCL, DCL
Objects: table, view, index, sequence, synonym
SQL*PLUS 툴

** SQL*Plus Commands
환경설정 : set, show
결과포맷 : colum, ttitle, btitle, break
명령편집 : list(l), input, append, delete, 숫자, change
파일편집 : edit  파일이름 : 생성 or 편집
           save  파일이름 : 버퍼 -> 파일
           get   파일이름 : 파일 -> 버퍼
           start 파일이름 : 파일 -> 버퍼 -> 실행
           (= @ 파일이름)
           spool 파일이름 ~ spool off
치환변수 : &, &&, define, undefine, accept, 숫자

** 환경설정
SQL> show all
SQL> show user
SQL> show under
SQL> show underline
SQL> exit

** 결과포맷
SQL> select department_id, employee_id, last_name, salary from employees;
//컬럼 포맷 자리수 조절
> column last_name format a10
> / (마지막 실행)

// 숫자 컬럼 포맷 지정
> col salary format 999,999.99

// 컬럼 3자리로 줄이기
> col employee_id heading ENO format 999

// 컬럼 명령어 설정 정보
> col

// 컬럼 설정 정보 지우기
> clear col
> col employee_id clear

// 컬럼해딩 2줄로 바꾸기 (|)
> col department_id heading DEPT|NO

// 쿼리 결과를 리포트 파일에 담아라
SQL> ed sal_report.sql
    spool salary_report.txt
    select department_id, employee_id, last_name, salary from employees;
    spool off;
SQL> @sal_report.sql

// 리포트 제목 붙이기 머릿글
날짜 , 제목, 페이지 노출
> set linesize 80
> tti 'Salary|Report'

// feed 피드백 결과 비노출 설정
> show feed
> set feedback off

// break 반복되는 값 생략하기
> break on department_id  skip 1
  --> 중간에 한줄 띄기
> break on department_id  skip page
  --> 한페이지씩 (컬럼이 반복되어 나옴)
> clear break;
  --> break 해제

// 바닥글 넣기
> bti 'confidential'
> bti off;

//verify 검증 설정
old 와 new 안보여주기
> set verify off

// 변수 값 받기
select department_id, employee_id, last_name, salary from employees
where deptno in (&deptno);
실행시 변수 값 받기

// 변수 값 받는 prompt 변경하기
accept

** sal_report 최종 sql 문서

    set linesize 60
    set pagesize 40
    set feedback off
    set verify off

    tti 'Salary|Report'
    bti 'Confidential'
    break on department_id skip 1

    col last_name     format a15
    col salary        format 999,999.99
    col employee_id   heading ENO    format 99999999
    col department_id heading DEPTNO format 99999999

    spool salary_replort.txt

    accept deptno prompt 'Enter DEPTNO Please : '

    select department_id, employee_id, last_name, salary
    from employees
    where department_id in (&deptno)
    order by department_id, salary desc, last_name;

    spool off

    tti off
    bti off
    clear break

    col last_name     clear
    col salary        clear
    col employee_id   clear
    col department_id clear

    set linesize 200
    set pagesize 40
    set feedback on
    set verify on

**

** 편집명령
현재 버퍼에 있는 sql 명령어 변경해서 사용하기
* 는 현위치

// 추가하기
SQL> list
  1  select empno
  2* from emp
SQL> input
  3  where deptno=10;

     EMPNO
----------
      7782
      7839
      7934

3 rows selected.
SQL> list
  1  select empno
  2  from emp
  3* where deptno=10

// 변경하기
SQL> list
  1  select empno
  2  from emp
  3* where deptno=10
SQL> l
  1  select empno
  2  from emp
  3* where deptno=10
SQL> c/10/20
  3* where deptno=20
SQL> l
  1  select empno
  2  from emp
  3* where deptno=20

// 현재 줄 변경해서 a 어팬드로 붙이기
  SQL> l
    1  select empno
    2  from emp
    3* where deptno=20
  SQL> 1
    1* select empno
  SQL> a , ename
    1* select empno, ename
  SQL> l
    1  select empno, ename
    2  from emp
    3* where deptno=20

// 마지막에 추가하고 해당 리스트 보기
SQL> l
  1  select empno, ename
  2  from emp
  3* where deptno=20
SQL> i
  4  and job='MANAGER'
  5  order by empno;

     EMPNO ENAME
---------- ----------
      7566 JONES

1 row selected.
SQL> l
  1  select empno, ename
  2  from emp
  3  where deptno=20
  4  and job='MANAGER'
  5* order by empno
SQL> l 4
  4* and job='MANAGER'

// 삭제하기
SQL> del (현재)
SQL> l
  1  select empno, ename
  2  from emp
  3  where deptno=20
  4* order by empno
SQL> del 1 2 (해당라인)

----> 이렇게 안하고 ed 명령으로 편집기로 바로 편집 가능 (실행은 run, r, /)

** 치환변수
& - define 에 저장되지 않음
&&, &1, accept, col - define 에 저장됨
&1, &2 ... : 실행시 변수로 입력받음


# 파일편집

  SQL> select * from emp
    2  where deptno = 30
    3  and sal >= 1000;

  SQL> save s001.sql

  SQL> select * from dept;
  SQL> l

  SQL> start s001

  SQL> cl buff

  SQL> get s001
  SQL> l
    1  select * from emp
    2  where deptno = 30
    3* and sal >= 1000

  SQL> 2

  SQL> c/30/10
    2* where deptno = 10

  SQL> r

  SQL> ed s002.sql

    select *
    from dept
    where loc like 'NEW%';

  SQL> @s002

# 치환변수(Substitution Variables)

  - 변수     ≒ 그릇
  - 상수     ≒ 그릇
  - 매개변수 ≒ 그릇

  SQL> define
  SQL> define v1 = 100
  SQL> define v1
  SQL> define

  SQL> undefine v1
  SQL> define

  SQL> ed sv01

    set verify off

    accept amu number prompt 'Enter deptno please : '

    select *
    from emp
    where deptno = &amu;

    set verify on

  SQL> @sv01
  Enter value for amu: 30

  SQL> ed sv02

    select *
    from emp
    where ename = '&name';

  SQL> @ sv02

  SQL> ed sv03

    select empno, &&col1
    from emp
    order by &col1;

    undefine col1

  SQL> @ sv03
  Enter value for col1: sal

  SQL> @sv03
  Enter value for col1: deptno

  SQL> ed sv04

    select empno, ename, sal
    from &1
    where deptno = &2
    order by &3;

  SQL> @sv04 emp 30 empno
  SQL> @sv04 emp 10 sal

  SQL> ed sv05

    prompt Salary Report

    col avg_sal new_value sv_avg_sal

    select avg(sal) as avg_sal
    from emp
    where deptno = &1;

    select *
    from emp
    where deptno = &1
    and sal > &sv_avg_sal;

  SQL> @sv05 10
  SQL> @sv05 30

# SQL

  https://en.wikipedia.org/wiki/SQL

# SQL 분류

  - DDL : CREATE, ALTER, DROP, RENAME, TRUCATE, COMMENT
  - DML : INSERT, UPDATE, DELETE, MERGE, SELECT
  - TCL : COMMIT, ROLLBACK, SAVEPOINT
  - DCL : GRANT, REVOKE

# SELECT 이해

  - 검색, 조회, 질의, ...
  - Queries allow the user to describe desired data.

  select empno, ename, sal, job
  from emp;

  select sal, sal, sal, sal    -- 컬럼 복제
  from emp;

  select sum(sal), avg(sal), max(sal), min(sal)
  from emp;

  select empno, ename, sal, sal*1.3
  from emp;

# SELECT Statement

  * SELECT 문장을 작성하거나 해석할 때 권장 순서 (절대 실행순서 아님)

  SELECT   deptno, sum(sal)  -- 4 (mandatory)
  FROM     emp               -- 1 (mandatory)
  WHERE    sal >= 1000       -- 2
  GROUP BY deptno            -- 3
  HAVING   sum(sal) >= 2000  -- 5
  ORDER BY deptno            -- 6
  ;

# Where절 이해

  * candidate row를 검증해서 T, F, N 가운데 하나를 리턴하는 절인데
    where절이 T를 리턴해야 후보행(candidate row)이 리턴된다.

  select * from emp where sal >= 1500;
  select * from emp where sal >= 1500 and job = 'SALESMAN';

  select * from emp where comm = null;   -- 엉터리
  select * from emp where comm is null;  -- 제대로

  select ename, lower(ename), sal, sal * 1.2
  from emp
  where sal >= 1000;

  drop table t1 purge;
  create table t1 as select * from emp where 1 = 2;

  drop table t1 purge;
  create table t1 as
  select empno a, deptno b from emp where deptno = 10;

# Join

  * 용어

    select *
    from emp e, dept d            -- Join Statement
    where e.deptno = d.deptno     -- Join Predicate
    and e.sal >= 1000             -- Non-Join Predicate
    and e.job = 'MANAGER'         -- Non-Join Predicate
    and d.deptno = 10             -- Non-Join Predicate(Single-Row Predicate)
    order by 1;

  * Syntax

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

  * 조인은 곱셈 연산이다!

    select count(*)
    from (select level as no from dual connect by level <= 100),
         (select level as no from dual connect by level <= 100),
         (select level as no from dual connect by level <= 100);

# Join >> Oracle Syntax

 (1) Equi join

  select *
  from emp, dept
  order by 1;

  select *
  from emp e, dept d
  where e.deptno = d.deptno
  order by 1;

 (2) NonEqui join

  select *
  from emp, salgrade
  order by 1;

  select *
  from emp e, salgrade s
  where e.sal >= s.losal and e.sal <= s.hisal
  order by 1;

  select s.grade, count(*), avg(e.sal)
  from emp e, salgrade s
  where e.sal >= s.losal and e.sal <= s.hisal
  group by s.grade
  order by grade desc;

 (3) Self join

  select *
  from emp w, emp m
  order by 1;

  select *
  from emp w, emp m
  where w.mgr = m.empno
  order by 1;

  select w.empno, w.ename, m.empno, m.ename
  from emp w, emp m
  where w.mgr = m.empno
  order by 1;

  # 문제.ALLEN 보다 SAL이 많은 사원?

    select *
    from emp e, emp a;

    select *
    from emp e, emp a
    where a.empno = 7499;

    select *
    from emp e, emp a
    where a.empno = 7499
    and e.sal > a.sal;

    select e.empno,
           e.sal,
           a.empno,
           a.sal,
           e.sal - a.sal as diff
    from emp e, emp a
    where a.empno = 7499
    and e.sal > a.sal
    order by diff desc;

  cf.상호 관련 서브쿼리로 해결

     select empno, ename, mgr, (select ename from emp where empno = e.mgr) as ename
     from emp e;

 (4) Outer join

  select *
  from emp w, emp m
  where w.mgr = m.empno (+)
  order by 1;

# 문제.누적합 구하기

         A          B      누적
  -------- ---------- ---------
      7369        800       800
      7499       1600      2400
      7521       1250      3650

  drop table t1;

  create table t1
  as
  select empno c1, sal c2
  from emp
  where rownum <= 3;

  select *
  from t1;

  select *
  from t1 a, t1 b;

  select *
  from t1 a, t1 b
  where a.c1 >= b.c1
  order by 1, 2;

  select a.c1, a.c2, sum(b.c2) as cumulative
  from t1 a, t1 b
  where a.c1 >= b.c1
  group by a.c1, a.c2
  order by 1, 2;

# Cartesian Product는 항상 나쁘다??!!
  -- 없는 컬럼은 null 로 맞춰줌
  select deptno, job, sum(sal)
  from emp
  group by deptno, job
  union all
  select deptno, null, sum(sal)
  from emp
  group by deptno
  union all
  select null, null, sum(sal)
  from emp
  order by 1, 2;

     ---

  select *
  from (select deptno, job, sum(sal) as sum_sal
        from emp
        group by deptno, job) e,
       (select level as no
        from dual
        connect by level <= 3) n
  order by n.no;
  ▼
  select decode(n.no, 1, deptno, 2, deptno) as deptno,
         job,
         sum_sal,
         no
  from (select deptno, job, sum(sal) as sum_sal
        from emp
        group by deptno, job) e,
       (select level as no
        from dual
        connect by level <= 3) n
  order by n.no;
  ▼
  select decode(n.no, 1, deptno, 2, deptno) as deptno,
         decode(n.no, 1, job) as job,
         sum_sal,
         no
  from (select deptno, job, sum(sal) as sum_sal
        from emp
        group by deptno, job) e,
       (select level as no
        from dual
        connect by level <= 3) n
  order by n.no;
  ▼
  select decode(n.no, 1, deptno, 2, deptno) as deptno,
         decode(n.no, 1, job) as job,
         sum(sum_sal)
  from (select deptno, job, sum(sal) as sum_sal
        from emp
        group by deptno, job) e,
       (select level as no
        from dual
        connect by level <= 3) n
  group by decode(n.no, 1, deptno, 2, deptno),
           decode(n.no, 1, job)
  order by 1, 2;

     ---

  select deptno, job, sum(sal)
  from emp
  group by rollup(deptno, job);

# desc.sql

  SQL> ed desc.sql

       set linesize 50
       desc &1
       set linesize 200

  SQL> @desc emp

# View

  - Named Select!
  - Query Transformation

  create or replace view v1
  as
  select empno, ename
  from emp
  where deptno = 10;

  select *
  from v1
  where ename like 'A%';

# print_table 프로시져

  - http://cafe.naver.com/n1books/14 첨부 파일 다운로드

  SQL> @"C:\Users\student\Desktop\print_table .sql"

  SQL> set serveroutput on
  SQL> exec print_table('select * from employees')

  SQL> exec pt('select * from employees')
  SQL> exec pt('select * from emp where ename = ''ALLEN'' ')

  SQL> create or replace view v1
       as
       select e.empno, e.ename, d.*
       from emp e, dept d
       where e.ename like 'A%'
       and d.deptno = 10;

  SQL> exec pt('select * from v1')

=====================
 1장
=====================

# 1-11

  가공 -> 연산 - 산술
               - 연결
               - 논리
               - ...

       -> 함수 - Vendor-supplied function - Single-row function
                                          - Multiple-row function
               - User-defined function    - Single-row function
                                          - Multiple-row function

# 1-15

  select empno,
         sal,
         comm,
         sal*12 + nvl(comm, 0)    ann_sal,
         sal*12 + nvl(comm, 0) as ann_sal,
         sal*12 + nvl(comm, 0)    "$Ann Sal"
  from emp;

# 1-20 concatenation operator, literal

  select empno, ename||' is a '||job as sawon
  from emp;

  select empno,
         'Dear '||ename||'! '||chr(10)||
         'your salary from '||sal||' to '||sal*1.2 as kidding
  from emp;

  select 'drop table '||tname||
         ' cascade constrants;' as commands
  from tab
  where tname like 'E%';

# 1-23

  select ename||'''s house is bigger than Tom''s'     from emp;
  select ename||q'!'s house is bigger than Tom's!' from emp;
  select ename||q'X's house is bigger than Tom'sX' from emp;

# 1-24

  select unique   deptno from emp;
  select distinct deptno from emp;

  select distinct deptno, job
  from emp
  order by 1, 2;

  select empno, sal as salary
  from emp
  where salary > 1000;

=====================
 2장
=====================

# 2-11

  select * from emp
  where mgr = 7698;

  select * from emp
  where mgr = 7839;

  select * from emp
  where mgr = 7788;

    ---

  select * from emp
  where mgr = 7698
  union all
  select * from emp
  where mgr = 7839
  union all
  select * from emp
  where mgr = 7788;

    ---

  select * from emp
  where mgr in (7698, 7839, 7788);

  select * from emp
  where mgr = 7698 or mgr = 7839 or mgr = 7788;

    ---

  select * from emp
  where mgr not in (7698, 7839, 7788);

  select * from emp
  where mgr != 7698 and mgr != 7839 and mgr != 7788;

# 2-12

  select * from emp
  where ename like 'A%';

  select * from emp
  where ename like '_____';

   ---

  >> 중간에 포함된 A_A 찾기

  drop table t1 purge;

  create table t1 (col1 varchar2(30));

  insert into t1 values ('AAA');
  insert into t1 values ('ABA');
  insert into t1 values ('ACA');
  insert into t1 values ('A_A');

  commit;

  select * from t1 where col1 like '%A_A%';              -- 엉터리
  select * from t1 where col1 like '%A!_A%' escape '!';  -- 제대로

# 2-14

  select * from emp where comm = null;    -- 엉터리
  select * from emp where comm is null;   -- 제대로

  cf.

     select * from emp where empno = empno;
     select * from emp where comm = comm;

# 2-23

  select empno, ename, sal salary from emp order by sal;
  select empno, ename, sal salary from emp order by salary;
  select empno, ename, sal salary from emp order by 3;

  select empno, ename, sal salary from emp order by hiredate;

  select deptno, ename, sal from emp order by deptno, sal desc;

  select * from emp order by comm;
  select * from emp order by comm nulls first;

  select * from emp order by comm desc;
  select * from emp order by comm desc nulls last;

# 실습

  문제.월별 정렬 (가공한 결과에 의한 Order by)

    select empno, hiredate, to_char(hiredate, 'MM')
    from emp;

    select empno, hiredate, to_char(hiredate, 'MM')
    from emp
    order by to_char(hiredate, 'MM');

    select empno, hiredate
    from emp
    order by to_char(hiredate, 'MM');

  문제.SQL Yellow p.117 상단

    select to_char(hiredate, 'day')
    from emp
    where rtrim(to_char(hiredate, 'day')) = 'tuesday';

    select to_char(hiredate, 'day')
    from emp
    where to_char(hiredate, 'day') like 'tues%';

  문제.jb 출제

    select empno, sal, sal*1.1, s.*
    from emp e, salgrade s
    order by 1;

    select e.empno,
           e.sal,
           s.grade
    from emp e, salgrade s
    where e.sal >= s.losal and e.sal <= s.hisal
    order by 1;

    select e.empno,
           e.sal,
           (select grade
            from salgrade s
            where e.sal >= s.losal and e.sal <= s.hisal) ret1,
           e.sal*1.1,
           (select grade
            from salgrade s
            where e.sal*1.1 >= s.losal and e.sal*1.1 <= s.hisal) ret2
    from emp e
    order by 1;

    select *
    from (select e.empno,
                 e.sal,
                (select grade
                 from salgrade s
                 where e.sal >= s.losal and e.sal <= s.hisal) ret1,
                 e.sal*1.1,
                (select grade
                 from salgrade s
                 where e.sal*1.1 >= s.losal and e.sal*1.1 <= s.hisal) ret2
          from emp e)
    where ret1 != ret2
    order by 1;

# 읽기 일관성, Lock 및 Deadlock


  [Session 1]                  [Session 2]

  * 읽기 일관성

  drop table books purge;

  create table books
  (no number,
   name varchar2(10));

  insert into books
  values (1000, 'ABC');

  insert into books
  values (2000, 'SQL');

  select * from books;

                               select * from books;
                               -- session 1 변경하기 전 데이터가 보임
  commit;

                               select * from books;
                              -- session 1 변경한 데이터가 보임
  * Lock

  update books
  set name = 'JAVA'
  where no = 1000;

  select * from books;

                               select * from books;

                               update books
                               set name = 'JAVA'
                               where no = 1000;
                               | waiting!

  commit;

                               commit;

  * Deadlock

  update books
  set name = 'SQL'
  where no = 1000;

                               update books
                               set name = 'SUN'
                               where no = 2000;

  update books
  set name = 'C++'
  where no = 2000;
  | waiting!
                               update books
                               set name = 'Solaris'
                               where no = 1000;
                               | waiting!

  ORA-00060: deadlock detected
  while waiting for resource

  rollback;
