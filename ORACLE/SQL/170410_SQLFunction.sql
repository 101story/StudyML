
SQL*Plus 연결연산자 -
SQL> col ename -
> formet a30
SQL> set underline "-"

## SQL 문 추가 및 복습 ########

** null 이 아닌 값들 전부 노출
> select * from emp where comm=comm;

** sql reorganization 이란
컬럼 재배치, 구조 변경 등등

** 문제) 알랜 보다 더 많이 받는 사람
> select *
from emp e, emp a
where a.empno = 7499;
총 14*1 : 14건

넌 이퀴조인, 셀프조인
> select e.ename,
        e.sal,
        a.ename,
        a.sal,
        e.sal - a.sal as diff
from emp e, emp a
where a.empno = 7499
and e.sal > a.sal
order by diff desc;

Cartesian Product
  from emp, dept
  join문없이 멀티로 join 함

** Data Mining
통계학, RDBMS, ML머신러닝 알고리즘


### 170405,170407 수업 SQL 복습 ##

** view
- Named Select!
- Query Transformation

** exec print_table
테이블 세로로 출력하기

########################
## 3장,4장 단일행 함수 ##
########################

select ename, lower(ename)
from emp;

# 3-4 argument
> col user format a10
> select sysdate, user, ename, initcap(ename) a, substr(ename,1,2) b, substr(ename,3) c
from emp;

** 단일행 함수 종류
• 문자
• 숫자
• 날짜
• 변환
• 일반
      - NVL
      - NVL2
      - NULLIF
      - COALESCE
      - CASE (표현식)
      - DECODE (함수)

------------------------
문자 함수
------------------------

** 문자 조작 함수
CONCAT('Hello', 'World')    HelloWorld
TRIM('H' FROM 'HelloWorld') elloWorld
SUBSTR('HelloWorld',1,5)    Hello
LENGTH('HelloWorld')        10
INSTR('HelloWorld', 'W')    6
LPAD(salary, 10,'*')         *****24000
RPAD(salary, 10, '*')       24000*****
REPLACE('JACK and JUE','J','BL')  BLACK and BLUE

• LPAD: 길이가 n이 되도록 왼쪽부터 문자식으로 채운 표현식을 반환합니다.
• RPAD: 길이가 n이 되도록 오른쪽부터 문자식으로 채운 표현식을 반환합니다.
* instr(문자, 찾을문자, 검색시작위치, 빈도수)

# 3-13 trim ltrim 과 rtrim 비교
select ltrim('SOS', 'S') from dual;
select trim(leading 'S' from 'SOS') from dual;

select rtrim('SOS', 'S') from dual;
select trim(trailing 'S' from 'SOS') from dual;

select ltrim(rtrim('SOS', 'S')) from dual;
select trim(both 'S' from 'SOS') from dual;
//both 생략해도 됨

 -------

> select ltrim('xyxYxyxy','xy')
from dual;
  :: 결과 :: xyx 'xy' 하나씩 비교해서 Y 전까진 다 지워짐

> select trim('xy' from 'xyxYxyxy')
from dual;
  :: 결과 :: 에러 trim 은 한글자만 가능하다.



# 3-13
문제. ename 이 5자인 사원?
> select empno, ename, job
from emp
where ename like '_____';

> select empno, ename, job
from emp
where length(ename) = 5;

문제. ename에 a 가 포함된 사람
> select empno, ename, job
from emp
where ename like '%A%';

> select empno, ename, job
from emp
where instr(ename, 'A') > 2;

문제. sal 을 그래프로 나타내세요. * 하나가 100입니다. 반올림하세요.
> col starts format a70
> select empno, sal, rpad('*', round(sal/100), '*') as starts
from emp;
> select empno, sal, rpad(' ', round(sal/100), '*') as starts
from emp;

참고) SELECT LPAD('4567',10,'0') FROM DUAL
결과: 0000004567
lpad(str, length, padstr)

문제. 숫자로만 이루어진 행 찾기
drop table t1 purge;
create table t1 (col1 varchar2(10));

insert into t1 values('37236');
insert into t1 values('A33A');
insert into t1 values('38434');
insert into t1 values('33DAI');
insert into t1 values('233');
insert into t1 values('9');

commit;

해답 1.
> select col1
from t1
where lower(col1) = upper(col1);

해답 2.
> select col1, ltrim(col1, '0123456789')
from t1;

> select col1
from t1
where ltrim(col1, '0123456789') is null;

# 3-14 substr
** substr
substr('abcdefg', 2,1)  : b
substr('abcdefg', -2,1) : f

> select ename, substr(ename, -1, 1)
from emp;

> select ename
from emp
where substr(ename, -1, 1) = 'N';
  ENAME
  ----------
  ALLEN
  MARTIN

** translate
SQL> SELECT TRANSLATE('a1b2c3d4e5','abcde','0123') FROM DUAL;
    TRANSLATE
    ---------
    011223345

SQL> SELECT TRANSLATE('a1b2c3d4e5','abcde','0123') FROM DUAL;
    TRANSLATE
    ---------
    011223345

SQL> SELECT TRANSLATE('a1b2c3d4e5fgh','abcdefg','0123') FROM DUAL;
    TRANSLATE(
    ----------
    011223345h

# user-defined function
// 뷰처럼 코드가 저장된다.
create or replace fuction tax (a number) return number
is
begin
  return a*0.137;
end;

select emp no, sal, tax(sal)
from emp;

-----------------------------
 숫자 함수
-----------------------------

round(45.996, 2)  : 46
round(45.926, 2)  : 45.93
round(45.993, -2) : 소수점 위 2자리 반올림 (100원단위)
trunc(45.992, 2) : 45.99

select empno, mod(empno, 2), mod(empno, 3)
from emp;

abs() : 절대값
ceil()  : 올림
floor() : 내림

# dual 테이블
- sys 소유의 테이블
- dummy 컬럼, x값 을 가지고 있음
row 가 하나짜리인 테이블로 test 하거나 다른 용도로 사용함

// t 또는 h 또는 e 면 삭제 ' ' 없으니까 stop
SQL> select ltrim('thte king', 'the')
  2  from dual;
  LTRIM
  -----
   king

 -----------------------------
  날짜 함수
 -----------------------------
# 날짜 연산
  date +,- number
  sysdate +1
  *, / 연산 불가

> alter session set nls_date_format = 'YYYY/MM/DD HH24:MI:SS';
> select sysdate,
  sysdate + 3,
  sysdate + 3/24,
  sysdate + 12/(24*60),
  sysdate + 36/(24*60*60)
from dual;

// 내가 살아온 날 수
> select sysdate - to_date('19861109', 'YYYYMMDD')
from dual;
> select (sysdate - to_date('19861109', 'YYYYMMDD'))/7
from dual;

// 만일 이상 살려면.... 89년 이상 29
> select sysdate - to_date('19890101', 'YYYYMMDD')
from dual;

sysdate : 서버 기준 날짜
CURRENT_DATE : 클라이언트 기준 날짜

# 날짜 함수

• MONTHS_BETWEEN(date1, date2): date1과 date2 사이의 월수를 찾습니다.
결과는 양수나 음수가 될 수 있습니다. date1이 date2보다 늦은 날짜인 경우 결과는
양수이고 date1이 date2보다 앞선 날짜인 경우 결과는 음수입니다. 결과에서 정수가
아닌 부분은 월의 일부분을 나타냅니다.
• ADD_MONTHS(date, n): date에 월수 n을 추가합니다. n 값은 정수여야 하며 음수가
될 수도 있습니다.
• NEXT_DAY(date, 'char'): date 다음에 오는 지정된 요일('char')의 날짜를
찾습니다. char 값은 요일을 나타내는 숫자나 문자열이 될 수 있습니다.
• LAST_DAY(date): date에 해당하는 날짜가 있는 월의 말일 날짜를 찾습니다.
• ROUND(date[,'fmt']): date를 형식 모델 fmt에서 지정한 단위로 반올림하여
반환합니다. 형식 모델 fmt가 생략된 경우 date는 가장 가까운 일로 반올림됩니다.
• TRUNC(date[, 'fmt']): date를 형식 모델 fmt에서 지정한 단위로 truncate하여
날짜의 시간 부분과 함께 반환합니다. 형식 모델 fmt가 생략된 경우 date는 가장 가까운
일로 truncate됩니다.

// 6개월 뒤
> select empno,
  hiredate,
  months_between(sysdate, hiredate),
  add_months(hiredate, 6),
from emp;

// 오늘이 지난 첫번째 월요일
> select sysdate,
  next_day(sysdate, 'mon')
from dual;

// 그 달의 마지막 날
> select last_day(to_date('06-feb-17', 'DD-MM-RR'))
from dual;

# 3-31
  일 : 01~15 : 탈락
      16~31 : 반올림
  월 : 01~06 : 탈락
      07~12 : 반올림

// DD 가 반올림의 대상이 됨
> select round(to_date('17-jul-2016', 'DD-MON-YYYY'),'month')
from dual;
  ROUND(TO_
  ---------
  01-JAN-16
> select round(to_date('17-jul-2016', 'DD-MON-YYYY'),'year')
from dual;
  ROUND(TO_
  ---------
  01-JAN-17

> select empno,
  hiredate,
  trunc(hiredate, 'month'),
  trunc(hiredate, 'year')
from emp;

// 81년 입사자
> select empno,
  hiredate,
  trunc(hiredate, 'month'),
  trunc(hiredate, 'year')
from emp
where trunc(hiredate, 'month')='01-FEB-81';

-----------------------------
 변환 함수
-----------------------------
# Implicit Conversion
- expression 일 경우
> select 100 + '100'
from dual;

> select *
from emp
where empno = '7788';

- assignment 일 경우
> select empno, substr(ename, 1, '2')
from emp;
(명시적 변환을 사용하는 것이 좋다)

# to_char() date -> char

> SELECT to_char(hiredate, 'YYYY YYYY')
FROM emp;
> SELECT to_char(hiredate, 'YEAR Year year')
FROM emp;
> SELECT to_char(hiredate, 'fm Year Month mon Day dy')
FROM emp;
* fm : 변환과정에서 생긴 ' ' 공백 제거

> SELECT hiredate, to_char(hiredate, 'YYYY Q MM WW W DDD DD D Day')
FROM emp;
분기 1년중에 몇일
달
WW 또는 W 연 또는 월의 주
DDD 또는 DD 또는 D 연, 월 또는 주의 일

// RM 로마식 월 숫자
> select hiredate, to_char(hiredate, 'RM Rm rm') from emp;

// HH24:MI:SS AM
> select to_char(sysdate, 'hh24:mi:ss') from dual;

// ddspth fourteenth
> select to_char(hiredate, 'DD Ddsp ddth ddspth ddthsp') from emp;

// SSSSS 자정 이후의 초(0–86399)
> select to_char(sysdate, 'sssss') from dual;

> select '오늘은 '||to_char(hiredate, 'Year Mon Dy')||'요일입니다.'
from emp;

> select to_char(hiredate, '"오늘은" YYYY"년" MM"월" DD"일입니다." ')
from emp;

"" 사용 하는 곳 :
      alias 에서 space 를 사용하는 경우
      날짜 변환에 리터럴 문자 추가 해주는 경우

cf. fm: fill mode
  페이드 블랭스 ' ' 스페이스, 0 같은 것들 처리

> SELECT last_name,
TO_CHAR(hire_date,
'fmDdspth "of" Month YYYY fmHH:MI:SS AM')
HIREDATE
FROM employees;
  //00:00:00 -> 0:0:0 으로 사라지기 때문에 fm 을 한번 더 해줌

# to_char() number -> char
  '9999' 숫자로 생각하면 안됨 있는 수 만큼 채움
  '0000' 강제 자리 채움
select empno,
       sal,
       to_char(sal, '999,999.99'),
       to_char(sal, '000,000.00')
from emp;
  화폐 단위
  L 로컬 단위
select empno,
       sal,
       to_char(sal, '$999,999.99'),
       to_char(sal, 'L000,000.00', 'nls_currency=\') --'
from emp;

# to_number()
> select '1235' to_number('1235')
from dual;

# to_date()
> select to_date('07/08/09', 'RR/MM/DD')
from dual;


## 일반함수
DECODE : IF THEN ELSE
GREATEST
DUMP
VSIZE
USER



########################
### 5장 복수행 함수 #####
########################
# 집단별 집계

> select avg(sal)
from emp;

> select sum(sal), avg(sal)
from emp;

> select deptno, sum(sal), avg(sal)
from emp
group by deptno
order by deptno;

> select deptno, job, sum(sal), avg(sal)
from emp
group by deptno, job
order by deptno, job;


>select empno,
       sal,
       case when sal < 2000 then '1'
            when sal < 4000 then '2'
            else                 '3'
       end as gubun
from emp
order by gubun, sal;

> select case when sal < 2000 then '1 : < 2000'
            when sal < 4000 then '2 : < 4000'
            else                 '3 : >= 4000'
       end as gubun,
       count(*),
       sum(sal),
       avg(sal)
from emp
group by case when sal < 2000 then '1 : < 2000'
              when sal < 4000 then '2 : < 4000'
              else                 '3 : >= 4000'
         end
order by gubun;
//where, group by 에 컬럼 alias 사용 불가

> select /*가공한 결과에 의한 group by */
      to_char(hiredate, 'yyyy') as year, avg(sal)
from emp
group by to_char(hiredate, 'yyyy')
order by year;

** 에러 대처

// group 함수로 나오는 모든 값은 다 group by 에 있어야 한다.
// 복수행 함수로 감싼 컬럼 이외의 모든 컬럼은 group by 절에 나와야 한다. 단, 리터럴은 예외
> select deptno, dempno, ename, sal, avg(sal)
from emp
group by deptno;

** where vs having
// from 절에서 20번 빼고 다음에 가져옴 where 절이 성능적으로 좋음

> select deptno, sum(sal)
from emp
where deptno != 20
group by deptno;

> select deptno, sum(sal)
from emp
group by deptno
having deptno != 20;

// 그룹함수는 where 에서 사용할 수 없다.
> select deptno, sum(sal)
from emp
where sum(sal) < 1000
group by deptno;

** 그룹함수 유형
• AVG
• COUNT
• MAX
• MIN
• STDDEV : 표준편차
• SUM
• VARIANCE : 분산

> select avg(all sal), avg(distinct sal)
from emp;

// 모든 복수행 함수는 null 을 무시한다.
단!) count(*) 는 예외
> select sum(comm), avg(comm)
from emp;

// commition 받은 사람끼리, 사원당 평균 커피션
> select avg(comm), avg(nvl(comm, 0))
from emp;

----
drop table t1 purge;
create table t1 (col1 number);
insert into t1 values (1000);
insert into t1 values (1000);
insert into t1 values (2000);
insert into t1 values (2000);
insert into t1 values (null);
insert into t1 values ('');
commit;
select * from t1;

// 컬럼명, distinct 넣으면 null 빼고 계산
select count(*), count(col1), count(distinct col1) from t1;
----
// 80번 부서에서 커미션을 받는 사람만
SELECT COUNT(commission_pct)
FROM employees
WHERE department_id = 80;

// 그룹 함수는 열에 있는 null 값을 무시합니다.
SELECT AVG(commission_pct)
FROM employees;
// NVL 함수는 강제로 그룹 함수에 null 값이 포함되도록 합니다.
SELECT AVG(NVL(commission_pct, 0))
FROM employees;

// 최고평균급여
>select max(avg(nvl(salary)))
FROM employees
GROUP BY department_id;


**
SQL 책142쪽
문제) 매니저별 부하직우너의 숫자 카운트 2명이상만 출력

**
