

## SQL 제대로 시작하기 ###
orale 11g pdf 교제 1장

수평조인
수직조인 unian all  같은..
만든 파일들은 SQL을 실행한 위치에 저장됨
C:\Users\student

** 오라클 join 구동 방법
내가 가진 값(포린키)에서 값의 비교를 통해 연결 테이블을 찾는다.
비교하는 시간이 오래걸린다.

** 기본 select 문
원하는 데이터를 묘사하는것.
{}: 브레이스 brace : 전체 묶음
[]: 브렉켓 bracket : 또는

(): 브랜티시스?

** SQL 접속 setting 정보
login.sql 을 만들어 놓으면 SQL 서버 접속시 login.sql 파일을 읽어 접속하는데
기본 세팅 정보를 만들어 두면 좋다.
dual : sys유저의 더미테이블

** ed desc
desc 명령어 수행시 컬럼폭이 너무 긴 불편함을 해소 하기 위해 실행문서 작성함
(ed desc.sql 확장자 생략해도됨)
desc 명령어 실행시 변수를 입력받을 수 있음
desc &1: 치환변수 &1
SQL> ed desc.sql
SQL> get desc
  1  set linesize 50
  2  desc &1
  3* set linesize 200
SQL> @desc emp

** print_table 프로시져
http://cafe.naver.com/n1books/14
pl/sql 파일 다운로드
프로시져 만들기
> set serverouput on 기능을 켜고
> exec print_table('select * from emp')
SQL> set serveroutput on
SQL> exec print_table('select * from employees')
//강사님이 만들어 놓은것 쓰기
SQL> exec pt('select * from employees')

** 실행 권한 주기
grant execute
on print_table
to public

** escape 쓰기
SQL 명령어 안에서 문자 데이터 다루기
' ': 경우 한번더 넣어 줌
SQL> exec print_table('select * from employees where ename=''ALLEN'' ')

** VIEW
- Named(이름붙여진) select
- Query Transformation
> grant create view
to public;
> create or replace view v1
as
select empno, ename
from emp
where ename like 'A%';
//속도를 빠르게 하지 않는다. 집합을 가져와 저장하는 것은 아님. 퍼포먼스와 관계가 크지 않다.
select *
from v1
where deptno = 10;

** 쿼리 결과 가공
연산
  산술
  연결
  논리
  ...
함수
  vendor-supplied function
    single-row function
    multiple-row function
  user-defined fuction
    single-row function
    multiple-row function
//연산한 결과를 바구니에 담고 그 것을 최종 결과 보낼때 같이 바구니에 담아 보냄
//연산 우선순위

** Null 연산 nvl()
> select empno, sal, comm, sal*12+comm
from emp;
Null 의 산술연산 결과는 null

nvl(comm, 0): 값이 있으면 comm 없으면 0 리턴

** 별명 붙이기
> select empno, sal, comm,
  sal*12+nvl(comm,0) ann_sal,
  sal*12+nvl(comm,0) as ann_sal,
  sal*12+nvl(comm,0) "$Ann Sal"
from emp;
//가능하면 as 를 붙여 사용하는게 가독성이 높다 emp sal 인 경우 sal 이 별명으로 인식될 수 있다.

** 리터럴 연결하기
concatenation operator , literal
: sql 문에 등장하는 문자, 숫자 값
> select empno, ename||' is a(n) '||chr(10)||job
from emp;
//리터럴 문자는 한row 마다 붙음
//chr(10) 줄바꿈

> select 'drop table '||tname||' cascade constrants;' as command
from tab
where tname like 'T1%';

** 대체 인용 (q) 연산
> select ename||'''s house is bigger than Tom''s' as ret
from emp;
> select ename||q'!'s house is bigger than Tom's'!' as ret
from emp;
> select ename||q'['s house is bigger than Tom's']' as ret
from emp;

** 중복제거 distinct
> select unique deptno from emp;
> select distinct deptno from emp;

//deptno, job 두개다 distinct 한것을 찾음
> select distinct deptno, job
from emp
order by 1,2;

//전에는 sorting group by 였는데
//10g 이후에는 hashing group by 여서 정렬이 되어 있지 않다.
//order by 를 넣으면 sort group by 를 사용한다.
select distinct deptno, count(*)
from emp
group by deptno
order by 1;
----------------------------------
SQL> set timing on
SQL> set autot on
SQL> select distinct deptno, count(*)
from emp
group by deptno;

    DEPTNO   COUNT(*)
---------- ----------
        20          5
        30          6
        10          3

Execution Plan
----------------------------------------------------------
Plan hash value: 4067220884

---------------------------------------------------------------------------
| Id  | Operation          | Name | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |      |     3 |     9 |     3  (34)| 00:00:01 |
|   1 |  HASH GROUP BY     |      |     3 |     9 |     3  (34)| 00:00:01 |
|   2 |   TABLE ACCESS FULL| EMP  |    14 |    42 |     2   (0)| 00:00:01 |
---------------------------------------------------------------------------

SQL> select distinct deptno, count(*)
  2  from emp
  3  group by deptno
  4  order by 1;

    DEPTNO   COUNT(*)
---------- ----------
        10          3
        20          5
        30          6

Execution Plan
----------------------------------------------------------
Plan hash value: 15469362

---------------------------------------------------------------------------
| Id  | Operation          | Name | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------
|   0 | SELECT STATEMENT   |      |     3 |     9 |     3  (34)| 00:00:01 |
|   1 |  SORT GROUP BY     |      |     3 |     9 |     3  (34)| 00:00:01 |
|   2 |   TABLE ACCESS FULL| EMP  |    14 |    42 |     2   (0)| 00:00:01 |
--------------------------------------------------------------------------
----------------------------------

** hashing
distinct = hash unique
오라클 10g 부터 hash 로 형식이 변경됨
hashing, index
여기저기 흩어져있는 정렬되어 있지 않은 데이터 들을 효율적으로 찾을 수 있도록 함
hashing : 무한한 입력 데이터를 임의이 몇가지 방법으로 분류하는 방법

** where절
컬럼 alias 를 사용할수 없다.
//안됨
> select empno, sal as salary
from emp
where salary > 1000;

** 날짜
RR -> YY 와 비슷하지만 다름
YYYYMMDDHH24MISS
7byte 로 저장됨
yy/mm/dd 한국식
SQL> alter session set nls_date_format='YYYYMMDDHH24MISS';

** between
> select last_name, salary
from employees
where salary between 2500 and 3500;

> select last_name, salary
from employees
where salary >= 2500 AND salary <= 3500;

//between -> 아래 쿼리로 바꾸어서 수행 약간!! 아래 쿼리가 더 빠름

** in 연산자
> select * from emp
where mgr = 7698;
> select * from emp
where mgr = 7839;
> select * from emp
where mgr = 7788;
를 한번에 받기
  > select * from emp
  where mgr = 7698;
  union all
  select * from emp
  where mgr = 7839;
  union all
  select * from emp
  where mgr = 7788;
이것도 복잡하니까
  > select * from emp
  where mgr in(7698,7839,7788);
또는 따로
  > select * from emp
  where mgr=7698 or mgr=7839 or mgr=7788
하지만 in 연산자도 = or 로 변경되어 처리 된다.

** Like 연산자
와일드카드 %
> select * from emp
//where ename = 'A%' 이름이 A% 인사람
where ename like 'A%'

drop table t1 purge;
create table t1 (col1 varchar2(30));
insert into t1 values ('AAA');
insert into t1 values ('ABA');
insert into t1 values ('ACA');
insert into t1 values ('A_A');
commit;
//escape 옵션 A_A 찾기
> select * from t1 where col1 like '%A_A%'; --엉터리
> select * from t1 where col1 like '%A!_A%' escape '!'; --제대로

** is Null 연산자
> select * from emp
where comm = null;
> select * from emp
where comm is null;

> select * from emp
where comm is not null;

cf.
SQL> select * from emp where comm=comm;
//총 14중 null 값이 아닌 실제 값이 있는 4가지만 나옴

** not 연산자
> select * from emp
where not (sal > 1000);

** 연산자 우선순위
and 가 or 조건에 우선한다.
where a||b+100>=2000
<> 같지 않으면
2-21 예제 확인하기
1 산술 연산자
2 연결 연산자
3 비교 조건
4 IS [NOT] NULL, LIKE, [NOT] IN
5 [NOT] BETWEEN
6 같지 않음
7 NOT 논리 조건
8 AND 논리 조건
9 OR 논리 조건

SQL> select last_name, job_id, salary
  2  from employees
  3  where job_id = 'SA_REP'
  4  or job_id = 'AD_PRES'
  5  and salary >15000;

LAST_NAME                 JOB_ID         SALARY
------------------------- ---------- ----------
King                      AD_PRES         24000
Abel                      SA_REP          11000
Taylor                    SA_REP           8600
Grant                     SA_REP           7000

SQL> select last_name, job_id, salary
  2  from employees
  3  where (job_id = 'SA_REP'
  4  or job_id = 'AD_PRES')
  5  and salary >15000;

LAST_NAME                 JOB_ID         SALARY
------------------------- ---------- ----------
King                      AD_PRES         24000


** order by 절
오름차순 asc (생략가능)
내림차순 desc
//order by 에는 별칭 사용 가능
> select empno, ename, sal salary from emp order by sal;
> select empno, ename, sal salary from emp order by salary;

> select empno, ename, sal salary from emp order by hiredate;

정렬을 해달라는 것이 아니고
데이터가 순서없이 저장되기 때문에 해당 순서로 보여달라는 것.

> select deptnom ename, sal
from emp
order by deptno, sal desc;

//null 은 오름차순일때 뒤에 나옴
> select * from emp
order by comm;
> select * from emp
order by comm nulls first;
> select * from emp
order by comm nulls last;

//월별 정렬
> select empno, hiredate, to_char(hiredate, 'MM')
from emp
order by to_char(hiredate, 'MM');
//가공한 결과에 의한 order by
> select empno, hiredate
from emp
order by to_char(hiredate, 'MM');

** 읽기 일관성
> create table t_books1
(no number,
name varchar2(30));
> insert into t_books1
values (1000, 'ABAC');
> insert into t_books1
values (2000, 'JAVA');
> commit;  //하지 않으면 다른 세션에선 볼수 없다. 읽기 일관성

** lock 및 Deadlock
lock
update를 먼저 하고 commit 하지 않으면 다른 세션은 lock에 걸려 있다.
select 로 현재 잡고 있는 사용자를 찾을 수 있다.

Deadlock
오라클: 먼저 기다린 작업을 실패시킴 ORA-00060: deadlock detected while waiting for resource 리소스 기다리다 데드락 발생
//나때문에 누군가 기다리고 있다...락에 걸렸다. 보통 rollback 을 함으로 기존작업한 사람들에게 피해주지 않고 다시 작업한다.

**
**
문제. 급여가 올랐을때 등급의 변화 보기
//상호관련 서브쿼리: 밖에서 사용하는 테이블을 서브쿼리에서 사용
select e.empno,
  e.sal,
  (select s.grade
  from salgrade s
  where e.sal >= s.losal and e.sal <= s.hisal
  ) as s.grade,
  e.sal*1.1,
  (select s.grade
  from salgrade s
  where e.sal*1.1 >= s.losal and e.sal*1.1 <= s.hisal
  ) as s.grade*1.1
from emp e
order by 1;

//오류
> select e.empno, e.sal, s.grade, e.sal*1.1,
  (select s.grade
  from emp e, salgrade s
  where e.sal*1.1 >= s.losal and e.sal*1.1 <= s.hisal
  ) as newgrade
from emp e, salgrade s
where e.sal >= s.losal and e.sal <= s.hisal
order by 1;

(select s.grade
   *
ERROR at line 2:
ORA-01427: single-row subquery returns more than one row

select e.sal*1.1, s.grade, s.losal, s.hisal
from emp e, salgrade s
where e.sal*1.1 >= s.losal and e.sal*1.1 <= s.hisal
order by 1;

SQL> select e.empno, e.sal, s.grade, e.sal*1.1, (select s1.grade
from salgrade s1 where s1.grade=s.grade) as newgrade
from emp e, salgrade s
where e.sal >= s.losal and e.sal <= s.hisal
order by 1;

     EMPNO        SAL      GRADE  E.SAL*1.1   NEWGRADE
---------- ---------- ---------- ---------- ----------
      7369        800          1        880          1
      7499       1600          3       1760          3
      7521       1250          2       1375          2
      7566       2975          4     3272.5          4
      7654       1250          2       1375          2
      7698       2850          4       3135          4
      7782       2450          4       2695          4
      7788       3000          4       3300          4
      7839       5000          5       5500          5
      7844       1500          3       1650          3
      7876       1100          1       1210          1
      7900        950          1       1045          1
      7902       3000          4       3300          4
      7934       1300          2       1430          2

14 rows selected.

**
DAI
