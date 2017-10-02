
* 서브 프로그램 : PROCEDURE + FUNCTION 을 한번에 부를때
* 임계점 : 급격한 성능 저하가 시작되는 시점, 임계점에 도달하기 전까진 느끼지 못함

* pl/sql 한문자 한문장 pl/sql 서버가 해석하다가 sql 문장을 만나면 sql 서버로 던짐
BULK COLLECT 로 한번에 받겠다 하는 거임

===========================
2 장. PL/SQL 변수 선언
===========================
PLP1-1 pdf

-----------------------
# PL/SQL 변수
-----------------------
• PL/SQL 변수
  – 스칼라 Scalar : 문자, 숫자, 날짜, Boolean
  – 조합 Composite : PL/SQL Record, PL/SQL Table ....
  – 참조 Reference :
  – LOB(대형 객체)
• 비PL/SQL 변수
  - Substitution 변수
  - 바인드 변수 Bind


* non pl/sql 변수 : 치환변수
* 바인드변수 : var a number
* 클라이언트 |              서버
   user     |   server          background process
            |     PG                 SG
   sv_empno |      a                v_empno
   치환변수  |  바인드변수         PL/SQL 변수
            |  서버 밖같에 존재    PL/SQL 서버


> ed a001.sql

  accept sv_empno number prompt 'Enter emp EMPNO: '
  var a number
  -- 바인드변수 : 을 붙여서 사용
  -- PL/SQL 서버 밖에 SQL PLUS 서버에 선언됨
  -- 세션이 끝날때까지 계속 유지 되고 세선이 재접속 하면 다시 사용할 수 있음

  declare
    v_empno emp.empno%type := &sv_empno;
    -- non PL/SQL 변수 &치환변수
    -- v_empno 서버에서 변수 생성 end 를 만들면 사라짐
  begin
    select sal into :a
    from emp
    where empno = v_empno;
  end;
  /

  print a

> @a001 7788
> disconnect

--- 구문 -------------------
identifier [CONSTANT] datatype [NOT NULL]
[:= | DEFAULT expr];

DECLARE
  v_hiredate DATE;
  v_deptno NUMBER(2) NOT NULL := 10;
  v_location VARCHAR2(13) := 'Atlanta';
  c_comm CONSTANT NUMBER := 1400;
----------------------------
• 스칼라 데이터 유형:
  단일 값을 보유합니다.
• 참조 데이터 유형:
  저장 위치를 가리키는 포인터라는 값을 보유합니다.
• LOB 데이터 유형:
  대형 객체의 위치를 지정하는 위치자라는 값을 보유합니다. 테이블 외부에 저장되는 그래픽 이미지 등이 대형 객체에 해당합니다.
• 조합 데이터 유형:
  PL/SQL 컬렉션과 레코드 변수를 통해 사용할 수 있습니다. PL/SQL 컬렉션과 레코드에는 개별 변수로 처리할 수 있는 내부 요소가 포함됩니다.
• 비PL/SQL 변수는 사전 컴파일러 프로그램에서 선언된 호스트 언어 변수

  cf.https://docs.oracle.com/cd/B10501_01/appdev.920/a96624/03_types.htm#10519

** SQL 실행 과정
Open > Parse > Execute > Fetch > Clos
SQL 문장 실행의 전체적인 순서
Parse (구문분석) -> Bind (값 치환) -> Execute (실행) -> Fetch (인출) 이다. (Select 문 기준)
http://ann-moon.tistory.com/35

* 결과 바로 노출
set autoprint (autop) on

> set autop on
> VARIABLE b_emp_salary number
> create or replace procedure p1
is
declare
  v_empno number(6) := &empno;
begin
  select salary into :b_emp_salary
  from employees
  where employee_id = v_empno;
end;
/

> 178

===========================
3 장. PL/SQL statement
===========================
## Lexical unit(어휘 단위)
A line of PL/SQL text contains groups of characters
known as lexical units:

- 구분자(Delimiter)  : simple and compound symbols
- 식별자(Identifier) : which include reserved words
- 리터럴(Literal)
- 주석(Comment)

-----------------------
 PL/SQL의 SQL 함수
-----------------------
• 프로시저문에서 사용할 수 있는 함수:
  – 단일 행 함수
    v_desc_size:= LENGTH(v_prod_description);
  – TO_CHAR
  – TO_DATE
  – TO_NUMBER
  – TO_TIMESTAMP

• 프로시저문에서 사용할 수 없는 함수:
  – DECODE
  – 그룹 함수

## 3-13

begin
  begin
    p.p('--------------------');
  end;

  declare
    amu varchar2(10) := 'Happy';
  begin
    p.p('Oh '||amu||' Day!');
  end;

  begin
    p.p('--------------------');
  end;
end;
/

//서브 프로그램 화 하기
create or replace procedure p_line
is
begin
  p.p('--------------------');
end;
/

begin
  p_line;
  begin
    p.p('Oh Happy Day!');
  end;
  p_line;
end;
/


## 3-14

declare
  -- 로컬 서프 프로그램이라고 선언하여 사용할 수 있다.
  -- 그냥 begin end 는 declare 에 나올 수 없다.
  procedure p_sub
  is
    begin
      p.p('SSSSSSSSSSSSSSS');
    end;
begin
  begin
    null;
  end;
  exception
    when others then
    begin
      null;
    end;
end;
/



## 변수의 범위와 가시성 (scope visibility)
<<amu>>
DECLARE
  v_father_name VARCHAR2(20):='Patrick';
  v_date_of_birth DATE:='20-Apr-1972';
BEGIN
  DECLARE
    v_child_name VARCHAR2(20):='Mike';
    v_date_of_birth DATE:='12-Dec-2002';
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Father''s Name: '||v_father_name);
    DBMS_OUTPUT.PUT_LINE('Date of Birth: '||amu.v_date_of_birth);
    DBMS_OUTPUT.PUT_LINE('Child''s Name: '||v_child_name);
    DBMS_OUTPUT.PUT_LINE('Date of Birth: '||v_date_of_birth);
  END;
DBMS_OUTPUT.PUT_LINE('Date of Birth: '||v_date_of_birth);
END;
---------
Father's Name: Patrick
Date of Birth: 12-DEC-02
Child's Name: Mike
Date of Birth: 20-APR-72
  - v_father_name, v_date_of_birth 둘다 scope 는 같으나 visibility가 다른다.

* <<amu>> : 한정사 같이 선언해서 해당 상위 변수를 사용 할 수 있도록 함. go to 문장 같이 사용 됨


## 문제: 변수 범위 결정

## 3-19
  <<outer>>
  DECLARE
    v_sal     NUMBER(7,2) := 60000;
    v_comm    NUMBER(7,2) := v_sal * 0.20;
    v_message VARCHAR2(255) := ' eligible for commission';
  BEGIN
    DECLARE
      v_sal        NUMBER(7,2) := 50000;
      v_comm       NUMBER(7,2) := 0;
      v_total_comp NUMBER(7,2) := v_sal + v_comm;
    BEGIN
      v_message := 'CLERK not'||v_message;

      p.p(v_message);         -- 1 CLERK not eligible for commission
      p.p(v_comm);            -- 2 0
      p.p(outer.v_comm);      -- 3 12000

      outer.v_comm := v_sal * 0.30;
    END;
    v_message := 'SALESMAN, '||v_message;

    -- p.p(v_total_comp);     -- 4 에러
    p.p(v_comm);              -- 5 15000
    p.p(v_message);           -- 6 SALESMAN, CLERK not eligible for commission
  END;
  /

## 3-24
  SQL statement 작성 지침
  http://orapybubu.blog.me/40023835579


* 괄호 : parenthesis



===========================
4 장. PL/SQL statement in Block
===========================

-----------------------
 PL/SQL 에서의 SQL 문
-----------------------

## 4-4

BEGIN
  사용불가
  - DDL : CREATE, ALTER, DROP, RENAME, TRUNCATE, COMMET
  - DCL : GRANT, REVOKE
  사용가능
  - DML : INSERT, UPDATE, DELETE, MERGE, SELECT
  - TCL : COMMIT, ROLLBACK, SAVEPOINT
END;

=> 이유 : https://docs.oracle.com/cd/A57673_01/DOC/server/doc/PLS23/ch5.htm#toc043


* PL/SQL 에서 사용되는 DDL, DML 구동 방법
  INSERT INTO ...

  SELECT *
  FROM dept

  EXECUTE IMMEDIATE 'CREATE TABLE .... '

  DELETE from ....
    // 파싱 및 실행 순서
    INSERT INTO 파스 바인드
    SELECT 파스 바인드
    DELETE 파스 바인드
      --- 다 바인드 하고 나서
    INSERT INTO 익스큐트
    SELECT 익스큐트 뱃치
    DELETE 익스큐드

    EXECUTE IMMEDIATE DDL 은 얼리 바인딩 때문에 키워드를 이용해서 사용 해야 한다. 바인딩 하는 동안은 그냥 텍스트로 저장이 되고 실행 할 때 실제 구동된다.

  - SQL 문을 한번에 모아놓고 실행하기 때문에 효율성을 위해서 DDL 을 사용 할수가 없다.
  - PL/SQL 텍스트도 저장이 되지만 반쯤 바인딩이된 컴파일된 파일도 저장되 되어 실행된다.

## WHERE 절에 컬럼명과 같은 변수명은 무조건 컬럼명으로 인식한다.
    DECLARE
      hire_date   employees.hire_date%TYPE;
      sysdate     hire_date%TYPE;
      employee_id employees.employee_id%TYPE := 176;
    BEGIN
      SELECT hire_date, sysdate INTO hire_date, sysdate
      FROM employees
      WHERE employee_id = employee_id; -- 에러
    END;
    /
  - INTO 절의 식별자는 PL/SQL 변수이기 때문에 INTO 절에 모호성이 발생할 가능성은 없습니다. 혼동이 발생할 가능성은 WHERE 절에만 있습니다.


## 4-33 MERGE

-----------
employees 테이블과 일치하도록 copy_emp 테이블에 행을 삽입하거나 행을 갱신

BEGIN
MERGE INTO copy_emp c
    USING employees e
    ON (e.employee_id = c.empno)
  WHEN MATCHED THEN
    UPDATE SET
    c.first_name = e.first_name,
    c.last_name = e.last_name,
    c.email = e.email,
    . . .
  WHEN NOT MATCHED THEN
  INSERT VALUES(e.employee_id, e.first_name, e.last_name,
    . . .,e.department_id);
END;
-----------
> drop table t1 purge;
drop table t2 purge;

create table t1
as
select empno, ename, job, sal
from emp
where rownum <= 10;


  - if key 값이 있으면 then
    update
  else
    insert
  이렇게 하지 않기 위해서 Merge 사용


MERGE INTO t1 a
USING t2 b
ON (a.empno = b.empno)
WHEN WATCHED THEN
  UPDATE -- 테이블명 사용하지 않는다.
  SET a.sal = b.sal,
WHEN NOT MATCHED THEN
  INSERT INTO
  VALUES


-----------------------
 SQL 커서
-----------------------
정의 : 커서는 Oracle 서버에서 할당한 전용(private) 메모리 영역에 대한 포인터입니다. 커서는 SELECT 문의 결과 집합을 처리하는데 사용됩니다.

CURSOR
  - 암시적 커서 : 1건 SELECT, DML 및 DDL에 활용
  - 명시적 커서 : 여러 건 SELECT

## 4-21
* SQL 커서 속성 : SQL 문의 결과 테스트
  - SQL%FOUND
    가장 최근의 SQL 문이 한 행 이상에 영향을 미친 경우 TRUE로 평가되는 부울 속성
  - SQL%NOTFOUND
    가장 최근의 SQL 문이 한 행에도 영향을 미치지 않은 경우 TRUE로 평가되는 부울 속성
  - SQL%ROWCOUNT
    가장 최근의 SQL 문에 의해 영향을 받은 행 수를 나타내는 정수 값

* 쿼리 결과를 확인 하고 싶을 때
BEGIN
  if
END;
/

drop table t1 purge;
create table t1 as select * from emp;

begin
  update t1
  set sal = sal + 100
  where deptno = &sv_deptno;

  if sql%notfound then
    p.p('There are no modifications!');
  end if;

  if sql%found then
    p.p(sql%rowcount||' rows has been fixed.');
  end if;
end;
/

SQL> /
Enter value for sv_deptno: 10

SQL> /
Enter value for sv_deptno: 90


===========================
5 장. 제어 구조 작성
===========================

## 제어 구조
Selection : if statement, case statement
Iteration : basic loop, while loop, for loop
Sequnce : goto, null

-----------------------
 Selection
-----------------------
* if 문의 결과가 null 일경우 else 로 감
* case ~ end 로 끝나면 then 에 값만 가능하다.
  (case 표현식)
* case ~ end case 로 끝나면 then 뒤에 DML 을 넣을 수 있다.
  (case statement)

* Searched case 식
DECLARE
  v_grade CHAR(1) := UPPER('&grade');
  v_appraisal VARCHAR2(20);
BEGIN
  v_appraisal := CASE
  WHEN v_grade = 'A' THEN 'Excellent'
  WHEN v_grade IN ('B','C') THEN 'Good'
  ELSE 'No such grade'
  END;
  DBMS_OUTPUT.PUT_LINE ('Grade: '|| v_grade || 'Appraisal ' || v_appraisal);
END;
/


-----------------------
 Iteration
-----------------------
## LOOP
  LOOP
  statement1;
  . . .
  EXIT [WHEN condition];
  END LOOP;

## WHILE
  WHILE condition LOOP
  statement1;
  statement2;
  . . .
  END LOOP;

## FOR
  FOR counter IN [REVERSE]
  lower_bound..upper_bound LOOP
  statement1;
  statement2;
  . . .
  END LOOP;
 - FOR i IN 의 카운터(i)를 할당 대상으로 참조하지 마십시오.

## 5-28

  ~ i는 할당의 대상이 될 수 없다

  declare
    v_no number;
  begin
    for i in 1..10 loop
      -- i := i + 1;      -- 에러 : PLS-00363: expression 'I' cannot be used as an assignment target
      v_no := i;
    end loop;
  end;
  /

  ~ i는 1씩 증가한다. 다르게 증가하는 것처럼 사용하려면 아래와 같이 한다

  begin
    for i in 0..10 loop
      if mod(i, 2) = 0 then
        p.p(i);
      end if;
    end loop;
  end;
  /

DECLARE
  v_no NUMBER;
BEGIN
  FOR i IN 1..10 LOOP
    P.P(i);
  END LOOP;
END;
/


-----------------------
중첩 루프 및 레이블
-----------------------
* <<label>> 사용

BEGIN
  <<Outer_loop>>
  LOOP
    v_counter := v_counter+1;
  EXIT WHEN v_counter>10;
    <<Inner_loop>>
    LOOP
      ...
      EXIT Outer_loop WHEN total_done = 'YES';
      -- Leave both loops
      EXIT WHEN inner_done = 'YES';
      -- Leave inner loop only
      ...
    END LOOP Inner_loop;
    ...
  END LOOP Outer_loop;
END;
/

## 5-31

begin
  <<multi>>
  for i in 2..9 loop
    p.p(i||':');

    <<campus>>
    for j in 1..9 loop
      p.p(i||' * '||j||' = '||i*j);
      exit multi when i*j > 50;
    end loop;

  end loop;
end;
/


* EXIT(루프를 종료함)
EXIT (loop 이름) WHEN 조건

* CONTINUE(특정 작업을 하지 않도록 함)
DECLARE
  v_total NUMBER := 0;
BEGIN
  <<BeforeTopLoop>>
  FOR i IN 1..10 LOOP
    v_total := v_total + 1;
    dbms_output.put_line('Total is: ' || v_total);
      FOR j IN 1..10 LOOP
        CONTINUE BeforeTopLoop WHEN i + j > 5;
        v_total := v_total + 1;   -- CONTINUE 문에 걸리면 수행하지 않음
      END LOOP;
  END LOOP;
END two_loop;

-----------------------
 Sequnce
-----------------------
https://docs.oracle.com/cd/B19306_01/appdev.102/b14261/controlstructures.htm#BABDBCFF
## GOTO 문
DECLARE
   done  BOOLEAN;
BEGIN
   FOR i IN 1..50 LOOP
      IF done THEN
         GOTO end_loop;
      END IF;
   <<end_loop>>  -- not allowed unless an executable statement follows
   NULL; -- add NULL statement to avoid error
   END LOOP;  -- raises an error without the previous NULL
END;
/

## NULL
NULL : statement 문으로 실행문을 생략해

DECLARE
  v_job_id  VARCHAR2(10);
  v_emp_id  NUMBER(6) := 110;
BEGIN
  SELECT job_id INTO v_job_id FROM employees WHERE employee_id = v_emp_id;
  IF v_job_id = 'SA_REP' THEN
    UPDATE employees SET commission_pct = commission_pct * 1.2;
  ELSE
    NULL; -- do nothing if not a sales representative
  END IF;
END;
/

-----------------------
## 문제. 구구단 출력하기
-----------------------
CREATE or REPLACE PROCEDURE calculator
  (v_empno emp.empno%type, v_num number, v_cal varchar2 )
is
  v_sal emp.sal%type;
  v_result number := 0;
BEGIN
  select sal INTO v_sal
  from emp where empno = v_empno;

  CASE v_cal
    WHEN 'add' THEN --100
      v_result := v_sal + v_num;
    WHEN 'subtract' THEN --100
      v_result := v_sal - v_num;
    WHEN 'multiplication' THEN --1.2
      v_result := v_sal * v_num;
    WHEN 'division' THEN --0.9
      v_result := v_sal / v_num;
    ELSE
      DBMS_OUTPUT.PUT_LINE('no result!');
  END CASE;
    DBMS_OUTPUT.PUT_LINE('v_result : '||v_result);
END;
/

CREATE or REPLACE PROCEDURE calculator
  (v_empno emp.empno%type, v_num number, v_cal varchar2 )
is
  v_sal emp.sal%type;
BEGIN
  select sal INTO v_sal
  from emp where empno = v_empno;
  DBMS_OUTPUT.PUT_LINE(v_sal||' !!!');
END;
/

begin
  --DBMS_OUTPUT.PUT_LINE('here : '||10+1);
  DBMS_OUTPUT.PUT_LINE(10+1);
  DBMS_OUTPUT.PUT_LINE('here : '||10*10);
end;
/



   해답 1.

   create or replace procedure calculator
     (a emp.empno%type,
      b number,
      c varchar2)
   is
     v_ret number;
   begin
     select case c when 'add'            then sal + b
                   when 'subtract'       then sal - b
                   when 'multiplication' then sal * b
                   when 'division'       then sal / b
            end into v_ret
     from emp
     where empno = a;

     p.p(v_ret);
   end;
   /

   해답 2.

   create or replace procedure calculator
     (a emp.empno%type,
      b number,
      c varchar2)
   is
     v_sal emp.sal%type;
   begin
     select sal into v_sal
     from emp
     where empno = a;

     if c = 'add' then
       p.p(v_sal + b);
     elsif c = 'subtract' then
       p.p(v_sal - b);
     elsif c = 'multiplication' then
       p.p(v_sal * b);
     elsif c = 'division' then
       p.p(v_sal / b);
     else
       p.p('There is no such operation!');
     end if;
   end;
   /


===========================
6 장. Composite Data Type
===========================

-----------------------
# VARRAY, NESTED TABLE
-----------------------

-- 잘 사용하지 않음
http://docs.oracle.com/cd/B19306_01/appdev.102/b14260/adobjcol.htm

* 하나의 컬럼값에 여러 값을 배열로 넣음 VARRAY
ORACLE 버전에 따라 RDBMS, OODBMS(8), XMLDBMS(9) 가능
CREATE TYPE people_typ AS TABLE OF person_typ;
/
CREATE TABLE people_tab (
    group_no NUMBER,
    people_column people_typ )
    NESTED TABLE people_column STORE AS people_column_nt;

INSERT INTO people_tab VALUES (
            100,
            people_typ( person_typ(1, 'John Smith', '1-800-555-1212'),
                        person_typ(2, 'Diane Smith', NULL)
                      )
);

* 하나의 컬럼값에 마치 표가 들어가 있는 것 처럼 Nested Tables


-----------------------
# PL/SQL 레코드 사용
-----------------------
## RECORD 구문:
  TYPE type_name IS RECORD
  (field_declaration[, field_declaration]…);

  identifier type_name;
--------------------
  field_declaration:
    field_name {field_type | variable%TYPE | table.column%TYPE | table%ROWTYPE}
    [[NOT NULL] {:= | DEFAULT} expr]
--------------------

DECLARE
  TYPE t_rec IS RECORD
  (v_sal number(8),
  v_minsal number(8) default 1000,
  v_hire_date employees.hire_date%type,
  v_rec1 employees%rowtype);      -- 레코드 안에 또 다른 레코드 선언해서 사용
  v_myrec t_rec;
BEGIN
  v_myrec.v_sal := v_myrec.v_minsal + 500;
  v_myrec.v_hire_date := sysdate;

  SELECT * INTO v_myrec.v_rec1
  FROM employees WHERE employee_id = 100;

  DBMS_OUTPUT.PUT_LINE(v_myrec.v_rec1.last_name ||' '||to_char(v_myrec.v_hire_date) ||' '||to_char(v_myrec.v_sal));
END;

## DECLARE 구문:
DECLARE
  identifier reference%ROWTYPE;
- 데이터베이스 테이블 또는 뷰의 열 컬렉션에 따라 변수를 선언

## 6-10
  create or replace view v7
  as
  select empno, ename, sal, job, hiredate
  from emp;

  create or replace procedure p1(a number)
  is
    r v7%rowtype;
  begin
    select empno, ename, sal, job, hiredate into r
    from emp
    where empno = a;

    p.p(r.ename);
    p.p(r.sal);
  end;
  /

  exec p1(7788)



DECLARE
  v_employee_number number:= 124;
  v_emp_rec retired_emps%ROWTYPE;
BEGIN
  SELECT employee_id, last_name, job_id, manager_id,
  hire_date, hire_date, salary, commission_pct,
  department_id INTO v_emp_rec FROM employees
  WHERE employee_id = v_employee_number;
  INSERT INTO retired_emps VALUES v_emp_rec;  --요기에서 사용
END;
/

DECLARE
  v_employee_number number:= 124;
  v_emp_rec retired_emps%ROWTYPE;
BEGIN
  SELECT * INTO v_emp_rec FROM retired_emps;
  v_emp_rec.leavedate:=CURRENT_DATE;
  UPDATE retired_emps SET ROW = v_emp_rec WHERE
  empno=v_employee_number; --요기에서 사용
END;
/



-----------------------
PL/SQL 컬렉션 사용
-----------------------

* 연관 배열 생성 구문 -------
  TYPE type_name IS TABLE OF
        {column_type | variable%TYPE
        | table.column%TYPE} [NOT NULL]
        | table%ROWTYPE
        | INDEX BY PLS_INTEGER | BINARY_INTEGER |  VARCHAR2(<size>);
  identifier type_name;
  -------
  예제 :
    TYPE ename_table_type IS TABLE OF
      employees.last_name%TYPE
      INDEX BY PLS_INTEGER;
      ...
    ename_table ename_table_type;   -- 변수 선언

* INDEX 를 varchar2 선언한 경우
  ename_table('keyvalue') := 'CAMERON';
  keyvalue : 사용과 동시에 키값 생성

** INDEX BY 테이블 메소드 사용
  - EXISTS(n)
    연관 배열에 n번째 요소가 존재하면 TRUE를 반환합니다.
  - COUNT
    현재 연관 배열에 포함된 요소 수를 반환합니다.
  - FIRST
    • 연관 배열에서 첫번째(가장 작은) 인덱스 번호를 반환합니다.
    • 연관 배열이 비어 있으면 NULL을 반환합니다.
  - LAST
    • 연관 배열에서 마지막(가장 큰) 인덱스 번호를 반환합니다.
    • 연관 배열이 비어 있으면 NULL을 반환합니다.
  - PRIOR(n)
    연관 배열에서 인덱스 n 앞에 나오는 인덱스 번호를 반환합니다.
  - NEXT(n)
    연관 배열에서 인덱스 n 뒤에 나오는 인덱스 번호를 반환합니다.
  - DELETE
    • DELETE 연관 배열에서 모든 요소를 제거합니다.
    • DELETE(n) 연관 배열에서 n번째 요소를 제거합니다.
    • DELETE(m, n) 연관 배열에서 m ... n 범위의 모든 요소를 제거합니다.

## 6-22 Using Collection Methods

  https://docs.oracle.com/cd/B28359_01/appdev.111/b28370/collections.htm#LNPLS005

# 6-23
// 값 하나를 여러 열
create or replace procedure  p1
IS
  type t1_type is table of dept.dname%type
    INDEX BY PLS_INTEGER;
  t t1_type;
BEGIN
  SELECT dname BULK COLLECT INTO t
  FROM dept;

  p.p(t.count);
  p.p(t.first);
  p.p(t.last);
  p.p(t(1));
  p.p('---------------');
  FOR i IN t.first .. t.last loop
    p.p(t(i));
  END LOOP;
END;
/

// 한줄의 row 를 여러열
create or replace procedure p1
is
  type t1_type is table of dept%rowtype
    index by PLS_INTEGER;
  t t1_type;
begin
  select * bulk collect into t
  from dept;

  for i in t.first .. t.last loop
    p.p(t(i).deptno||'  '||t(i).dname||'  '||t(i).loc);
  end loop;
end;
/


# 6-23

  DECLARE
    TYPE dept_table_type IS TABLE OF departments%ROWTYPE
      INDEX by PLS_INTEGER;
    dept_table dept_table_type;
  Begin
    SELECT * bulk collect INTO dept_table FROM departments;

    for i in dept_table.first .. dept_table.last loop
      DBMS_OUTPUT.PUT_LINE(dept_table(i).department_id ||' '||dept_table(i).department_name ||' '||dept_table(i).manager_id);
    end loop;
  END;
  /

# 6-24

  DECLARE
    TYPE emp_table_type IS TABLE OF employees%ROWTYPE
      INDEX BY PLS_INTEGER;
    my_emp_table  emp_table_type;
  BEGIN
    SELECT *  bulk collect INTO my_emp_table
    FROM employees
    WHERE employee_id between 100 and 104;

    FOR i IN my_emp_table.FIRST..my_emp_table.LAST LOOP
      DBMS_OUTPUT.PUT_LINE(my_emp_table(i).last_name);
    END LOOP;
  END;
  /


* 일반적으로 잘 사용되지 않는다.
  - 중첩 테이블 : 테이블 안에 테이블.
  - VARRAY : 테이블 안에 배열로 저장. 데이터베이스 내부에 저장하기 해서 사용.



===========================
첫번째 제목
===========================
-----------------------
 두번쨰 제목
-----------------------
