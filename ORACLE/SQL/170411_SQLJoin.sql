
### 어제 이어서 단일행 함수 추가 ####

# translate()
select col1, translate(col1, '0123456789', '----------') b
from t1
where translate(col1, '0123456789', '----------') like '%---%';

// a는 그대로 x 값은 전부 찾아서 지움
select translate('xUaxUaaxU','ax', 'a')
from dual;
    TRANS
    -----
    UaUaaU

// 뒤에 ''을 넣으면 결과는 모두 null 이 나옴
select translate('xUaxUaaxU','U', '')
from dual;
    T
    -
select translate('xUaxUaaxU','U', ' ')
from dual;
    TRANSLATE
    ---------
    x ax aax

# instr()

데이터의 단어수를 알수있는 방법

drop table t1 purge;

create table t1 (no number, name varchar2(100));

insert into t1 values(1, 'oracle ora ora');
insert into t1 values(2, 'ora oracle ora oracle');
insert into t1 values(3, ' ora ora');
insert into t1 values(4, 'ora ora ');
insert into t1 values(5, 'ora ora');
insert into t1 values(6, 'ora');

commit;

col name format a30
col a    format 99

// 앞에 빈칸 없애기
select no, name, trim(' ' from name),instr(trim(' ' from name), ' ', 1, 2) a
from t1 ;

select no, name, instr(trim(' ' from name), ' ', 1, 2) a
from t1
where instr(trim(' ' from name), ' ', 1, 2) > 0;


-----------------
 일반 함수
------------------

## Decode 함수와 case 표현식

예제 1.
// 부서에 따라 월급 차증인상
> select /* decode 함수 */
deptno, sal, decode(deptno, 10, sal*1.1, 20, sal*1.2, sal) as whatif
from emp;

> select /* simple case 표현식 */
       deptno,
       sal,
       case deptno when 10 then sal*1.1
                   when 20 then sal*1.2
                   else         sal
       end as whatif
from emp;
    (심플에서는 부등호 비교를 쓸수 없다)

> select /* searched case 표현식 */
       deptno,
       sal,
       case when deptno = 10 then sal*1.1
            when deptno = 20 then sal*1.2
            else                  sal
       end as whatif
from emp;



예제 2.
//월급수준에 따라 다르게 찍히도록 함
> select empno,
       sal,
       sal/2000,
       trunc(sal/2000)
from emp;

> select empno,
       sal,
       decode(trunc(sal/2000), 0, 'low', 1, 'mid', 'high') as gubun
from emp;

> select empno,
       sal,
       case trunc(sal/2000) when 0 then 'low'
                            when 1 then 'mid'
                            else        'high'
       end as gubun
from emp;

> select empno,
        sal,
        case when sal < 2000 then 'low'
            when sal < 4000 then 'mid'
            else      'high'
        end as gubun
from emp;
  (else 를 쓰지 않으면 값이 없는 것들은 null 이 추가 됨)



## decode()
# 문제. 부서별 업무별 급여합을 매트릭스 형태로 쿼리하세요

> select deptno, sal, sal, sal, sal
from emp;

> select deptno,
        decode(deptno, 10, sal) d10,
        decode(deptno, 20, sal) d20,
        decode(deptno, 30, sal) d30,
        sal
from emp;

> select sum(sal) total,
        sum(decode(deptno, 10, sal)) d10,
        sum(decode(deptno, 20, sal)) d20,
        sum(decode(deptno, 30, sal)) d30
from emp;

> select job,
        nvl(sum(sal), 0) total,
        nvl(sum(decode(deptno, 10, sal)), 0) d10,
        nvl(sum(decode(deptno, 20, sal)), 0) d20,
        nvl(sum(decode(deptno, 30, sal)), 0) d30
from emp
group by job
order by job;

** sql1-1 pdf 계속

** to_number() 추가
fx : user 가 정의한 조건이 완전히 일치해야만 한다.
fx 수정자를 사용하므로 문자
인수와 날짜 형식 모델이 정확히 일치해야 하며 단어 May 뒤의 공백은 인식되지 않습니다.
SELECT last_name, hire_date
FROM employees
WHERE hire_date = TO_DATE('May 24, 1999', 'fxMonth DD, YYYY');

# 4-20
fx = format exact

SELECT last_name, hire_date
FROM   employees
WHERE  hire_date = TO_DATE('May 24, 1999', 'fxMonth DD, YYYY');

## 일반 함수
함수 설명
• NVL (expr1, expr2)
  NVL
    null 값을 실제 값으로 변환합니다.
• NVL2 (expr1, expr2, expr3)
  NVL2
    expr1이 null이 아닌 경우 NVL2는 expr2를 반환합니다.
    expr1이 null인 경우 NVL2는 expr3을 반환합니다.
    인수 expr1은 임의의 데이터 유형을 가질 수 있습니다.
• NULLIF (expr1, expr2)
  NULLIF
    두 표현식을 비교하여 같으면 null을 반환하고 같지 않으면 첫번째 표현식을 반환합니다.
• COALESCE (expr1, expr2, ..., exprn)
  COALESCE
    표현식 리스트에서 null이 아닌 첫번째 표현식을 반환합니다.


# 4-31 nvl, nvl2
> select empno,
     ename,
     sal,
     comm,
     sal*12 + nvl(comm, 0)               as ann_sal1,
     nvl2(comm, sal*12+comm, sal*12)     as ann_sal2,
     nvl2(comm, 'sal*12+comm', 'sal*12') as gubun
from emp;

# 4-32 NULLIF
select last_name,
       first_name,
       nullif(length(last_name), length(first_name)) as ret
from employees;

select last_name,
       first_name
from employees
where nullif(length(last_name), length(first_name))  is null;


# 4-33 COALESCE (코얼레스)

drop table t1 purge;

create table t1
as
select comm a, mgr b, empno c
from emp;

select * from t1;

select a, b, c, coalesce(a, b, c, 0) d
from t1;

cf.select a, b, c, nvl(nvl(nvl(a, b), c), 0) d
   from t1;


## 일반 함수 실습 노랑이 교제

* greatest() : 가장 큰 값
  least() : 가장 작은 값
  GREATEST, LEAST는 여러 Column (열 혹은 표현) 중에서 최댓값/최솟값 구하는 함수
  SELECT MAX(COL_1), MIN(COL_2)
  FROM TABLE_1
  요건 한 개의 Row만 리턴... 해당 컬럼의 모든 Row를 대상으로 비교
  SELECT GREATEST(COL_1, COL_2, COL_3, ...), LEAST(COL_1, COL_2, COL_3, ...)
  FROM TABLE_1

  null이 포함된 경우에는 greatest, least모두 null을 반환하는 점을 참고하자.


* dump(expr[, return_fmt [, start_position [, length]]])
  : 바이트 크기와 해당 데이터 타입 코드를 반환 한다.
  데이터 타입, 바이트 길이, 내부 표현 방식 반환

* vsize() : 바이트 길이 반환
* SIGN() : 아규먼트가 음수가 -1,0 이면 0, 양수면 1

// 부서별 분기별 입사자 쿼리
* select to_char(hiredate, 'Q'),
        decode(to_char(hiredate, 'Q'), '1', '1') as Q1,
        decode(to_char(hiredate, 'Q'), '2', '2') as Q1,
        decode(to_char(hiredate, 'Q'), '3', '3') as Q1,
        decode(to_char(hiredate, 'Q'), '4', '4') as Q1
from emp;
> select deptno,
        count(to_char(hiredate, 'Q')) total,
        count(decode(to_char(hiredate, 'Q'), '1', '1')) as Q1,
        count(decode(to_char(hiredate, 'Q'), '2', '2')) as Q1,
        count(decode(to_char(hiredate, 'Q'), '3', '3')) as Q1,
        count(decode(to_char(hiredate, 'Q'), '4', '4')) as Q1
from emp
group by deptno
order by deptno;
    DEPTNO      TOTAL         Q1         Q1         Q1         Q1
    ---------- ---------- ---------- ---------- ---------- ----------
        10          3          1          1          0          1
        20          5          1          1          0          3
        30          6          2          1          2          1



TIP)
SQL 패러럴 기능으로 다른 서버로 날라가 병렬 처리가 가능하다
간단한 sql 문을 주고 받는것보다 io 를 줄이고 sql 문에서 해결하는게 성승상 더 좋다.
SQL 문사에는 FOR, IF 문 등이 없는게 좋다.
대부분의 완성된 결과를 RETURN 받아 화면에 노출하는 역할만 하는 것이 좋다.


===========================
 6장 조인
===========================

----------------
select *
from emp e, dept d            -- Join Statement
where e.deptno = d.deptno     -- Join Predicate
and e.sal >= 1000             -- Non-Join Predicate
and e.job = 'MANAGER'         -- Non-Join Predicate
and d.deptno = 10             -- Non-Join Predicate(Single-Row Predicate)
order by 1;
----------------

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

sort marge hash join


* outer 조인: 반환되는 결과중 부족한 쪽에 더하기

## join >> SQL: 1999 Syntax
---------------
SELECT table1.column, table2.column
FROM table1
[NATURAL JOIN table2] |
[JOIN table2 USING (column_name)] |
[JOIN table2
ON (table1.column_name = table2.column_name)]|
[[LEFT|RIGHT|FULL] OUTER JOIN table2
ON (table1.column_name = table2.column_name)]|
[CROSS JOIN table2];
---------------
참고: Equijoin은 Simple Join 또는 Inner Join이라고도 합니다.

(1) Cross join
//카르테시안 프러덕트
> select *
from emp CROSS JOIN dept;
또는
> select *
from emp, dept;
  (가독성을 위해 표현 사용)

(2) Natural join
//자연스럽게 같은 이름의 컬럼으로 조인함
> select *
from emp NATURAL JOIN dept;

===> Natural join 의 문제: 같은 이름의 컬럼이 모두 조인 조건에 사용된다.!!
employees, departments 테이블의 동일한 컬럼명이 2개있다.

    (3) Natural join의 문제 해결 방법 1 : Join Using

        select *
        from employees e JOIN departments d USING (department_id);

        • USING 절에 사용되는 열을 한정하지 마십시오. (where 절에 using 절에 사용한 컬럼 사용)
        • 동일한 열이 SQL 문의 다른 곳에서 사용되는 경우 alias를 지정하지 마십시오.
        • 어디에서도 그 컬럼 사용 할 때 테이블 명을 쓰면 안된다.

    (4)  Natural join의 문제 해결 방법 2 : Join On

        select *
        from employees e JOIN departments d ON (e.department_id = d.department_id);

(5) Outer join
// department 중에 employees id 를 가지고 있지 않은 190 도 반환됨
> select *
from employees e , departments d
where e.department_id (+) = d.department_id
order by 1;

> select *
from employees e RIGHT OUTER JOIN departments d on (e.department_id = d.department_id)


------
// employees 중에 department id 를 가지고 있지 않은 Kimberely 도 반환됨
> select *
from employees e , departments d
where e.department_id = d.department_id (+)
order by 1;

> select *
from employees e LEFT OUTER JOIN departments d on (e.department_id = d.department_id);

-----
> select *
from employees e , departments d
where e.department_id (+) = d.department_id (+)
order by 1; -- ERROR

> select *
from employees e FULL OUTER JOIN departments d on (e.department_id = d.department_id)


## Oracle Syntax vs SQL:1999 Syntax

** EQUJOIN
select *
from emp e, dept d
where e.deptno = d.deptno;

=> select *
   from emp e NATURAL JOIN dept d;

=> select *
   from emp e JOIN dept d USING (deptno);

=> select *
   from emp e JOIN dept d ON (e.deptno = d.deptno);
 ---
** NonEqui JOIN
단) join on 밖에 표현되지 않는다.
select *
from emp e, salgrade s
where e.sal >= s.losal and e.sal <= s.hisal;

=> select *
   from emp e JOIN salgrade s ON (e.sal >= s.losal and e.sal <= s.hisal);

** SELF JOIN
단) join on 밖에 표현되지 않는다.
select *
from emp w, emp m
where w.mgr = m.empno;

=> select *
   from emp w JOIN emp m ON (w.mgr = m.empno);

** OUTER JOIN 은 outer join 으로 함

## 노랑이 교제 문제
p210
문제 6-2
> select e.last_name as name, e.salary as sal, j.grade_level as grade_level
from employees e, job_grades j
where e.salary between j.lowest_sal and j.highest_sal;

문제 6-3
> select e.last_name, nvl(d.department_name, 'WAITING')
from employees e, departments d
where e.department_id = d.department_id(+);

문제 6-6
> select e.last_name as name, d.department_name as dept
from employees e
  JOIN departments d
  on e.department_id = d.department_id;

문제 6-7
> select e.last_name, e.salary, j.grade_level
from employees e
  join job_grades j
  on e.salary between j.lowest_sal and j.highest_sal;

## SQL1-2 pdf 단원 6
3) HR 부서에서 Toronto에 근무하는 사원에 대한 보고서를 요구합니다. Toronto에서 근무하는 모든 사원의 성, 직무, 부서 ID 및 부서 이름을 표시합니다.

> SELECT e.last_name, e.job_id, e.department_id,
d.department_name
FROM employees e JOIN departments d
ON (e.department_id = d.department_id)
JOIN locations l
ON (d.location_id = l.location_id)
WHERE LOWER(l.city) = 'toronto';


## 3 개 이상의 조인
* (join(join)) : 3 개이상 조인 가능
(join salgrade s on (e.sal detween s.losal and s.hisal)(emp e join dept d on (e.deptno = d.deptno)))

// 오라클
selec e.empno, e.ename, e.sal, d.*, s.*
from emp e, dept d, salgrade s
where e.deptno = d.deptno
      and e.sal detween s.losal and s.hisal;
      and e.sal >=1200;

// ansi 표준 (join 과 where 의 필터 구분이 확실하다.)
selec e.empno, e.ename, e.sal, d.*, s.*
from emp e join dept d on (e.deptno = d.deptno)
          join salgrade s on (e.sal detween s.losal and s.hisal);
where e.sal >=1200;


===========================
 7장 Subquery
===========================

# 란?
  - 다른 SQL 에 포함된 select
  - 해석 순서 : 서브쿼리 부터
  - 실행 순서 : 실행 계획을 봐야 알 수 있음

create table t1 as select ...
create view v1 as select
insert into ...

# 서브쿼리 분류
  - Single-row Subquery
  - Multiple-row Subquery
  - Multiple-column Subquery : 결과 값이 두 개 이상의 컬럼을 반환하는 Subquery이다. ex) 두개 이상의 컬럼 empno, sal, deptno 3개의 컬럼이 반환됨
    부서별 사원 중 급여를 가장 많이 받는 사원의 정보를 출력
    SELECT *
    FROM JUNG_EMP
    WHERE (J_DEPTNO,J_SAL) IN(
                      SELECT J_DEPTNO, MAX(J_SAL)
                      FROM JUNG_EMP
                      GROUP BY J_DEPTNO);

  - Inline-view : from 절의 Subquery

  - Scalar Subquery
      : 1행 1열 리턴하는 평범한 서브쿼리,
        groub by 를 제외한 모든곳에 사용 가능

  - Correlated Subquery
      : Subquery 에서 메인 쿼리의 정보를 사용

-----------------------
 Single-row
-----------------------
# 문제. 'CLARK'보다 많은 급여를 받는 사원

col sal new_value v_sal

select sal
from emp
where ename = 'CLARK';

select empno, sal
from emp
where sal > &v_sal;

   --

select e.empno, e.sal
from emp e, emp c
where c.ename = 'CLARK'
and e.sal > c.sal;

   --

select empno, sal
from emp
where sal > (select sal
             from emp
             where ename = 'CLARK');

문제.회사의 평균 급여보다 많은 급여를 받는 사원

select empno, sal
from emp
where sal > (select avg(sal)
             from emp);

문제.최저 급여자

select empno, sal
from emp
where sal = (select min(sal)
             from emp);



-----------------------
 Multiple-row
-----------------------

문제. 근무하는 사원이 있는 부서

select *
from dept
where deptno in (select deptno
                 from emp);

문제. 여러건을 부등호 비교해야 할 경우
//all, any, max, min
// 세일즈맨 전부보다 월급이 큰 사람
select empno, sal
from emp
where sal > all (select sal
                 from emp
                 where job = 'SALESMAN');

select empno, sal
from emp
where sal > (select max(sal)
             from emp
             where job = 'SALESMAN');

// 세일즈맨 전부보다 월급이 작은 사람
select empno, sal
from emp
where sal < all (select sal
                 from emp
                 where job = 'SALESMAN');

select empno, sal
from emp
where sal < (select min(sal)
             from emp
             where job = 'SALESMAN');

             --

select empno, sal
from emp
where sal > any (select sal
                from emp
                where job = 'SALESMAN');

select empno, sal
from emp
where sal > (select min(sal)
            from emp
            where job = 'SALESMAN');


 --

select empno, sal
from emp
where sal < any (select sal
                from emp
                where job = 'SALESMAN');

select empno, sal
from emp
where sal < (select max(sal)
            from emp
            where job = 'SALESMAN');



-----------------------
 Inline-view
-----------------------

* from 에 가까울수록 큰 테이블 멀어질 수록 작은 테이블을 놓는 것이 관습이다.

문제.소속 부서의 평균 급여보다 많은 급여를 받는 사원

select deptno, avg(sal) avg_sal
from emp
group by deptno;

select e.empno, e.sal, d.*
from emp e,
    (select deptno, avg(sal) avg_sal
     from emp
     group by deptno) d
where e.deptno = d.deptno
and e.sal > d.avg_sal;



-----------------------
 Scalar Subquery
-----------------------
* 전부 가능 하지만 group by 만 제외

select empno, ename, sal, (select avg(sal) from emp) as avg_sal
from emp;

select empno, ename, mgr, (select ename from emp where empno = e.mgr) as mgr_name
from emp e;

select empno, ename, deptno
from emp e
order by (select dname
          from dept
          where deptno = e.deptno);



cf.) where, having 절에는 부모자식의 관계가 되어 서로의 값을 사용할 수 없지만
Inline-view, scalar subquery 인경우 동급이 되어 사용 가능하다.


**
