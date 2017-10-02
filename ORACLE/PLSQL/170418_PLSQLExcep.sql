
===========================
 7 장. 명시적 커서
===========================

* 결과행 집합 active set (탄창에 총알장전)
* 선언 -> 오픈 -> fetch -> empty판단 -> close
* into 절이 없다.

-----------------------
커서에서 데이터 패치(fetch)
-----------------------

## 7- 12
// 1. rowtype 으로 받아 오기
declare
  CURSOR c1 IS
    select employee_id, last_name, salary, job_id, department_id
    from employees
    order by salary desc;

  r c1%rowtype;
begin
  open c1;
  loop
    fetch c1 into r;
    exit when c1%notfound or c1%rowcount >3;
    p.p(r.employee_id||' '||r.last_name);
  end loop;
  close c1;
end;
/

// 2. bulk 로 받아 오기
declare
  CURSOR c1 IS
    select employee_id, last_name, salary, job_id, department_id
    from employees
    order by salary desc;

  type yb is table of c1%rowtype
    index by pls_integer;

  t yb;
begin
  open c1;
    fetch c1 bulk collect into t;
    for i in t.first .. t.last loop
      exit when i > 3;
      p.p(t(i).employee_id||' '||t(i).last_name);
    end loop;
  close c1;
end;
/

// 3. 커서 for loop (open, fetch, cloase 가 한번에 가능)
declare
  CURSOR c1 IS
    select employee_id, last_name, salary, job_id, department_id
    from employees
    order by salary desc;
begin
  for r in c1 loop
    exit when c1%rowcount > 3;
    p.p(r.employee_id||' '||r.last_name);
  end loop;
end;
/

// 4. 커서 for loop (커서 선언 생략하기)
declare
  n number := 1;
begin
  for r in (select employee_id, last_name, salary, job_id, department_id
        from employees order by salary desc) loop
    exit when n > 3;
    p.p(r.employee_id||' '||r.last_name);
    n := n+1;
  end loop;
end;
/

-----------------------
* 명시적 커서 속성
-----------------------
  - %ISOPEN
    Boolean 커서가 열려 있으면 TRUE로 평가됩니다.
  - %NOTFOUND
    Boolean 가장 최근 패치(fetch)가 행을 반환하지 않으면   TRUE로 평가됩니다.
  - %FOUND
    Boolean 가장 최근 패치(fetch)가 행을 반환하면 TRUE로 평가됩니다.
    %NOTFOUND 속성을 보완합니다.
  - %ROWCOUNT
    Number 지금까지 반환된 총 행 수로 평가됩니다.


# 7-22

  declare
    cursor c1(a number) is
      select *
      from emp
      where deptno = a
      order by sal desc;
  begin
    for r in c1(20) loop
      p.p(r.empno||' '||r.sal);
    end loop;

    p.p('-------------------');

    for r in c1(30) loop
      p.p(r.empno||' '||r.sal);
    end loop;
  end;
  /


-----------------------
파라미터가 포함된 커서 사용
-----------------------
## 7-22

declare
  CURSOR c1(a number) IS
   select * from emp
   where deptno = a
   order by sal;
begin
  for r in c1(20) loop
    p.p(r.empno||' '||r.sal);
  end loop;

  p.p('================');

  for r in c1(30) loop
  p.p(r.empno||' '||r.sal);
  end loop;

  -- open c1(20);
  -- close c1;
end;
/

-----------------------
FOR UPDATE 절
-----------------------
## 구문:
  SELECT ...
  FROM ...
  FOR UPDATE [OF column_reference][NOWAIT | WAIT n];
• 명시적 잠금을 사용하여 트랜잭션 동안 다른 세션에 대한 액세스를 거부합니다.
• 갱신 또는 삭제 전에 행을 잠급니다.


## 7-26

drop table t1 purge;
create table t1 as select * from emp;

create or replace procedure p1(a number)
is
  cursor c1 is
    select * from emp
    where deptno = a
    for update;

  r c1%rowtype;
begin
  open c1;
  loop
    fetch c1 into r;

    exit when c1%notfound;
    update t1
    set sal = r.sal * 1.1
    where empno = r.empno;
  end loop;
  close c1;
end;
/

execute p1(10)
execute p1(30)

* fetch 가 도는 동안 다른 세션이 update 문을 수행하는 시점에
프로시져는 락이 걸릴수 있다.
* for update 를 추가 하면 다른 dml 문이 기다리게 할 수 있다.
* 프로시져 실행전에 dml 문이 진행중이면 nowait 에러 없이 wait 문으로 기다린 후 작업이 가능하다.


**
// rowid 를 이용하여 빠르게 찾기
create or replace procedure p1(a number)
is
  cursor c1 is
    select rowid as rid, e.* from emp
    where deptno = a
    for update;

  r c1%rowtype;
begin
  open c1;
  loop
    fetch c1 into r;
    exit when c1%notfound;

    update t1
    set sal = r.sal * 1.1
    where rowid = r.rid;
  end loop;
  close c1;
end;
/

execute p1(10)
execute p1(30)

-----------------------
WHERE CURRENT OF 절
-----------------------
* WHERE CURRENT OF 절은 FOR UPDATE 절과 함께 사용되어 명시적 커서의 현재 행을 참조
* row ID를 명시적으로 참조하지 않고도 현재 처리 중인 행에 갱신 및 삭제를 적용할 수 있습니다.
// row id 를 찾아서 가져오는 것과 같은 동작을 한다.
create or replace procedure p1(a number)
is
  cursor c1 is
    select * from emp
    where deptno = a
    for update wait 30;

  r c1%rowtype;
begin
  open c1;
  loop
    fetch c1 into r;
    exit when c1%notfound;
    update t1
    set sal = r.sal * 1.1
    where CURRENT OF c1;
  end loop;
  close c1;
end;
/

execute p1(10)
execute p1(30)


===========================
8 장. Exception Handling
===========================
# Error
  - Syntax Error
  - Runtime Error (=Exception)

  * Oracle Define Exception
    - Predefined Exception : 이름이 있는 애들
      -> [1] When 이름 then
    - Non-Predefined Exception : 이름이 없는 애들
      -> [2] 이름을 붙여서 처리
      -> [3] when others then
  * User Defined Exception
    -> [4] 선언, raise, 처리
    -> [5] raise_application_error 프로시져


# Every Oracle error has a number, but exceptions must be handled by name.

# Note.
  An exception raised in a declaration propagates immediately to the enclosing block.
  An exception raised inside a handler propagates immediately to the enclosing block.


# PL/SQL 면접 문제
  https://goo.gl/OaL8Tl

# DML 이 포함된 프로시져에서 exception 정상처리를 한 경우 DML 은 수행된다.

# Exception 발생 뒤에도 바드시 수행되기 원하는 문장

  create or replace procedure p1(a number, b number)
  is
  begin
    p.p(a/b);
    p.p('The important work goes on.');
  exception
    when ZERO_DIVIDE then
      p.p('Can not divide by 0!');
  end;
  /

  exec p1(100, 2)
  exec p1(100, 0)

    ↓↓

  create or replace procedure p1(a number, b number)
  is
  begin
    begin
      p.p(a/b);
    exception
      when ZERO_DIVIDE then
        p.p('Can not divide by 0!');
    end;

    p.p('The important work goes on.');
  end;
  /

  exec p1(100, 2)
  exec p1(100, 0)

# 예외를 발생시켰을 때 현재 블록에 해당 예외에 대한 처리기가 없을 경우 처리기를 찾을 때까지 예외가 이어지는 포함 블록으로 전달됩니다. 이러한 블록 중 어떤 것도 예외를 처리하지 않는 경우 호스트 환경에서 처리되지 않은 예외가 발생합니다.
# 선언부에서 발생된 익셉션은 자신의 밖에 블럭에서 처리해야됨
# exception 안에서의 익셉션 역시 자신의 밖의 블럭으로 넘어간다. exception when then .. when then 안에서 처리 되지 않음
# standard package 오라클 익셉션들이 정의된 곳에 선언해서 사용가능

------------------------
[1] When 이름 then
------------------------
  - when 이름 then 처리

  create or replace procedure p1(a number, b number)
    is
  begin
    p.p(a/b);
  exception
    when ZERO_DIVIDE then
      p.p('Can not divide by 0!');
  end;
  /

  exec p1(100, 2)
  exec p1(100, 0)

      --

  create or replace procedure p1(a number)
  is
    v_loc dept.loc%type;
  begin
    select loc into v_loc
    from dept
    where deptno = a;

    p.p(v_loc);
  exception
    when no_data_found then
      p.p('There is no such department!');
  end;
  /

  exec p1(10)
  exec p1(80)

      --

  create or replace procedure p1(a number)
  is
    v_ename emp.ename%type;
  begin
    select ename into v_ename
    from emp
    where deptno = a;

    p.p(v_ename);
  exception
    when TOO_MANY_ROWS then
      p.p('There are several results returned!');
  end;
  /

    exec p1(10)
------------------------
[2] 이름을 붙여서 처리
------------------------
  - exception 선언
  - pragma exception_init(선언, 번호) 으로 초기화
  - Package 에 넣어서 모든 세션에 모든 곳에서 다 사용 가능 하도록 해줌
  - pragma 컴파일러 지시어 (모의 명령어) : 우선 컴파일러가 받아서 컴파일링을 하고 저장하는데 컴파일에게 행위를 지시함
  (EXCEPTION_INIT 함수를 사용하여 선언된 예외를 표준 Oracle 서버 오류 번호와 연관시킴)

  drop table t1 purge;
  create table t1 (no number primary key);

  create or replace procedure p1(a number)
  is
    e_null exception;
    pragma exception_init(e_null, -1400);
  begin
    insert into t1 values(a);
  exception
    when e_null then
      p.p('You can not enter a null value.');
  end;
  /

  exec p1(null)

    ↓↓

  create or replace package pack1
  is
    e_null exception;
    pragma exception_init(e_null, -1400);
  end;
  /

  create or replace procedure p1(a number)
  is
  begin
    insert into t1 values(a);
  exception
    when pack1.e_null then
      p.p('You can not enter a null value.');
  end;
  /

  exec p1(null)

------------------------
[3] when others then
------------------------
  - when others then : 처리 되지 않은 에러 전부
  - sqlcode,sqlerrm 발생한 에러 번호와 메시지

  drop table plsql_errors purge;

  create table plsql_errors
  (Occurrence  timestamp,
   block_name  varchar2(30),
   sql_code    varchar2(30),
   sql_errm    varchar2(200));

  create or replace procedure p1(a number)
  is
    v_sqlcode plsql_errors.sql_code%type;
    v_sqlerrm plsql_errors.sql_errm%type;
  begin
    insert into t1 values(a);
  exception
    when others then
      p.p('Error occurred : '||sqlcode);
      p.p('Error Error    : '||sqlerrm);

      v_sqlcode := sqlcode;
      v_sqlerrm := sqlerrm;

      insert into plsql_errors
      values (sysdate, 'p1', v_sqlcode, v_sqlerrm);
  end;
  /

  exec p1(null)
  exec pt('select * from plsql_errors')


------------------------
[4] 선언, raise, 처리
------------------------
  - exception 선언
  - raise 선언
    문을 넣으면 raise 를 선언한 위치에서 exception 처리 문을 찾아 넘어 가게 된다.
  - exception 처리

  create or replace procedure p1(a number)
  is
    v_sal emp.sal%type;
    e_too_low exception;
  begin
    select sal into v_sal
    from emp
    where empno = a;

    if v_sal < 1000 then
      raise e_too_low;
    end if;

    p.p('The important work goes on');
  exception
    when e_too_low then
      p.p('The salary is too low.');
  end;
  /

  exec p1(7369)
  exec p1(7499)

    --

  create or replace procedure p1(a number)
  is
    v_sal emp.sal%type;
  begin
    select sal into v_sal
    from emp
    where empno = a;

    if v_sal < 1000 then
      raise zero_divide;
    end if;

    p.p('The important work goes on');
  exception
    when zero_divide then
      p.p('The salary is too low.');
  end;
  /

  exec p1(7369)
------------------------
[5] raise_application_error 프로시져
------------------------
  - raise_application_error(에러번호, 에러메시지)
  - 에러번호 : 예외에 대한 유저 지정 번호로, -20,000 ~ 20,999 범위의 값입니다.
  - 에러메시지 : 유저가 지정한 예외 메시지로, 최대 길이 2,048바이트의 문자열입니다.
  - 임의로 에러 발생! 비정상종료 됨
  - 해당 에러를 이름없는 에러 처리 방식과 동일하게 처리함

  create or replace procedure p1(a number)
    is
      v_sal emp.sal%type;
    begin
      select sal into v_sal
      from emp
      where empno = a;

      if v_sal < 1000 then
        raise_application_error(-20100, 'The salary is too low.');
      end if;
    end;
    /

    exec p1(7369)

      ↓↓

    create or replace procedure p1(a number)
    is
      v_sal emp.sal%type;

      e_too_low exception;
      pragma exception_init(e_too_low, -20100);
    begin
      select sal into v_sal
      from emp
      where empno = a;

      if v_sal < 1000 then
        raise_application_error(-20100, 'The salary is too low.');
      end if;

    exception
      when e_too_low then
        p.p('too low');
    end;
    /

    exec p1(7369)

* 트리거에서 에러가 나면 트리거를 시도했던 작업도 같이 취소된다.
cf.트리거(Trigger)를 이용해서 특정 IP 접속 제한하기

 CREATE OR REPLACE TRIGGER HR10_LOGON_TRI
 after LOGON ON dream30.SCHEMA
 BEGIN
   IF SUBSTR(sys_context('USERENV', 'IP_ADDRESS'), 1, 8) in ('70.12.50', '70.12.51')  then
        RAISE_APPLICATION_ERROR (-20002, 'IP '||ORA_CLIENT_IP_ADDRESS
           ||' is not allowed to connect database!');
   END IF;
 END;
 /


===========================
첫번째 제목
===========================
-----------------------
 두번쨰 제목
-----------------------
