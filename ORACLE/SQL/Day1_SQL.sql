
노트북 와이파이 / 멀캠5880
무선암호 guest1357


70.12.50.50

난 5번
총24명

강사님 까페
http://cafe.naver.com/gseducation

주소 : http://naver.me/FS3f1Pr2
암호 : 1234

==데이터베이스==========================

관계형DB(SQLDB)=자료구조(표)+입출력(SQL)
비관계형(Not Only SQL)=표 등의 여러 자료구조 이용
RDB는 3만오천건 처리 가능(초당) 그 이상은 비관계형을 주로 이용

Distributed File System = 하둡.....

Data: 자료, 회사의 자산, 경험의 축척

create user dream01
identified by catcher;

//강사님 서버로 접속(동일 아이디)
sqlplus dream05/catcher@70.12.50.50:1521/XE

Database: .doc, 생성한다.
DBMS: 설치한다.


** 압축파일 받아서 설치
//기존의 패스는 다 지워짐
//set path C:\instantclient_12_1
set path=C:\instantclient_12_1;%path%
--> notepad ic.bat //파일만들어서 환경 저장해 놓기
>more ic.bat	//내용보기
>ic //ic 파일 실행


** 랜덤 쿼리
SQL> ed r.sql //r.sql 파일 만들어서 실행가능하게 해줌
select no as you
from(select level as no
from dual
connet by level <= 24
order by dbms_random.value)
where rownum=1;
SQL> @r


** 표 만들기
>create table friends
(name varchar2(10 char) not null,
nick varchar2(10) unique,
hp varchar2(11), birth_date date);
>drop table friends;
char(10) 고정길이
varchar2(10) 가변길이
(10 char) 언어에 상관없이 10글자로 받아 들이겠다,
data type
data structure
DDL : 데이터의 자료구조(표...) 를 만드는 신텍스
table instance chart: 데이터 모델링을 통해 도출된 테이블 구조

** sql 안에 스크린 지우기
>clear screen
>cle scr
>ed c.sql //sql 파일 만들기
>@c //c.sql 파일 실행

** 관계형DB 표
한열의 같은 데이터타입 끼리 저장되어 있음
한행 한행 다시 만들어지는거(?)


** null
null 값은 서로 비교 불가능 하다 (기본정의-학설이 다름)
T, F, N 모름

** unique
null 값이여도 유니크 하기만 하면 허용가능 하다.
식별자 역할을 할수가 없다.


** insert
>insert into friends
values('방형욱', 'Eddy', '01012341234', sysdate);

** 한글깨짐
cmd 창에서
>regit
oracle 폴더> key_xe
NLS_LANG 에 KOREAN_KOREA.KO16MSWIN949가 있어야됨
환경변수로 추가


** SQL DEVELOPER 실행
접속 > 새접속
접속 정보 입력 후 진행


** 방형욱 SQL 도서 사이트
http://cafe.naver.com/n1books/11


** sql 자동실행
카페에서 파일 2개 다운받아서 끌어 cmd 창에 놓으면 명령어가 실행
테이블 생성 및 기본 테스트 환경 설정
SQL> @'C:\Users\student\Documents\jhfolder\creobjects.sql'
SQL> @'C:\Users\student\Documents\jhfolder\demobld.sql'
SQL> select * from tab;
SQL> select * from dept;


** 커밋
DML 은 커밋을 하지 않고 창을 종료하게 되면 롤백됨
ddl, dcl 은 자동커밋됨
