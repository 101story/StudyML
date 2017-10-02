
============================================
 5장 ASM Instance 관리
============================================

ASM Instance
메모리, 프로세스

데이터베이스 인스턴스에서 LGWR 프로세스는 SGA의 로그 버퍼 섹션에서 디스크의 온라인리두로그 변경 벡터를 복사한다. AMS 인스턴스는 해당 SGA에 로그버퍼를 포함하거나 온라인 리두로그 를 사용하지 않습니다. ASM 인스턴스의 LGWR 프로세스는 로깅 정보를 ASM 디스크 그룹에 복사합니다.


* ASM 프로세스
  RBAL : 각 프로세스를 관리
  ARBn : 실제 엑티비티를 수행
  GMON : 디스크레벨 활동을 수행
  MARK : 문제가 발생한 부분을 마킹함
  Onnn : asm 에 메시지를 주고 받는 역할을함
  PZ9n : 노드간에 소통을 할 수 있도록 함 디비하나에 여러 인스턴스 일경우 GV$ 여러개의 인스턴스의 내용을 한꺼번에 볼수 있음

* ASM 인스턴스 모양을 조정하는 파라메터
  -- 인스턴스 타입은 생략하면 오류
  INSTANCE_TYPE = ASM
  ASM_POWER_LIMIT = 1
  -- 해당 하는 부분만 사용하는 디스크로 여김
  ASM_DISKSTRING = '/dev/sda1','/dev/sdb*'
  -- 두개의 디스크 그룹
  ASM_DISKGROUPS = DATA2, FRA
  -- 그룹에 들어가는 그룹
  -- 지역적으로 먼 데이터센터의 디스크를 하나로 묶어서 사용할때 선호하는 그룹을 우선적으로 지정함
  ASM_PREFERRED_READ_FAILURE_GROUPS = DATA.FailGroup2
  -- 진단파일이 남는 경로를 남김
  DIAGNOSTIC_DEST = /u01/app/oracle
  -- extent map 을 보관해야 함으로 용량을 충분히 줌
  LARGE_POOL_SIZE = 12M
  -- DB 인증이 안되고 data dictionary 가 없다 v$ 는 있음
  REMOTE_LOGIN_PASSWORDFILE = EXCLUSIVE

예) JPG 확인 (Database Instance and ASM)
  여러 DB Instance 가 사용하는 ASM Instance 가 이용하는 Disk 그룹
  - - - - -
  Disk Group DG1
  수원
    Failcure Group a
      [disk1]
      [disk2]
  구미
    Failcure Group b
      [disk1]
      [disk2]
  - - - - -

* ASM System 권한
  SYSASM > SYSDBA > SYSOPER

* 간이 망 관리 프로토콜(Simple Network Management Protocol, SNMP)은 IP 네트워크상의 장치로부터 정보를 수집 및 관리하며, 또한 정보를 수정하여 장치의 동작을 변경하는 데에 사용되는 인터넷 표준 프로토콜이다.
사용하여 ASM 끼리의 통신을함

* AU 단위
  ASM disk 단위
  사이즈가 작을수록 아주 큰 파일이 들어옴

* ASM file
  AU 에 생기는 파일
  ASM extents 의 모음
  spread 되어 있음
  mirroring 가능

* 메모리 할당 단위 (for load balance and striping)
  coarse 뭉뚱뭉뚱
  fine 잘게

* normal redundancy
  알아서 redundancy 를 유지하기 위해
  각 disk1, disk2 에 file1 이 있다면
  망가진 disk1 에 있던 file1 을 다른 disk3 에 알아서 복사해둠
  무조건 2벌씩 유지한다.
  BUT! disk controller 가 망가지면 멈춰버림


* disk_repair_time
  disk 교채 할떄 30분도 디스크로 생각하지 않다가 시간이 지나면 사용하기
  (추가된 기능)


  CREATE DISKGROUP DG1
    NORMAL REDUNDANCY
    FAILGROUP a DISK 'ORCL:ASMDISK09' SIZE 2304 M ,
                     'ORCL:ASMDISK10' SIZE 2304 M
    FAILGROUP b DISK 'ORCL:ASMDISK11' SIZE 2304 M ,
                     'ORCL:ASMDISK12' SIZE 2304 M
    FAILGROUP c DISK 'ORCL:ASMDISK13' SIZE 2304 M ,
                     'ORCL:ASMDISK14' SIZE 2304 M
  ATTRIBUTE 'au_size' = '2M',
            'compatible.rdbms'='11.2',
            'compatible.asm'='11.2',
            'compatible.advm'='11.2';


============================================
 6장 Configuring the Oracle Network Enviroment
============================================
- 리스너 추가 connect time     -> 서버
- local naming 추가           -> 클라이언트
- Shared Server Process       -> 서버, 클라이언트
  <-> Dedicated Server Process

* Oracle Net
  JVM 처럼 OS 달라도 서로 connect 할 수 있도록 함
  DB Server 와 통신을 할려면 클라이언트에도 Oracle Net 이 설치되어 있거나 JDBC 같은 것들이 있어야 한다.
  ORACLE_HOME/Network/admin 이나 tns_admin 의 환경변수가 가리키는 곳에 네트워크 설정파일 (Oracle Net configuration files)이 있어야 한다. (환경변수를 먼저 찾음)
  sqlnet.ora : Oracle Net 제품 자체에 대한 설정 파일 없으면 default 값이 설정됨
  tnsnames.ora
  EM Database Control, Netca, vi 를 사용 하여 편집

* scott/tiger@192.168.179.10:1521/orcl
  scott/tiger@orcl
  > Host Port Protocol NameoftheService
    Listerner 가 돌고 있는 Host
    Listerner 가 열고 있는 Port
    Listerner 가 사용하는 Protocol
    Listerner 에 연결되어 있는 NameoftheService (XE 같은..)

  > orcl
    tnsnames 로컬정보 또는
    LDAP server 도메인서버 센트럴라이즈
    확인하여 도메인 주소를 알아넴


* 서비스등록
  Dynamic
    show parameter listerner
    local_listerner
    remote_listerner

    alter system set local_listerner = river;
    pmon 이 river 가 가리키는 여러개의 주소를 등록
    RAC 환경에서 다른 머신의 리스너에 등록하고 싶으면
    alter system set remote_listerner = hereNthere;

    서버쪽에 파라미터 값을 정해서 pmon 이 알아서 등록하게 하는 방식

  Static
    기존에 리스너 등록했던 방식들


# 6-9 Dynamic service registration과 Static service registration     << 예시일 뿐 실습 예제 아님

  [orcl:~]$ vi $ORACLE_HOME/network/admin/tnsnames.ora

RIVER =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.56.101)(PORT = 1521))
      (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.56.101)(PORT = 1621))
      (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.56.101)(PORT = 1721))
    )
  )

here_and_there =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.56.101)(PORT = 1521))
      (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.56.102)(PORT = 1521))
      (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.56.103)(PORT = 1521))
    )
  )

  [orcl:~]$ sqlplus / as sysdba

  SQL> alter system set local_listener  = river;
  SQL> alter system set remote_listener = here_and_there;
  SQL> startup force



* Shared Server 의 경우
  PGA 사용량은 좀 줄이고
  SGA 사용량은 좀 늘리고
  shared_servers 프로세스가 Server Process 역할과 유사한 하는데
  PGA 가 많이 필요하지 않는다. (그만큼 많은 일을 하지 않는다.)

* Connection Pooling
  기다렸다가 서비스를 받음
  New Client -> Active -> Idle



### Shared Server 기능 사용
- Scalability : 같은 자원으로 늘어나는 User 의 접속을 받아 낼 수 있다.
- Connection pooling 기능을 사용 가능
  shared 서버 여야만 한다.
  데이터베이스 서버가 idle 세션을 만료시키고 연결을 사용하여 활성 세션을 제공
- Connection Multiplexing : connect manager cman
  서버머신 외부에 기계를 놓고 Connection Manager 를 놓고 User 가 cman 에 붙어서 내부의 dispatcher 에 들어옴
  시분할 방식

* 서버측
  dispatchers   : ss 방식으로 들어오는 User 들을 받아서 Request Queue 에 추가해줌 (서빙담당자)
  shared_servers  : ss 방식으로 들어온 User 의 요구사항을 Request Queue 에서 하나씩 꺼내어 작업을 수행하고 Response Queue 에 결과를 넣음 (공동요리사)

  Requset Q : shared 방식 설정시 1개 생성
  Response Q : shared 방식 설정시
* 클라이언트측
  DEDICATED 1:1 방식으로 접속 기존 방식 Server Process
  shared 방식으로 접속시 부화가 덜한곳에서 자동으로 할당되어 서비스르 받을 수 있음

# 실습
 - 서버측 설정
  >> 파라미터 2개만 잡아주면 사용할 수 있음

  [oracle@ora11gr2 ~]$ export ORACLE_SID=prod
  [oracle@ora11gr2 ~]$ sqlplus / as sysdba

  -- dispatchers 를 지원하는 프로세스 3개
  SQL> alter system set dispatchers = '(protocol=tcp)(dispatchers=3)';

  -- shared server 를 지언하는 프로세스 2개
  SQL> alter system set shared_servers = 2;

  SQL> !ps -ef|grep prod

  	oracle   10687     1  0 16:22 ?        00:00:00 ora_d000_prod
  	oracle   10689     1  0 16:22 ?        00:00:00 ora_d001_prod
  	oracle   10691     1  0 16:22 ?        00:00:00 ora_d002_prod

  	oracle   10695     1  0 16:22 ?        00:00:00 ora_s000_prod
  	oracle   10697     1  0 16:22 ?        00:00:00 ora_s001_prod

  -- dnnn dispatchers
  -- snnn shared

  SQL> !lsnrctl service

      "D002" established:0 refused:0 current:0 max:1022 state:ready
         DISPATCHER <machine: ora11gr2.gsedu.com, pid: 10691>
         (ADDRESS=(PROTOCOL=tcp)(HOST=ora11gr2.gsedu.com)(PORT=45849))
      "D001" established:0 refused:0 current:0 max:1022 state:ready
         DISPATCHER <machine: ora11gr2.gsedu.com, pid: 10689>
         (ADDRESS=(PROTOCOL=tcp)(HOST=ora11gr2.gsedu.com)(PORT=45848))
      "D000" established:1 refused:0 current:1 max:1022 state:ready
         DISPATCHER <machine: ora11gr2.gsedu.com, pid: 10687>
         (ADDRESS=(PROTOCOL=tcp)(HOST=ora11gr2.gsedu.com)(PORT=45847))
        -- 나는 지금까지 몇명을 받았고 거절했고 지금은 몇명이다. 주소는 뭐고 ..

 - 클라이언트측 설정
  >> 클라이언트가 ss 로 붙으면 떠있는 프로세스중에 가장 부화가 없는 곳에 붙여줌

  C:\Documents and Settings\Administrator> set path=E:\ora\instantclient-11.1;%path%
  C:\Documents and Settings\Administrator> set tns_admin=E:\ora\instantclient-11.1
  C:\Documents and Settings\Administrator> notepad E:\ora\instantclient-11.1\tnsnames.ora

dd =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.0.10)(PORT = 1521))
    -- (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.0.11)(PORT = 1452))
    -- 주소가 2개면 리스너가 두개
    -- SOURCE_ROUTE=yes 가 있다면 cman 을 거쳐서 리스너로 가라
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SID = prod)
    )
  )

ss =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = 192.168.0.10)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = shared)
      (SID = prod)
    )
  )

  C:\Documents and Settings\Administrator> sqlplus system/oracle@dd
  SQL> select username, server from v$session;
  SQL> exit

  C:\Documents and Settings\Administrator> sqlplus system/oracle@ss
  SQL> select username, server from v$session;
  SQL> exit



# Connection Pooling

  * Session vs Connection

    http://me2.do/xniiAscG


# Source routing

  --> http://blog.naver.com/barcoder/60071872027

  1.cman.ora를 이용해서 Connection Manager를 설정
  2.tnsnames.ora를 적절히 설정

  C:\Users\student> sqlplus u/p@abc    << 예시일 뿐 실습 예제 아님

  abc =
    (DESCRIPTION =
      (ADDRESS_LIST =
        (ADDRESS = (PROTOCOL = TCP)(HOST =121.190.154.108)(PORT = 1610))  # cman.ora 에서 설정한 부분
        (ADDRESS = (PROTOCOL = TCP)(HOST =192.168.11.168)(PORT = 1521))   # connection manager에게 이주소로 접속하겠다는 걸
        (SOURCE_ROUTE=yes)
      )
      (CONNECT_DATA =
        (SERVER = DEDICATED)
        (SERVICE_NAME = CM)
      )
    )



## 실습
- 다른 머신의 리스너로 다른 머신의 db 인스턴스 접속하기


# 6-35 : Database Link 활용

  0.putty를 이용해서 192.168.56.101로 접속하세요.

  1.다음 과정을 그대로 따라하세요.

  [orcl:~]$ . oraenv
  ORACLE_SID = [orcl] ? prod

  [prod:~]$ sqlplus dream30/catcher@70.12.50.50:1521/XE
  SQL> exit

  [prod:~]$ vi $ORACLE_HOME/network/admin/tnsnames.ora

    samsung =
      (DESCRIPTION =
        (ADDRESS_LIST =
          (ADDRESS = (PROTOCOL = TCP)(HOST = 70.12.50.50)(PORT = 1521))
        )
        (CONNECT_DATA =
          (SERVICE_NAME = XE)
        )
      )
  -- oracle net 과 connect 확인
  [prod:~]$ tnsping samsung

  [prod:~]$ sqlplus dream30/catcher@samsung

  SQL> exit

  [prod:~]$ sqlplus / as sysdba

  SQL> drop user orange cascade;

  SQL> create user orange
       identified by orange;

  SQL> grant create session,
             create database link,
             create synonym
       to orange;

  SQL> conn orange/orange

  SQL> create database link remote_xe
       connect to dream30
       identified by catcher
       using 'samsung';

  SQL> show user
  USER is "ORANGE"

  SQL> col db_link format a10
  SQL> col host format a20

  SQL> select db_link, username, host
       from user_db_links;

  SQL> select * from tab;

  SQL> select * from dept@remote_xe;
  SQL> select * from emp@remote_xe;

  SQL> create synonym dept_xe for dept@remote_xe;
  SQL> create synonym emp_xe for emp@remote_xe;

  SQL> select * from dept_xe;
  SQL> select * from emp_xe;

  SQL> select d.deptno, d.loc, e.empno, e.ename, e.job
       from emp_xe e, dept_xe d
       where e.deptno = d.deptno;


/
