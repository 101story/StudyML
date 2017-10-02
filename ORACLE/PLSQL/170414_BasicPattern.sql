

===========================
 PL/SQL 추가 (멀티 Row 맛보기)
===========================
## 프로그래밍 : 해야할 일을 미리 기술해 놓은것

- Varry : 배열과 유사
Declare type array_type is varray(5) of integer;
- nested table : list 와 유사
declare type nested_type is table of varchar2(30);
- associative array : neasted table 에 index by 가 추가된 형태
type assoc_array_num_type is table of number index by pls_integer;


## 연산자
  할당연산자
    c, java             a=100
    basic, powerscript  a=100
    pascal, pl/sql      a:=100
  비교연산자
    c, java             a==100
    basic, powerscript  a==100
    pascal, pl/sql      a=100

// 프로시져 정보 보기
> ed src.sql

  set lines 200
  set pages 100
  set verify off

  col name format a30
  col type noprint
  col text format a70
  -- 쿼리는 해오는데 해당 컬럼만 화면에 노출 하지 않기
  -- break on name skip 1
  break on name skip page
  select *
  from user_source
  where name like upper('%&1%')
  order by name, line;;

  col name clear
  col type print
  col text clear
  clear break

  set lines 200
  set pages 40
  set verify on
> @src proc

## 매개변수 문자 사용
  p1(a varchar2 또는 a emp.job%type) 사용

## too manay rows! 에러
** PL/SQL 블럭에 사용되는 QUERY는 반드시 한건의 ROW만 리턴해야 하며
   여러 건을 리턴할 경우 에러임. 이를 극복하기 위한 방법이 두가지 있는데
   명시적 커서를 사용하거나 BULK COLLECT INTO를 사용하면 됨
* select 문에 여러 건의 결과가 반환될때

create or replace procedure p1 (p_job emp.job%type)
is
  v_empno emp.empno%type;
  v_ename emp.ename%type;
  v_sal   emp.sal%type;
begin
  select empno, ename, sal INTO v_empno, v_ename, v_sal
  from emp
  where job = p_job;
end;
/

exec p1('MANAGER')   -- 에러 : ORA-01422: exact fetch returns more than requested number of rows

>> 해결 1. 명시적 커서 사용
// 서버에 결과가 저장되고 하나씨 잘라서 open close 에서 반환해줌
create or replace procedure p1 (p_job emp.job%type)
is
  v_empno emp.empno%type;
  v_ename emp.ename%type;
  v_sal   emp.sal%type;

  CURSOR c1 IS
    select empno, ename, sal
    from emp
    where job = p_job;
begin
  OPEN c1;
    loop
      FETCH c1 INTO v_empno, v_ename, v_sal;
      exit when c1%notfound;  -- row 결과를 전부 가져왔으면
      dbms_output.put_line(v_empno||' '||v_ename||' '||v_sal);
    end loop;
  CLOSE c1;
end;
/

exec p1('MANAGER')
exec p1('SALESMAN')

>> 해결 2. BULK COLLECT INTO
  - 1의 변수를 1개로 : 스칼라 변수
  - 서로다르값 한번에 : 구조체
  - 같은값을 한번에 : 배열
//select 문에 BULK COLLECT INTO 를 사용하여 구조체 배열 변수에 넣음
-- 구조체 선언
TYPE emp_record_type IS RECORD
();
-- 구조체로 되어 있는 배열 선언
TYPE emp_record_table_type IS TABLE OF emp_record_type
  INDEX BY PLS_INTEGER;
-- 구조체 배열 변수 선언
r emp_record_table_type;

create or replace procedure p1 (p_job emp.job%type)
is
  TYPE emp_record_type IS RECORD
    (empno emp.empno%type,
     ename emp.ename%type,
     sal   emp.sal%type);

  TYPE emp_record_table_type IS TABLE OF emp_record_type
    INDEX BY PLS_INTEGER;

  r emp_record_table_type;
begin
  select empno, ename, sal BULK COLLECT INTO r
  from emp
  where job = p_job;

  for i in r.first .. r.last loop
    dbms_output.put_line(r(i).empno||' '||r(i).ename||' '||r(i).sal);
  end loop;
end;
/

exec p1('MANAGER')
exec p1('SALESMAN')


## 트리거 예제
* 자동 실행됨
drop table t1 purge;
create table t1 (no number, name varchar2(10));
-- 제약조건 name 에는 반듯이 첫글자 대문자로 입력해라!
-- new.name
//insert 하기 전에 begin ~ end 문이 수행
create or replace trigger t1_name_tri
  before insert or update or delete on t1
  for each row
begin
  :new.name := initcap(:new.name);
end;
/

insert into t1 values(1000, 'abc');


===========================
 0 장
===========================
overloading - 형제
overrriding - 부모

# 패키지
// overloading
// head
create or replace package p
is
  procedure p(a number);
  procedure p(a varchar2);
  procedure p(a date);
end;
/

// body
create or replace package body p
is
  procedure p(a number)
  is
  begin
    dbms_output.put_line(a);
  end;

  procedure p(a varchar2)
  is
  begin
    dbms_output.put_line(a);
  end;

  procedure p(a date)
  is
  begin
    dbms_output.put_line(a);
  end;
end;
/

PL/SQL RECORD : 한 로우에 여러 값
  - 레코드
  - 필드
PL/SQL TABLE : 한 열에 여러 값
  - 한개 한개를 element 라고 함
  - element 하나에 부는게 key 값
  - FIRST, LAST 사용 가능

## PL/SQL RECORD  Pattern
[1]
  // 하나 row 의 값 하나
  create or replace procedure p1(a number)
  is
    v_sal emp.sal%type;
  begin
    select sal into v_sal
    from emp
    where empno = a;

    p.p(v_sal);
  end;
  /
  show errors

  exec p1(7788)
  exec p1(7900)
[2]
  // 하나 row 하나이 레코드 row 전부
  - 각 필드(하나하나의값)로 하나의 ROW 타입의 변수가 생성됨
  (PLSQL 레코드=구조체)
  create or replace procedure p1(a number)
  is
    r emp%rowtype;
  begin
    select * into r
    from emp
    where empno = a;

    p.p(r.ename||' '||r.sal);
  end;
  /

  exec p1(7788)
  exec p1(7900)

[3]
  // 하나 row 의 몇가지 열만
  - 변수 타입을 제작함 TYPE emp_rec_type IS RECORD
    (ename emp.ename%type, sal emp.sal%type, job emp.job%type)
    (-필드명과 데이터 타입명도 같게 해줌)
  - 만들어진 타입으로 변수 선언 r emp_rec_type
    (-만들어진 타입, 변수는 end 를 만나면 사라짐)
  create or replace procedure p1(a number)
  is
    TYPE emp_rec_type IS RECORD
     (ename emp.ename%type,
      sal   emp.sal%type,
      job   emp.job%type);

    r emp_rec_type;
  begin
    select ename, sal, job into r
    from emp
    where empno = a;

    p.p(r.ename||' '||r.job);
  end;
  /

  exec p1(7788)
  exec p1(7900)

  // 만든 타입과 변수 기억하기 (패키지 만들기)
  create or replace package pack1
  is
    TYPE emp_rec_type IS RECORD
     (ename emp.ename%type,
      sal   emp.sal%type,
      job   emp.job%type);
  end;
  /

  create or replace procedure p1(a number)
  is
    r pack1.emp_rec_type;
  begin
    select ename, sal, job into r
    from emp
    where empno = a;

    p.p(r.ename||' '||r.job);
  end;
  /

  exec p1(7788)
  exec p1(7900)


## PL/SQL RECORD Patten
create or replace procedure p1(a number)
  is 대신 as 도 가능

[4]
  // 하나의 열 전부
  -- PLS_INTEGER 정수 타입의 인덱스
  create or replace procedure p1(a number)
  is
    TYPE emp_ename_tab_type IS TABLE OF emp.ename%type
      INDEX BY PLS_INTEGER;

    t emp_ename_tab_type;
  begin
    select ename BULK COLLECT INTO t
    from emp
    where deptno = a;

    for i in t.first .. t.last loop
      p.p(t(i));
    end loop;
  end;
  /

  // 패키지에 넣어서 저장해서 사용하기
  - 재 이용해야 할 패키지 만들떄
  - 스팩과 패키를 한번에 만들기도 함 (타입 선언만 할때엔 스팩에 다 넣음)
  create or replace package pack1
  is
    TYPE emp_rec_type IS RECORD
     (ename emp.ename%type,
      sal   emp.sal%type,
      job   emp.job%type);

    TYPE emp_ename_tab_type IS TABLE OF emp.ename%type
      INDEX BY PLS_INTEGER;
  end;
  /

  create or replace procedure p1(a number)
  is
    t pack1.emp_ename_tab_type;
  begin
    select ename BULK COLLECT INTO t
    from emp
    where deptno = a;

    for i in t.first .. t.last loop
      p.p(t(i));
    end loop;
  end;
  /

  exec p1(20)

[5]
  // 여러행 모든 ROW
  - pl/sql table of record
  - 구조체 배열을 사용
  - 반복되는 타입이 emp%rowtype 을 가져옴
  create or replace procedure p1(b number)
  is
    TYPE emp_tab_rec_type IS TABLE OF emp%rowtype
      INDEX BY PLS_INTEGER;

    t emp_tab_rec_type;
  begin
    select * BULK COLLECT INTO t
    from emp
    where deptno = b;

    for i in t.first .. t.last loop
      p.p(t(i).empno||' '||t(i).ename||' '||t(i).sal);
    end loop;
  end;
  /

  exec p1(20)

[6]
  // 군대 군대 여러열 여러행
  create or replace procedure p1(b number)
  is
    TYPE emp_rec_type IS RECORD
    (ename emp.ename%type,
     sal   emp.sal%type,
     job   emp.job%type);

    TYPE emp_tab_rec_type IS TABLE OF emp_rec_type
      INDEX BY PLS_INTEGER;

    t emp_tab_rec_type;
  begin
    select ename, sal, job BULK COLLECT INTO t
    from emp
    where deptno = b;

    for i in t.first .. t.last loop
      p.p(t(i).ename||' '||t(i).sal||' '||t(i).job);
    end loop;
  end;
  /

  exec p1(20)

----------------------------
## DML 예제
----------------------------
** DML은 멀티 row 가 가능?? 여러개가 나와도되요???
** DML 하기전에 검증해야 하는 것들을 나열 할 수 있다.
** IF 문
IF 조건 THEN
ELSEIF 조건 THEN
ELSE
END IF;

drop table t1 purge;

create table t1
as
select empno, ename, sal from emp where 1 = 2;


// insert into
  create or replace procedure up_t1_insert
    (p_empno emp.empno%type,
     p_ename emp.ename%type,
     p_sal   emp.sal%type)
  is
  begin
    insert into t1(empno, ename, sal)
    values (p_empno, p_ename, p_sal);

    insert into t1(empno, ename, sal)
    values (p_empno, p_ename, p_sal);
  end;
  /


// update
create or replace procedure up_t1_sal_update
  (p_empno emp.empno%type,
   p_sal   emp.sal%type)
is
begin
  update t1
  set sal = p_sal
  where empno = p_empno;
end;
/

// delete
create or replace procedure up_t1_delete
  (p_empno emp.empno%type)
is
begin
  delete from t1
  where empno = p_empno;
end;
/

exec up_t1_insert(1000, 'TOM', 2400)
exec up_t1_insert(2000, 'JOHN', 1900)
exec up_t1_insert(3000, 'EDDY', 3600)

commit;

exec up_t1_sal_update(2000, 2700)

commit;

exec up_t1_delete(2000)

select * from t1;

commit;

----------------------------
## DML 예제 : Package 로 변환
----------------------------
* plb 파일 만들기
- 소스 코드가 암호화 됨

SQL> ed emp_pack.sql

create or replace package emp_pack
is
  procedure up_t1_insert
    (p_empno emp.empno%type,
     p_ename emp.ename%type,
     p_sal   emp.sal%type);

  procedure up_t1_sal_update
    (p_empno emp.empno%type,
     p_sal   emp.sal%type);

  procedure up_t1_delete
    (p_empno emp.empno%type);
end;
/

SQL> ed emp_pack_body.sql

create or replace package body emp_pack
is
  procedure up_t1_insert
    (p_empno emp.empno%type,
     p_ename emp.ename%type,
     p_sal   emp.sal%type)
  is
  begin
    insert into t1(empno, ename, sal)
    values (p_empno, p_ename, p_sal);
  end;

  procedure up_t1_sal_update
    (p_empno emp.empno%type,
     p_sal   emp.sal%type)
  is
  begin
    if p_sal <= 1000 then
      p.p('what?');
    elsif p_sal <= 2000 then
      p.p('oh no!');
    else
      update t1
      set sal = p_sal
      where empno = p_empno;
    end if;
  end;

  procedure up_t1_delete
    (p_empno emp.empno%type)
  is
  begin
    delete from t1
    where empno = p_empno;
  end;
end;
/

SQL> exit

C:\Users\student> dir emp*

2017-04-14  오후 04:30               343 emp_pack.sql
2017-04-14  오후 04:30               640 emp_pack_body.sql

C:\Users\student> wrap iname=emp_pack_body.sql

2017-04-14  오후 04:30               343 emp_pack.sql
2017-04-14  오후 04:31               511 emp_pack_body.plb
2017-04-14  오후 04:30               640 emp_pack_body.sql

C:\Users\student>ic

SQL> @emp_pack.sql
SQL> @emp_pack_body.plb

SQL> # 테스트

truncate table t1;

drop procedure up_t1_insert;
drop procedure up_t1_sal_update;
drop procedure up_t1_delete;

exec emp_pack.up_t1_insert(1000, 'TOM', 2400)
exec emp_pack.up_t1_insert(2000, 'JOHN', 1900)
exec emp_pack.up_t1_insert(3000, 'EDDY', 3600)

commit;

select * from t1;

set serveroutput on

exec emp_pack.up_t1_sal_update(2000, 900)
exec emp_pack.up_t1_sal_update(2000, 1900)
exec emp_pack.up_t1_sal_update(2000, 2700)

commit;

exec emp_pack.up_t1_delete(2000)

select * from t1;

commit;


===========================
 1 장 PL/SQL 소개
===========================
* SQL 과 호환성이 좋다.
* PL/SQL 엔진에서 SQL 엔진으로 SQL 쿼리문을 던지고 다시 결과값을 PL/SQL 엔진으로 리턴함
* ENGINE : 다른 SW 를 위해 핵심적, 본질적 기능 수행하는 SW
* 오라클 서버 자체가 이식성이 좋아 오라클 서버 안에 들은 PL/SQL 도 이식성이 좋음 (모든 OS 안에서 구동)
* 함수는 리턴문이 반듯이 있어야 함
  프로시져는 리턴문이 있을 수도 있고 없을수도 있고

-----------------------
  --- 블록 구조 ------
-----------------------
• DECLARE (선택 사항)
  – 변수, 커서, 유저 정의 예외
• BEGIN (필수)
  – SQL 문
  – PL/SQL 문
• EXCEPTION (선택 사항)
  – 예외 발생 시 수행할 작업
• END; (필수)

* 프로시저
    PROCEDURE name
    IS
    BEGIN
    --statements
    [EXCEPTION]
    END;

* 함수
    FUNCTION name
    RETURN datatype
    IS
    BEGIN
    --statements
    RETURN value;
    [EXCEPTION]
    END;

* 익명 블록
    [DECLARE]
    BEGIN
    --statements
    [EXCEPTION]
    END;
-----------------------

-----------------------
## user-defined function
-----------------------
// 사용자 정의 함수
create or replace function f1(a number, b number) return number
  is
  begin
    return a*b;
  end;
/

> select f1(24, 39)
from dual;


===========================
2 장. PL/SQL 변수 선언
===========================
- 변수 (Variable)
- 상수 (Constant)
- 매개변수 (Parameter)
- 인자(인수, Argument, 아규먼트)


-----------------------
## 변수 선언시 수행되는 일
-----------------------
* PL/SQL 에서는 초기값이 없으면 null 이 들어감
v_no number := 100
  1. 메모리 할당(실주소)
  2. 메모리 별명이 결정(변수명)
  3. 데이터 타입 결정
  4. 데이터 결정


## 2-9
> set serverout on
> DECLARE
  v_event VARCHAR2(15);
BEGIN
  v_event := q'!Father's day!';
  --- v_event := 'Father''s day!';
  DBMS_OUTPUT.PUT_LINE('3rd Sunday in June is : '|| v_event );
  v_event := q'[Mother's day]';
  DBMS_OUTPUT.PUT_LINE('2nd Sunday in May is : '|| v_event );
END;
/


-----------------------
# PL/SQL 변수
-----------------------
• PL/SQL 변수
  – 스칼라 Scalar : 문자, 숫자, 날짜, Boolean
  – 조합 Composite : Record, Table ....
  – 참조 Reference :
  – LOB(대형 객체)
• 비PL/SQL 변수
  - Substitution 변수
  - 바인드 변수 Bind



# 문제. 아래와 같이 결과가 나타나도록 프로시져를 만드세요.
      10 ACCOUNTING     NEW YORK

         7782 CLARK            2450
         7839 KING             5000
         7934 MILLER           1300

      20 RESEARCH       DALLAS

         7566 JONES            2975
         7902 FORD             3000
         7876 ADAMS            1100
         7369 SMITH             800
         7788 SCOTT            3000

      30 SALES          CHICAGO

         7521 WARD             1250
         7844 TURNER           1500
         7499 ALLEN            1600
         7900 JAMES             950
         7698 BLAKE            2850
         7654 MARTIN           1250

      40 OPERATIONS     BOSTON

> select deptno, empno, ename, sal
from emp
where deptno in (10, 20, 30)
order by deptno;

> select deptno, dname, loc
from dept
where deptno in (10, 20, 30)
order by deptno;

> select d.deptno, e.empno, e.ename, e.sal, d.dname, d.loc
from emp e, dept d
where e.deptno = d.deptno and
d.deptno in (10, 20, 30)
order by d.deptno;

> create or replace procedure p1
is
  v_count   number;
  v_tmpDept emp.deptno%type;

  TYPE ed_rec_type IS RECORD
  ( deptno emp.deptno%type,
    empno emp.empno%type,
    ename emp.ename%type,
    sal   emp.sal%type,
    dname dept.dname%type,
    loc dept.loc%type  );

  TYPE ed_tab_rec_type IS TABLE OF ed_rec_type
    INDEX BY PLS_INTEGER;

  t ed_tab_rec_type;
begin
  select d.deptno, e.empno, e.ename, e.sal, d.dname, d.loc
   BULK COLLECT INTO t
  from emp e, dept d
  where e.deptno = d.deptno
  order by d.deptno;

  v_count := t.first;
  loop
    dbms_output.put_line(t(v_count).deptno||' '||t(v_count).dname||' '||t(v_count).loc);
      loop
        v_tmpDept := t(v_count).deptno;
        dbms_output.put_line('------'||t(v_count).empno||' '||t(v_count).ename||' '||t(v_count).sal);
        exit when v_count = t.last;
        exit when v_tmpDept != t(v_count+1).deptno;
        v_count:=v_count+1;
      end loop;
    exit when v_count = t.last;
    v_count:=v_count+1;
  end loop;
end;
/

exec p1()
- for 문의 i 값은 할당이 불가능 함 ex) i:=i+1;

해답.

create or replace procedure p1
is
begin
  for d in (select * from dept) loop
    p.p(d.deptno||' '||d.dname||' '||d.loc);

    for e in (select * from emp where deptno = d.deptno) loop
      p.p('-----'||e.empno||' '||e.ename||' '||e.sal);
    end loop;
  end loop;
end;
/

===========================
첫번째 제목
===========================
-----------------------
 두번쨰 제목
-----------------------
