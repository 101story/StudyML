

===========================
PL/SQL
===========================
- https://en.wikipedia.org/wiki/SQL#Procedural_extensions
* PL/SQL = SQL(Data Manipulating) + 3GL(Data Processing)
* oracle 의 고유 언어
  - Pascal -> Ada -> PL/SQL
* Server-Side Programming
  (sql : client side programming)
* block 을 서버 내부에 저장함
* block 구조의 언어
  - anonymous Block
  - Named Block : procedures, function, Packages, trigger, object ...
* begin ~ end select 문의 결과는 1row 만 허가함

* block 구조
- anonymouse
  declare   옵션
    선언부
  begin       필수
    실행부
    exception   옵션
    예외처리
  end;        필수
  /
- named block
  create or replace [procedure|function] 이름
    is
    declare   옵션
      선언부
    begin       필수
      실행부
      exception   옵션
      예외처리
    end;        필수
    /


* ; : 블럭의 끝
/ : 실행

## 무작정 따라하기
set serv  eroutput on

begin
dbms_output.put_line('Hello_World!');
end;
/

begin
for i in 1..100 loop
dbms_output.put_line(i);
end loop;
end;
/

begin
for i in 1..9 loop
dbms_output.put_line(2*i);
end loop;
end;
/

declare
 v_avg_sal number;
begin
 select avg(sal) into v_avg_sal
 from emp
 where deptno = &sv_deptno;
 dbms_output.put_line(v_avg_sal)
end;
/


// 수행되는게 아니고 저장됨
create or replace procedure p1(amu number)
is
begin
for i in 1..9 loop
dbms_output.put_line(amu*i);
end loop;
end;
/

//저장된 procedure 실행
exec p1(7)

* show errors : 에러 위치 알수 있음
SQL> create or replace procedure p1
2  begin
3    for i in 1..9 loop
4      dbms_outut.put_line(2*i);
5    end loop;
6  end;
7  /
  Warning: Procedure created with compilation errors.

// 프로시져 디버깅 에러 확인하기
SQL> show errors
Errors for PROCEDURE P1:

  LINE/COL ERROR
  -------- -----------------------------------------------------------------
  2/1      PLS-00103: Encountered the symbol "BEGIN" when expecting one of
  the following:
  ( ; is with authid as cluster compress order using compiled
  wrapped external deterministic parallel_enable pipelined
  result_cache
  The symbol "is" was substituted for "BEGIN" to continue.


## 조금 더 따라하기
// v_ename emp.ename%type; 생성 순간의 타입을 가져옴
create or replace procedure proc1(p_empno number)
is
  v_ename emp.ename%type;
  v_sal   emp.sal%type;
begin
  select ename, sal into v_ename, v_sal
  from emp
  where empno = p_empno;

  dbms_output.put_line('ENAME : '||v_ename);
  dbms_output.put_line('SAL : '||v_sal);

  -- file, dml, 등에도 추가 할 수 있음
  -- ELO nodata select 문에 0건 결과가 나올떄
  -- too many select 문에 2건이상의 결과가 나올떄
exception
    when no_data_found then
  dbms_output.put_line(p_empno||' does not exists!');
end;
/

// 실행
exec proc1(7788)
exec proc1(4567) -- 에러남


--
