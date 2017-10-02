
http://dbinv.co.kr/ : 강사님 회사 사이트
DATA-BASED INVESTMENT

===========================
 10장 테이블 생성 및 관리
===========================
스키마는 데이터의 논리적 구조 또는 스키마 객체의 모음입니다. 스키마는 데이터베이스 유저가 소유하며 해당 유저와 동일한 이름을 가지고 있습니다. 각 유저는 단일 스키마를 소유합니다.
USERB가 소유한 EMPLOYEES 테이블에 USERA가 액세스하려면 USERA는 다음과 같이 테이블 이름 앞에 스키마 이름을 추가해야 합니다.

데이터 베이스 객체
• 테이블: 데이터를 저장합니다.
• 뷰: 하나 이상의 테이블에 있는 데이터의 부분 집합입니다.
• 시퀀스: 숫자 값을 생성합니다.
• 인덱스: 일부 질의 성능을 향상시킵니다.
• 동의어: 객체에 다른 이름을 부여합니다.

DDL: 자료구조를 만들고 관리하는 command

------------------------
 테이블
------------------------

특수한 alias to_char 안에 서 "" 사용
also "table name" 로 테이블 명 사용이 가능은 하나 쓰지 말자!
예약어는 이름으로 사용 불가
  https://docs.oracle.com/database/121/SQLRF/ap_keywd001.htm#SQLRF55621

# 10-5

schema = user : 매핑되지만 다른것
create table t1 ....
create view t1 .... (불가)
create index t1 .... (가능)

하나의 name space 안에 두개의 동일한 객체를 가질수 없다.
http://docs.oracle.com/cd/B19306_01/server.102/b14200/sql_elements008.htm#i27561

Within a namespace, no two objects can have the same name.
# The following schema objects share one namespace:

 - Tables
 - Views
 - Sequences
 - Private synonyms
 - Stand-alone procedures
 - Stand-alone stored functions
 - Packages
 - Materialized views
 - User-defined types

# Each of the following schema objects has its own namespace:

 - Indexes
 - Constraints
 - Clusters
 - Database triggers
 - Private database links
 - Dimensions


출처: http://kwangsics.tistory.com/entry/펌-네임스페이스에서-이름생성-방법Within-a-namespace-no-two-objects-can-have-the-same-name


# 10-7

 * Data integrity : 데이터 무결성은 비지니스 룰을 기준으로 판단된다.

drop table d1 purge;
drop table e1 purge;

create table d1
  (dno    number(2),
    dname varchar2(30),
    loc   varchar2(30)
  );
create table e1
  (empno  number(4),
    ename varchar2(30),
    sal   number(10,2),
    hp    varchar2(11),
    deptno number(2)
  );

select table_name, tablespace_name
from user_tables
where table_name in('D1','E1');

insert into d1
  values (10, 'SALES', 'SEOUL');
insert into d1
  values (10, 'MARKETING', 'SUWON');

select * from d1;

---

drop table e1 purge;
drop table d1 purge;

create table d1
(dno   number(2)    primary key,
dname varchar2(30) not null,
loc   varchar2(30));

create table e1
(empno  number(4)     primary key,
ename  varchar2(30)  not null,
sal    number(10, 2) check(sal >= 1000),
hp     varchar2(11)  not null unique,
deptno number(2)     references d1(dno));

select table_name, tablespace_name
from user_tables
where table_name in ('D1', 'E1');

select table_name,
    constraint_name,
    constraint_type,
    search_condition
from user_constraints
where table_name in ('D1', 'E1');

select table_name, index_name
from user_indexes
where table_name in ('D1', 'E1');

---
>> column-level constraint

drop table d1 purge;
drop table e1 purge;

create table d1
(dno   number(2)    constraint d1_dno_pk   primary key,
dname varchar2(30)  constraint d1_dname_nn not null,
loc   varchar2(30));

create table e1
(empno  number(4)     constraint e1_empno_pk  primary key,
 ename  varchar2(30)  constraint e1_ename_nn  not null,
 sal    number(10, 2) constraint e1_sal_ck    check(sal >= 1000),
 hp     varchar2(11)  constraint e1_hp_nn     not null
                      constraint e1_hp_uk     unique,
 deptno number(2)     constraint e1_deptno_fk references d1(dno));


// sal   number(10,2) check(sal>=1000) 논리식 검삭 후 값 추가
// deptno number(2)  references d1(dno) 참조 무결성
// ename varchar2(30) not null : 논리식 검사 후 값 추가

* 식별자 : what are we talking about!! 무엇에 대해서 말하고 있느냐
  empno 또는 hp 가 식별자가 될 수 있다.

// 제약 조건 확인
select table_name, constraint_name, constraint_type, search_condition
from user_constraints
where table_name in('D1','E1');

* oracle 은 primary key(테이블에 1개만 가능), unique key 를 생성하면 키로 index 를 생성한다.
select table_name, index_name
from user_indexes
where table_name in('D1','E1');

dno number(2) constraint d1_dno_pk primary key
: 제약에 이름을 붙여줄 수 있음 (관리 시 필요)
: Oracle 서버가 SYS_Cn 형식을 사용하여 이름을 생성할

* foreign key : pk, uk 제약이 걸려있는 것만 가능, 인덱스가 있는 컬럼만 가능, index 와 비교해서 허락 또는 거부 판단한다. 참조 무결성
값을 넣지 않아도 된다. null 허용
  Master|Parent(pk) - Slave|Child(fk)
  • ON DELETE CASCADE: 상위 테이블의 행이 삭제될 때 하위 테이블의 종속 행을 삭제합니다. (부모가 지워지면 나도 지워지겠다.)
  • ON DELETE SET NULL: 종속 Foreign key 값을 null로 변환합니다

* table instance chart : they need to look out for the entries in the Column Name, Data Type, and Length fields. The other
entries are optional, and if these entries exist, they are constraints that need to be incorporated as a part
of the table definition.

 ------
>> table-level constraint

drop table e1 purge;
drop table d1 purge;

create table d1
(dno   number(2),
 dname varchar2(30),
 loc   varchar2(30),
   constraint d1_dno_pk   primary key(dno),
   constraint de_dname_nn check(dname is not null)
);

create table e1
(empno  number(4),
 ename  varchar2(30),
 sal    number(10, 2),
 hp     varchar2(11),
 deptno number(2),
   constraint e1_empno_pk  primary key(empno),
   constraint e1_ename_nn  check(ename is not null),
   constraint e1_sal_ck    check(sal >= 1000),
   constraint e1_hp_nn     check(hp is not null),
   constraint e1_hp_uk     unique(hp),
   constraint e1_deptno_fk foreign key(deptno) references d1(dno) ON DELETE SET NULL
);

cf. 두개 이상의 컬럼에 하나의 제약을 설정하려면 반드시 table-level 을 사용해야 함 (주민번호)
create table t_dumin
  (
    no number(10),
    ju1 varchar2(8),
    ju2 varchar2(8),
    unique(ju1, ju2)
  )
 ------

* create table e1 (empno  number(4) default '0');
default '0' : 입력할떄 값이 없으면 defaul 값을 넣어줌

# 10-9 Pseudocolumn
  : 진짜가 아닌 흉내만 낸 컬럼
  : https://docs.oracle.com/cd/B28359_01/server.111/b28286/pseudocolumns.htm#SQLRF0025
  : default 뒤에는 나올 수 없다.

* ROWID Pseudocolumn : 64진법 어느 객체의 어느 파일의 몇번째 블럭의 몇번째 로우인지, 로우의 위치값
> select rowid, e.* from emp e;
* ROWNUM Pseudocolumn : where 절을 통과하면 붙는 번호로 사용하는 커럼
> select rownum, e.*
from emp e;
> select rownum, e.*
from emp e
where sal > 1500;

* Pseudocolumn vs functions without arguments
> select rownum, rowid, sysdate, user, empno, ename
from emp;



# 대표적인 pseudocolumn들

  rownum  <- where 통과시 붙는 번호

  rowid   <- 인덱스

  level   <- 계층질의

  currval <- sequence

  nextval <- sequence

# rownum의 의미
  > rownum return 이 될떄 붙는 번호
  주로 서브쿼리에서 의미있게 사용됨
  top n
  우선 가장 위에 3개만

  select rownum, e.*
  from emp e;

  select rownum, e.*
  from emp e
  where job = 'SALESMAN';

# 비교

  select /* 엉터리 */
    rownum as no, e.*
  from emp
  where rownum <= 3
  order by sal desc;

  select /* 제대로 */
    rownum as no, e.*
  from (select *
        from emp
        order by sal desc) e;

  select /* 제대로 */
    rownum as no, e.*
  from (select *
        from emp
        order by sal desc) e
  where rownum <= 3;

# 5번째에서 10번째

  select *
  from (select /* 제대로 */
          rownum as no, e.*
        from (select *
              from emp
              order by sal desc) e)
  where no >= 5
  and   no <= 10;

# rownum 이해

  select * from emp
  where rownum >= 3

  > 한줄 한줄 리턴될때마다 조건에서 탈락해서
  첫번쨰 라인 rownum = 1 3 보다 작아서 탈락
  두번쨰 라인 rownum = 1 3 보다 작아서 탈락
  선택된게 없다.

------------------------
 데이터 유형
------------------------
VARCHAR2(size) 가변 길이 문자 데이터
CHAR(size) 고정 길이 문자 데이터
NUMBER(p,s) 가변 길이 숫자 데이터
DATE 날짜 및 시간 값
LONG 가변 길이 문자 데이터(최대 2GB)
CLOB 문자 데이터(최대 4GB)
RAW and LONG RAW 원시 이진 데이터
BLOB 바이너리 데이터(최대 4GB)
BFILE 외부 파일에 저장된 바이너리 데이터(최대 4GB)
ROWID 테이블에 있는 행의 고유한 주소를 나타내는 base-64 숫자 체계

# 10-12
oracle 은 row를 메모리에 저장될때 길이와 데이터가 같이 들어가기 때문에
char, varchar2 똑같은 결과를 가져온다. [길이|데이터|길이|데이터]
* row 의 migration
  처음 자리에 넣지 못하고 다른곳에 들어가게 되는것 update
* data의 migration
  io 의 비효율이 생김
  index 찾고 -> 원래 데이터위치에가서 이동된 주소를 알고 -> 다시 이동된 데이터 위치로 간다.
* update 에 대한 대비로 메모리에 테이블을 저장할때 한곳에 70%만 채우고 30%의 여유 공간을 만듬 (수치는 모름)
* 연구용 목적으로 일부러 공간을 차지하게 할때 char 를 사용하기도 함 but! 그게 아니면 varchar2 를 사용하는게 좋음
* where t1.ename = 'scott' (char)
  where t2.ename = 'scott' (varchar2)
  where t1.ename = t2.ename 가 다를 수 있다.

문자
  - 고정길이 : char       ename char(10) <- scott
  - 가변길이 : varchar2   ename varchar2(10) <- scott
  - 2G 길이 : long
  - 128T 길이 : clob
숫자
  - 정수 : number(4)
  - 고정소수점(fixed) : number(10,2) 정수 10 자리 소수점 2자리
  - 부동소수점(float) : number 모든걸 다 받을수 있지만 좋지 않음
  -> http://gseducation.blog.me/20095938837

날짜
  - date : 고정 7byte 초단위 이하는 표현불가능
  - timestamp : 초단위 9자리 까지 표현 가능
  - interval : 3일 3시간 sysdate+3+3/24 => sysdate + intervale day to second '3 3'
기타
  - raw
  - long row
  - LOB: clob, blob, bfile


------------------------
 Subquery를 사용하여 테이블 생성
------------------------
CREATE TABLE table
        [(column, column...)]
AS subquery;

CREATE TABLE dept80
AS
  SELECT employee_id, last_name,
      salary*12 ANNSAL,
      hire_date
  FROM employees
  WHERE department_id = 80;

------------------------
  ALTER DROP TABLE 문
------------------------
ALTER TABLE 구문을 사용하여 다음을 수행할 수 있습니다.
• 테이블을 읽기 전용 모드로 설정하여 테이블을 유지 관리하는 동안 DDL 문 또는 DML 문에 의한 변경을 방지합니다.
• 테이블을 다시 읽기/쓰기 모드로 설정합니다.
ALTER TABLE employees READ ONLY;
-- perform table maintenance and then
-- return table back to read/write mode
ALTER TABLE employees READ WRITE;

DROP TABLE table [PURGE]

리컴파일, 리벨리(?) 로 관련 종속 데이터들은 invalid 상태가 된다.


=========================================
 9장 데이터 조작
=========================================
* 트랜잭션은 논리적 작업 단위를 형성하는 DML 문의 모음으로 구성됩니다.
  DMS 의 집합

------------------------
  INSERT INTO
------------------------
INSERT INTO table [(column [, column...])]
VALUES (value [, value...]);

// date 포맷이 맞지 않아도 삽입 가능하다.
INSERT INTO employees
VALUES (114,
      'Den', 'Raphealy',
      'DRAPHEAL', '515.127.4561',
      TO_DATE('FEB 3, 1999', 'MON DD, YYYY'),
      'SA_REP', 11000, 0.2, 100, 60);

// INSERT 문을 subquery로 작성합니다.
INSERT INTO sales_reps(id, name, salary, commission_pct)
    SELECT employee_id, last_name, salary, commission_pct
    FROM employees
    WHERE job_id LIKE '%REP%';

# 9-12

insert into t1
select deptno, loc
from dept
where deptno > 20;

select * from t1;

------------------------
  UPDATE
------------------------
UPDATE table
SET column = value [, column = value, ...]
[WHERE condition];

# 9-15 Implicit Query
  http://gseducation.blog.me/20125786704
암시적쿼리
  where 절을 주지 않으면 발생함

명시적쿼리

------------------------
  DELETE
------------------------
DELETE [FROM] table
[WHERE condition];


------------------------
  TRUNCATE
------------------------
TRUNCATE TABLE table_name;
(초기화)

# 9-25
  ----------------------------------
                  공간의 반납        rollback 가능여부
drop table t1;      몽땅반납               X
truncate table t1;  최초크기만남기고반납    X
delete from t1;     전혀 반납하지 않음      O
  ----------------------------------
rollback, undo 세그먼트가 존재


------------------------
  트랜잭션
------------------------
* 데이터베이스 트랜잭션은 다음 중 하나로 구성됩니다.
  • 데이터를 일관되게 변경하는 여러 DML 문
  • 하나의 DDL 문
  • 하나의 DCL(데이터 제어어) 문

* 데이터베이스 트랜잭션: 시작과 종료
  • 첫번째 DML SQL 문이 실행될 때 시작됩니다.
  • 다음 상황 중 하나가 발생하면 종료됩니다.
  – COMMIT 또는 ROLLBACK 문 실행
  – DDL 또는 DCL 문 실행(자동 커밋)
  – 유저가 SQL Developer 또는 SQL*Plus를 정상종료(exit명령어로 자동커밋)
  – 시스템 중단 (자동롤백)

* SAVEPOINT
  COMMIT, SAVEPOINT 및 ROLLBACK 문을 사용하여 트랜잭션 논리를 제어할 수 있습니다.
  SAVEPOINT name은 현재 트랜잭션 내에 저장점을 표시합니다.
  ROLLBACK TO SAVEPOINT name

* 명령문 레벨 롤백
  • 단일 DML 문을 실행하는 중에 오류가 발생하면 해당 명령문만 롤백됩니다.
  • Oracle 서버는 저장점을 암시적으로 구현합니다. (SAVEPOINT)
  • 다른 모든 변경 사항은 보존됩니다.
  • 유저는 COMMIT 또는 ROLLBACK 문을 실행하여 트랜잭션을 명시적으로 종료해야 합니다.
  => ex) update 문을 쳤는데 중간 row 에 check 에 걸려 다 update 를 할 수 없는 경우

* oracle 은 select 문과 dml 문이 별개로 사용 가능하다.
  (lock 되지 않는다. 다른 mysql 은 lock 발생 가능)
  BUT!!!! FOR UPDATE 사용시 lock 에 걸림
  SELECT employee_id, salary, commission_pct, job_id
  FROM employees
  WHERE job_id = 'SA_REP'
  FOR UPDATE
  ORDER BY employee_id;

  // EMPLOYEES 테이블 및 DEPARTMENTS 테이블의 행이 잠깁니다.
  SELECT e.employee_id, e.salary, e.commission_pct
  FROM employees e JOIN departments d
  USING (department_id)
  WHERE job_id = 'ST_CLERK'
    AND location_id = 1500
  FOR UPDATE
  ORDER BY e.employee_id;

  >> FOR UPDATE OF column_name을 사용하여 변경할 열을 지정할 수 있습니다.
  SELECT e.employee_id, e.salary, e.commission_pct
  FROM employees e JOIN departments d
  USING (department_id)
  WHERE job_id = 'ST_CLERK' AND location_id = 1500
  FOR UPDATE OF e.salary
  ORDER BY e.employee_id;

  >> 다음 예제에서 데이터베이스는 행을 사용할 수 있을 때까지 5초간 기다린 후 유저에게 제어를 반환합니다.
  SELECT employee_id, salary, commission_pct, job_id
  FROM employees
  WHERE job_id = 'SA_REP'
  FOR UPDATE WAIT 5
  ORDER BY employee_id;

# 9-45
> select e.empno, e.ename, e.sal
from emp e
where deptno in (select deptno
                 from dept
                 where loc = 'DALLAS');

> select e.empno, e.ename, e.sal
from emp e, dept d
where d.loc = 'DALLAS'
and e.deptno = d.deptno
for update of sal;


===========================
 튜터의 문제
 '112.111.111(.122)'전화번호 3번쨰 자리를 * 만들어라
===========================

select rpad(
      substr('123.123.1111.111', 1, instr('123.123.1111.111','.',1,2)), decode(instr('123.123.1111.111','.', 1,3), 0, length('123.123.1111.111'), instr('123.123.1111.111','.', 1,3)),
      '*')
from dual;


select phone_number, rpad(
      substr(phone_number, 1, instr(phone_number,'.',1,2)), decode(instr(phone_number,'.', 1,3), 0, length(phone_number), instr(phone_number,'.', 1,3)),
      '*') newPhone
from employees;


col newphone format a20
select phone_number,
      rpad(
            substr(phone_number, 1, instr(phone_number,'.',1,2)),
            decode(instr(phone_number,'.', 1,3), 0, length(phone_number), instr(phone_number,'.', 1,3)-1),'*')
      ||decode(instr(phone_number,'.', 1,3), 0, '', substr(phone_number, instr(phone_number,'.', 1,3),length(phone_number))) newPhone
from employees;


select ename, substr(ename, null)
from emp;

=======
추가
=======
연산자 반환
UNION 중복 행이 제거된 두 query의 행
UNION ALL 중복 행이 포함된 두 query의 행
INTERSECT 두 query에 공통적인 행
MINUS 첫번째 query에 있는 행 중 두번째 query에 없는 행

===========================
 첫번째 제목
===========================

-----------------------
 두번쨰 제목
-----------------------
