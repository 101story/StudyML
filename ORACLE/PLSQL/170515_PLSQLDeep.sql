
---------------------
20170428 추가
# in, out 매개변수
 주로 프로시져에서 사용됨
 out return 되는 변수값

 drop table t1 purge;

 create table t1
 as
 select empno c1, sal c2, comm c3
 from emp
 where 1 = 2;

 create or replace procedure p1
 (a in number, b out number, c out number)
 is
 begin
   select sal, comm into b, c
   from emp
   where empno = a;
 end;
 /

 create or replace procedure up_t1_insert(p_empno number)
 is
   v_sal  number;
   v_comm number;
 begin
   p1(p_empno, v_sal, v_comm);

   insert into t1
   values (p_empno, v_sal, v_comm);
 end;
 /

 select * from t1;

 exec up_t1_insert(7788)

 select * from t1;

 exec up_t1_insert(7566)

================================
  Develop PL/SQL Program Units
================================
20170512 추가

---------------------
 (Stored) procedure
---------------------

# Parametr(매개변수)
  - Formal Parameter(형식 매개변수)
    : 프로시져 안에서 선언되어 사용하는 변수값
    ~ in
    ~ out
    ~ in out
  - Actual Parameter(실 매개변수)
    : 프로시져가 실행되기 전에 전달되는 변수값
    ~ positinal
    ~ named (연관연산자 => 사용)
    ~ composite
* 예제
  서버에 저장되는 프로시저
  create or replace procedure p1
      (a in number, b in number, c out number)
  as
  begin
    c := a + b;
  end;
  /

  서버에 프로시저 저장해서 테스트
  [테스트 방법]
  DECLARE
    v_a number := 100;
    v_b number := 100;
    v_c number := 0;
  BEGIN
    p1(v_a, v_b, v_c);                -- positinal
    p1(a => v_a, b => v_b, c => v_c); -- named
    p1(v_a, b => v_b, c => v_c);      -- composite
    p.p(v_c);
  END;
  /

  클라이언트에 선언되는 변수를 이용
  [테스트 방법1]
  var b_out number
  exec p1(100, 101, :b_out)
  print b_out
  --
  [테스트 방법2]
  var b_a number
  var b_b number
  var b_c number
  exec :b_a := 100
  exec :b_b := 100
  exec p1(:b_a, :b_b, :b_out)
  print b_c

* 예제 DBMS_ADVISOR.create_task 검색
  DBMS_ADVISOR.create_task ( advisor_name => DBMS_ADVISOR.sqlaccess_advisor, task_name => l_taskname, task_desc => l_task_desc);
  DBMS_ADVISOR.create_task(dbms_advisor.sqlaccess_advisor, task_id, task_name);

* in out 매개변수 활용 예제
  : 하나의 매개변수로 주고 받는 변수
  입력 v_number := 01012345678
  출력 > 010-1234-5678

  create or replace procedure p1(a in out varchar2)
  is
  begin
    a := substr(a, 1, 3)||'-'||substr(a, 4, 4)||'-'||substr(a, 8);
  end;
  /

  declare
    v_out varchar2(50) := '01012345678';
  begin
    p1(v_out);
    p.p(v_out);
  end;
  /

  @desc dbms_advisor

# 1-23
create or replace procedure up_mode
  (a in number,
   b out number,
   c in out number)
is
  v number;
begin
  -- in a : 상수 취급
  v := a;
  -- a := 100; --Error

  -- out b : 변수 취급
  v := b;
  b := 100;

  -- in out c : 변수 취급
  v := c;
  c := 100;
end;

declare
  v1 number;
  v2 number;
  v3 number;
begin
  -- up_mode(100, 100, 100); --error
  -- out, in out 은 반듯이 변수
  up_mode(100, v2, v3);
  up_mode(v1, v2, v3);
  up_mode(b => v2, c => v3);
end;
/

exec dbms_advisor.UPDATE_SQLWKLD_STATEMENT('ab', cd, ...)

------------------
 (Stored) Function
------------------
# 사용자 정의 함수 생성 및 활용
create or replace Function f1
  (a in number,
   b in number)
   return number
as
begin
  return a*b;
end f1;
/


[사용법 1]
  begin
    dbms_output.put_line(initcap('scott'))
    dbms_output.put_line(f1(100, 100));
  end;
  /

[사용법 2]
  variable b_ret number
  exec :b_ret := f1(100,100)
  print b_ret


[사용법 3]
  select empno, sal, comm, f1(sal, 12) + nvl(comm, 0) as ann_sal
  from emp;

  select empno, sal, comm, f1(b=>12, a=>sal) + nvl(comm, 0) as ann_sal
  from emp;



* -- 기본값 주기
CREATE OR REPLACE PROCEDURE add_dept(
p_name departments.department_name%TYPE:='Unknown',
p_loc departments.location_id%TYPE DEFAULT 1700)

* 모든 위치 지정 파라미터는 이름 지정 파라미터 앞에 와야 합니다.
EXECUTE add_dept(p_name=>'new dept', 'new location')

* 삭제 참고
  테이블-> 트리거 를 만들면
    테이블 삭제시 트리거도 삭제
  테이블 -> 뷰 를 만들면
    테이블 삭제시 뷰는 삭제 되지 않음

* set long 20000
  - 기본 80자리 까지만 노출하도록 설정되어 있는 부분을 변경해줌
* user_source 테이블
  line by line 으로 text 를 보여줌
  clear break break 를 끄고 보면 한행에 들어 있는 것을 확인 할수 있음
  user_triggers
  user_procedures

## 사용자 정의 함수의 다양한 모습
  - rule in만 사용할것
  - return 타입이 sql 에서 사용할수 있도록 할것
-- 생성은 가능하나 사용하지 않음 out 변수
create or replace Function f1
  (a in number,
   b out number,
   c in out number)
   return number
as
begin
  return a + b + c;
end f1;
/
declare
  v1 number := 0;
  v2 number;
  v3 number;
  v4 number;
begin
  v4 := f1(v1, v2, v3);            -- 성공

  select f1(v1, v2, v3) into v4    -- 실패
  from dual;
end;
/

-- record 로 return 하기 생성은 가능하나 rule 에 맞지 않음
create or replace function f1
 (a in number)
  return emp%rowtype
as
  r emp%rowtype;
begin
  select * into r
  from emp
  where empno = a;

  return r;
end f1;
/

declare
  emp_rec emp%rowtype;
begin
  emp_rec := f1(7788);    -- 성공
end;
/

select f1(7788)           -- 실패
from dual;


* SQL 표현식에서 함수를 호출할 때의 제한 사항
  • SQL 표현식에서 호출할 수 있는 유저 정의 함수의 경우:
    – 데이터베이스에 저장해야 합니다.
    – PL/SQL 고유 유형이 아닌 적합한 SQL 데이터 유형을 가진 IN 파라미터만 사용해야 합니다.
    – PL/SQL 고유 유형이 아닌 적합한 SQL 데이터 유형을 반환해야 합니다.
  • SQL 문에서 함수를 호출할 경우:
    – 함수를 소유하거나 EXECUTE 권한을 가지고 있어야 합니다.
    – SQL 문의 병렬 실행을 허용하려면 PARALLEL_ENABLE
    키워드를 활성화해야 할 수 있습니다.

* 함수를 만들면 sql 문에서 바로 사용가능하기 때문에 application java, python 등에서 쉽게 사용 가능 하나 제한사항이 많고 프로시저는 사용하기가 힘들다.


# 여러 행 여러 열 리턴

create or replace package pack1
is
  type emp_rec_tab_type is table of emp%rowtype
  index by pls_integer;

  -- 전역변수 추가 (세션 내에서 계속 존재)
  r emp_rec_tab_type;
end;
/

[1] 프로시져일 경우
create or replace procedure p1
  (a in emp.deptno%type,
  b out pack1.emp_rec_tab_type)
is
begin
  select * bulk collect into b
  from emp where deptno = a;

end;
/

  (사용1)
  DECLARE
    r pack1.emp_rec_tab_type;
  begin
    p1(10, r);

    for i in r.first .. r.last loop
      p.p(r(i).empno);
    end loop;
  end;
  /

  (사용2)
  begin
    for rec in (select deptno from dept) loop
      p1(rec.deptno, pack1.r);
      for i in pack1.r.first .. pack1.r.last loop
        p.p(pack1.r(i).empno);
      end loop;
    end loop;
  exception
    when others then
      null;
  end;
  /


[2] 함수일 경우
create or replace function f1
  (a emp.deptno%type)
  return pack1.emp_rec_tab_type
is
begin
  select * bulk collect into pack1.r
  from emp where deptno = a;

  return pack1.r;
end;
/

  (사용1)
  DECLARE
    r pack1.emp_rec_tab_type;
  begin
    pack1.r = f1(10);

    for i in pack1.r.first .. pack1.r.last loop
      p.p(r(i).empno);
    end loop;
  end;
  /


# Clob

  create or replace function f_terms(term varchar2)
    return clob
  is
    v_ret clob;
  begin
    if lower(term) = 'ai' then
      v_ret := 'Artificial intelligence (AI) is intelligence exhibited by machines.
      In computer science, the field of AI
      research defines itself as the study of "intelligent agents":
      any device that perceives its environment and takes actions that maximize its chance of success at some goal.';

    elsif lower(term) = 'ml' then
      v_ret := 'Machine learning is the subfield of computer science that, according to Arthur Samuel in 1959, gives "computers the ability to learn without being explicitly programmed.';
    end if;

    return v_ret;
  end;
  /

  drop table t1 purge;

  create table t1 (no, name)
  as
  select 1, 'ai' from dual
  union all
  select 2, 'ml' from dual;

  select * from t1;

  select no, upper(name) as term, f_terms(name) as description
  from t1;




======================
  DATA 를 연결하는 방법 4가지
======================

create table t1
as
select empno, ename
from emp;

create table t2
as
select empno, job
from emp;


(1) 조인
  - join 곱샘 연산
  select t1.empno, t1.ename, t2.job
  from t1, t2
  where t1.empno = t2.empno
  order by 1;

(2) Set 연산자
  - union all 은 덧샘
  select empno, ename, ''
  from t1
  union all
  select empno, '', job
  from t2
  order by 1,2;
  select empno, max(ename), max(job)
  from (select empno, ename, ''
        from t1
        union all
        select empno, '', job
        from t2
        order by 1,2
        )
  group by empno
  order by empno;

(3) 서브쿼리
  select empno, ename, (select job from t2 where empno = t1.empno)
  from t1;

(4) 사용자 정의함수
  create or replace fuction uf_emp_job
    (a t1.empno%type)
    return t2.job%type
  is
    v_jobt2.job%type;
  begin
    select job into v_job
    from t2
    where empno = a;
  end;
  /

  select empno, ename, uf_emp_job(empno) as job
  from t1;

  재귀적 SQL 리커시브 SQL



## 병렬처리
  Hint /*+ */

  select /*+ parallel(emp 2) */
  from emp;
  프로세스 2개 + 코디네이터 필요

  select /*+ parallel(emp 2) */
  from emp
  order by sal;
  프로세스가 4개 + 코디네이터 필요

  select /*+ parallel(emp 2) */
    deptno, sum(sal)
  from emp
  group by deptno
  order by deptno;
  프로세스가 6개 + 코디네이터 필요


## mutating error
  update table empset sal = f1(sal)
  where empno =7788
  f1 에서 insert 를 한다면 변경이 진행중인 테이블은 허락하지 않는다.


===================
 package
===================
* 변수
  - public : 패키지. 으로 누구나 사용
  - private : 그 패키지 바디에서만 사용
  - private - local : 그 서브프로그램만

# 예제1 : 패키지 구조 이해

create or replace package pack1
is
  v1 number; --public (global) variable
  procedure p1; -- --public (global) subprogram
  procedure p1(a number);
  procedure setV2(a number);
  function getV2 return number;
end;
/

create or replace body pack1
is
  v2 number; -- private variable


  procedure dash;                 ---- forward declaration
  -- getter setter
  procedure setV2(a number)
  is
  begin
    v2 := a;
  end;


  function getV2 return number
  as
  begin
    return v2;
  end;

  -- 오버로딩
  procedure p1 (a number)
  is
    v3 emp.sal%type;
  begin
    select sal into v3
    from emp
    where empno = a;

    dash;
    p.p(v3);
    dash;
  end;


  procedure p1
  is
    v3 number;
  begin
    v1 := 100;
    v2 := 200;
    v3 := 300;

    p.p(v1);
    p.p(v2);
    p.p(v3);
  end;

  procedure dash                  -- private subprogram
  is
    procedure p                   -- local subprogram
    is
    begin
      dbms_output.put_line('---------');
    end;
  begin
    p;
  end;

  -- 초기화
  procedure init
  is
  begin
    select sum(sal), avg(sal) into v1, v2
    from emp;
  end;
  --- 또는 ----
  begin
    select sum(sal) into v1
    from emp;

    select avg(sal) into v2
    from emp;

end;
/

exec pack1.p1



# 예제2 : 커서의 지속 이해

  create or replace package pack_cursor
  is
    procedure p_open;
    procedure p_fetch;
    procedure p_close;
  end;
  /

  create or replace package body pack_cursor
  is
    cursor c1 is
      select * from emp
      order by sal desc;

    procedure p_open
    is
    begin
      if not c1%isopen then
        open c1;
      end if;
    end;

    procedure p_fetch
    is
      r c1%rowtype;
    begin
      if c1%isopen then
        fetch c1 into r;
        if c1%found then
          p.p(r.empno||' '||r.sal);
        end if;
      end if;
    end;

    procedure p_close
    is
    begin
      if c1%isopen then
        close c1;
      end if;
    end;
  end;
  /

  ** 테스트

  SQL> select * from dept;

  SQL> exec pack_cursor.p_open;
  SQL> exec pack_cursor.p_fetch;

  SQL> select * from dept;
  SQL> select sysdate from dual;

  SQL> exec pack_cursor.p_fetch;
  패키지가 열려있다.
  패키지가 가지고 있는 public 과 private 변수 함수는
  내 세션동안 계속해서 사용할 수 있다.

  SQL> exec pack_cursor.p_open;
  SQL> exec pack_cursor.p_fetch;

  SQL> exec pack_cursor.p_close;

  SQL> exec scott.pack_cursor.p_close@abc(1,22);
  SQL> EXECUTE scott.comm_pkg.reset_comm(0.15)
  scott user 의 pack_cursor 패키지의 어느 원격데이터베이스 abc 서버에서 있는 p_close프로시져 사용

* 포워드 디클러레이션
  참조 되어야 하는 곳을 위에 적어야 아래에서 사용가능 하다.

* 참조 종속
  table <- view <- procedure <- procedure ....
  참조 하고 있는 Tabel, view, procedure, function 등이 변경이 되면
  invalid 가 되어 recomplie 하거나 rewrite 되어야 한다.
  실행하는 순간에 자동으로 가능함
  BUT 매개변수가 변경이 되면 수동으로 Recomplie, Rewrite 해야 한다.

* 종속성 관리
  객체들 관에 종속성 관리
  서버내부에서도 필요함

* 종속 계층 단순화
  참조하여 사용하는 패키지 자체를 참조하여 종속 계층을 단순화해준다.

# 3-19

  1평 = 3.305785 m^2
  1 m^2 = 0.3025 평

  create or replace package unit_conversion
  is
    pyoung2squremeter constant number := 3.305785;
    squremeter2pyoung constant number := 0.3025;
  end;
  /

  create or replace function p2sm(a number) return number
  is
  begin
    return a * unit_conversion.pyoung2squremeter;
  end;
  /

  create or replace function sm2p(a number) return number
  is
  begin
    return a * unit_conversion.squremeter2pyoung;
  end;
  /

  select p2sm(10) as square_meter
  from dual;

  select sm2p(100) as pyoung
  from dual;

  select level as pyoung, p2sm(level) as square_meter
  from dual
  connect by level <= 100;

# Fine Grain
  Fine 미세한 작은 종속성 관리
  Fine-Grain Dependency 관리는 Package Spec이 변경될 때 참조 서브 프로그램을 재컴파일할 필요성을 줄입니다.

===========================
 로컬 서브프로그램 오버로딩
===========================

create or replace procedure p1
is
  procedure sub(a number)
  is
  begin
    p.p('It''s a number!');
  end;
  procedure sub(a varchar2)
  is
  begin
    p.p('It''s a character!');
  end;
begin
  sub(1);
  sub('1');
end;
/

exec p1


# 4-8

create or replace function to_char(a number) return varchar2
is
begin
  if a>0 then
    return 'Positive number';
  elseif a<0 then
    return 'Negative number';
  else
    return 'It''s Zero';
  end if;
end;
/

col ret2 format a30
select to_char(-100) ret1, dream05.to_char(-100) ret2
from dual;
  --- 또는

  create or replace package test
  is
    procedure p1;
  end;
  /

  create or replace package body test
  is

    function to_char(a number) return varchar2
    is
    begin
      if a > 0 then
        return 'Positive number.';
      elsif a < 0 then
        return 'Negative number.';
      else
        return 'It''s zero.';
      end if;
    end;

    procedure p1
    is
    begin
      p.p(to_char(-100));
      p.p(standard.to_char(-100));
    end;

  end;
  /

  exec test.p1


* Purity 레벨
  함수가 부작용으로부터 얼마나 안전한지를 나타냅니다. 부작용이란 읽거나 쓰기 위해 데이터베이스 테이블, 패키지 변수 등에 액세스하는 것을 의미합니다.

  http://www.praetoriate.com/t_high_perform_purity_level.htm

  oracle\product\11.2.0\server\rdbms\admin 디렉토리
  dbmsotpt.sql 을 열어 보면
  put_line WNDS, RNDS

  prvtotpt.plb
  암호화 파일

* Package 함수 예제
  https://oracle-base.com/articles/10g/sql-access-advisor-10g

* 패키지의 지속 상태
  • 패키지가 처음으로 로드될 때 초기화됨
  • 세션 기간 동안 지속됨(기본값):
    – UGA(User Global Area)에 저장됨
    – 세션마다 고유함
    – 패키지 서브 프로그램이 호출되거나 공용(public) 변수가 수정될 때 변경될 수 있음
  • Package Spec에서 PRAGMA SERIALLY_REUSABLE을 사용할 경우 세션 동안 지속되는 대신 서브 프로그램이 호출되는 동안 지속됨
UGA
PGA
세션별 별개의 저장공간

___
