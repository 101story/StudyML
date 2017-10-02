Resource Plan
  https://docs.oracle.com/cd/E11882_01/server.112/e25494/dbrm.htm#ADMIN13327
  낮에 백업작업을 하면 자원 소모가 너무 크니
  여러그룹으로 나누고 그룹 (유저단위 또는 어플리케이션단위)
  특정 그룹에서 복구 백업작업을 진행 할수 있다.

Jobs
  https://docs.oracle.com/cd/B28359_01/server.111/b28310/scheduse002.htm#ADMIN12384
  job 을 job class 로 묶고 Consumer Group 에 연관되어 있으면
    Consumer Group 에 해당되는 리소스만 사용하고 다른 리소스에 영향을 주지 않는다.

Database Maintenance
  AWS
    저장소 오랜된것은 자동을 처리해 줌
  Automated tasks
    스케쥴러 와 리소스 매니져를 같이 사용하는 것이 더 효율 적이다.

MMON
  퍼포먼스 관련 데이터를 우리가 모르는 사이에 계속 쌓아 둔다.

ADDM
  분석가
  • CPU bottlenecks
  • Poor Oracle Net connection management
  • Lock contention
  • Input/output (I/O) capacity
  • Undersizing of database instance memory structures
  • High-load SQL statements
  • High PL/SQL and Java time
  • High checkpoint load and cause (for example, small log files)

Autotask 자동화된 유지관리 업무
  create window
  plan 에 자동실행
  언제부터 언제까지 얼마나

DBA_OUTSTANDING_ALERTS
  발생한 alert 들이 모이는 곳
  해결되면 DBA_ALERT_HISTORY 에 남음

Resumable Session Suspended
  DML 을 하다가 테이블 공간이 모자라서 멈추면
  공간확보 후 다시 시작할 수 있도로함


unuserble index 가리키던 테이블이 이전했을 때
alter table emp move tablespace ts1;
ALTER INDEX HR.emp_empid_pk REBUILD;
인덱스도 rebuild 해야 한다.

============================================
 13장 Performance Management
============================================

wait cpu 사용률
  wait 이 너무 커도 문제이지만
  (쿼리 결과가 나올때까지 기다림이 59분 후 수행은 1분)
  cpu 만 많이 사용한다고 해도
  (기다림은 없는데 쿼리를 수행하는데 먼~~~거리를 돌아서 돌아서 쿼리를 수행해 옴)
  문제이다.


==============================
  ### STATISTICS 분류 실습
==============================

       (1) Activity

	v$statname : activity 관련 지표 설명 : http://goo.gl/tw678
	v$sysstat  : 인스턴스 시작 이후 있었던 모든 세션의 activity 누적
	v$sesstat  : 현재 연결중인 각 세션의 activity 누적
	v$mystat   : 현재 세션의 activity 누적

	select * from v$statname;
	select * from v$statname where class = 2;
	select * from v$statname where class = 8;

	select * from v$sysstat;
	select * from v$sysstat where class = 2;
	select * from v$sysstat where class = 8;

	select * from v$sesstat;

	select * from v$sysstat where statistic# = 11;
	select * from v$sesstat where statistic# = 11 order by value desc;

	select * from v$mystat;
	select * from v$sesstat where sid = userenv('sid');

       (2) Wait

	v$event_name    : wait 관련 지표 설명 : http://goo.gl/qnNRX
	v$system_event  : 인스턴스 시작 이후 경험한 모든 wait 누적
	v$session_event : 현재 연결중인 각 세션이 경험한 wait 누적
	v$session (또는 v$session_wait) : 현재 각 세션의 wait 누적 각 세션이 뭘 기다리고 있는지 보여줌

	--> Wait? Syscall? http://carymillsap.blogspot.com/2009/02/dang-it-people-theyre-syscalls-not.html

	select * from v$event_name where name like 'db file%';

	select * from v$event_name;
	select * from v$event_name where wait_class = 'Idle';
	select wait_class, count(*) from v$event_name group by wait_class order by 1;
	select * from v$event_name where name like 'enq: TX%'

	select * from v$system_event;   --> 경험한 wait만
	select * from v$session_event;
	select * from v$session_event where sid = userenv('sid');
	select * from v$session;

       (3) Others

	select * from v$fixed_table
	where name like 'V$%';

	select * from v$fixed_view_definition
	order by view_name;


# Metric

  Performance statistics : ex> physical reads 지표
   ↓
  Metric                 : ex> physical reads/초당, physical reads/tx
   ↓
  Server Alert           : Alerts are notifications of when a database is in an undesirable state and needs your attention.

# Alert

  - Tool Alert   (Pull Model)
    (MRI, 정밀검사 세밀한 검사로 증상이 없는 곳도 찾아냄)
  - Server Alert (Push Model) -> Metric-based Alert
                              -> Event-based Alert
    (재체기, 발열 몸에서 발생시키는 문제의 알림)

  alert 가 뜨면 어떻게 해라 까지 처리 가능
  threshold alert : 임계치 얼럿
  metric 기반 alert : metric 값이 85% 일때 또는 97% 일때 alert

# Statistics 이해

[1] Optimizer Statistics

 [oracle@ora11gr2 ~]$ export ORACLE_SID=orcl
 [oracle@ora11gr2 ~]$ sqlplus / as sysdba
 SQL> startup force
 SQL> alter user scott identified by tiger account unlock;

 SQL> conn scott/tiger
 SQL> insert into emp select * from emp;            --> 에러

 SQL> alter table emp disable constraint PK_EMP;
 SQL> insert into emp select * from emp;
 SQL> insert into emp select * from emp;
 SQL> commit;

 SQL> select * from emp;
 SQL> select table_name, NUM_ROWS, BLOCKS, AVG_ROW_LEN from user_tables;

	TABLE_NAME                                                     NUM_ROWS     BLOCKS AVG_ROW_LEN
	------------------------------------------------------------ ---------- ---------- -----------
	DEPT
	EMP                                                                  14          5          37
	BONUS
	SALGRADE

 SQL> desc dbms_stats
 SQL> exec dbms_stats.gather_table_stats(user, 'EMP')

 SQL> select table_name, NUM_ROWS, BLOCKS, AVG_ROW_LEN from user_tables;

	TABLE_NAME                                                     NUM_ROWS     BLOCKS AVG_ROW_LEN
	------------------------------------------------------------ ---------- ---------- -----------
	DEPT
	EMP                                                                  56          5          37
	BONUS
	SALGRADE

 SQL> delete from emp e
      where rowid > (select min(rowid) from emp
                     where empno = e.empno);

 SQL> exec dbms_stats.gather_table_stats(user, 'EMP')
 SQL> select table_name, NUM_ROWS, BLOCKS, AVG_ROW_LEN from user_tables;

	TABLE_NAME                                                     NUM_ROWS     BLOCKS AVG_ROW_LEN
	------------------------------------------------------------ ---------- ---------- -----------
	DEPT
	EMP                                                                  14          5          37
	BONUS
	SALGRADE

[2] Performance Statistics

 (1) user-managed snapshot

	[oracle@ora11gr2 ~]$ export ORACLE_SID=orcl
	[oracle@ora11gr2 ~]$ sqlplus / as sysdba

	SQL> create table scott.my$sysstat as select 0 no, a.* from v$sysstat a where 1=2;
	SQL> insert into  scott.my$sysstat select 1 no, a.* from v$sysstat a;
	SQL> insert into  scott.my$sysstat select 2 no, a.* from v$sysstat a;
	SQL> insert into  scott.my$sysstat select 3 no, a.* from v$sysstat a;
	SQL> insert into  scott.my$sysstat select 4 no, a.* from v$sysstat a;
	SQL> commit;

	SQL> col name format a40
	SQL> set pause on
    -->> 화면 멈춤
	SQL> select * from scott.my$sysstat order by STATISTIC#, no;
	SQL> exit

 (2) utlbstat.sql 및 utlestat.sql

	[oracle@ora11gr2 ~]$ cd $ORACLE_HOME/rdbms/admin
	[oracle@ora11gr2 admin]$ ls utl*stat.sql
	[oracle@ora11gr2 admin]$ vi utlbstat.sql     --> stats를 저장할 테이블 생성, 첫번째 snapshot 생성
    --> stats$begin from v$... 로 정보를 수집함
	[oracle@ora11gr2 admin]$ vi utlestat.sql     --> 두번째 snapshot 생성, summary 테이블 생성, report 생성, stats를 저장하고 있는 테이블 삭제
    --> 시간이 좀 지난 다음에 돌림 insert 구문 조인을해서 델타값(변화량) 을 생성 spool 로 파일에 report.txt 로 저장 후 테이블 삭제

 (3) statspack

	** http://download.oracle.com/docs/cd/B10501_01/server.920/a96533/statspac.htm#34837

	[oracle@ora11gr2 admin]$ ls sp*
	[oracle@ora11gr2 admin]$ more spcreate.sql --> 환경설정
	[oracle@ora11gr2 admin]$ more spauto.sql --> dbms_job.submit(....) job 이 돌아 갈때 statspack 을 자동으로 돌아가게 만듬
	[oracle@ora11gr2 admin]$ more spreport.sql --> 보고서 만들기

	[oracle@ora11gr2 admin]$ sqlplus / as sysdba
	SQL> @spcreate.sql
    --> 별도의 user 만들기 prfstat (그냥 다 엔터 다 그대로 하겠다.)
    --> 유저 소유의 여러 v$ 를 담을 수 있는 table 을 만듬
	SQL> show user --> prfstat 유저 확인

	SQL> col object_name format a40
	SQL> select object_name, object_type from user_objects order by 2, 1;
    -- 148개의 객체 생성 user, table, synonim, .. 등 생성

	SQL> desc statspack

		- PROCEDURE SNAP
		- FUNCTION SNAP RETURNS NUMBER(38)

  -- 프로시져로 호출
	SQL> exec statspack.snap
	SQL> exec statspack.snap
    -- SQL> exec statspack.snap(5, ...) 스냅샷 레벨 (수집되는 내용의 레벨 정함)

  -- 함수로 호출하기
	SQL> var sn number
	SQL> exec :sn := statspack.snap
	SQL> print sn

	SQL> exec :sn := statspack.snap
	SQL> exec :sn := statspack.snap

	SQL> @spreport.sql

	--> 생성된 보고를 분석해서 문제의 원인과 해결책을 찾아내셔야 합니다.
	--> http://orapybubu.blog.me/40014540506

 (4) AWR + MMON + ADDM

	--> AWR은 sys 소유의 테이블들을 지칭하며, 이 테이블들은 sysaux 테이블스페이스에 있습니다.

	--> EM에서 sysaux 테이블스페이스의 Occupants를 클릭하셔서 AWR을 확인하세요.
	--> EM에서 Automatic Workload Repository를 클릭하셔서 snapshot을 확인하세요.
	--> EM에서 Advisor Central 클릭하셔서 ADDM 분석 결과를 확인하세요.
