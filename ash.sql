-- ash.sql print info on latest active session for the current instance from ash
-- Luca Canali March 2012, latest change April 2014

col sample_id for 999999999
col sid_ser# for a10
col username for a26
col sql_id for a13
col exec_plan_ln#_obj# for a45
col dT for 9999
col event for a30
col "DB%,CPU%" for a7
col "R,W_IOPS" for a7
col "R,W_MBPS" for a7
col "PGA,TEMP_MB" for a9

set verify off

column  sample_id new_value target_sample_id
select sample_id, sample_time from v$active_session_history where rownum=1;

select sample_id,session_id||' '||session_serial# sid_ser#,
       (select us.username from dba_users us where us.user_id=a.user_id)||
       case when regexp_substr(program,' \(...') <> ' (TNS' then regexp_substr(program,' \(.+') end username,
       sql_id, round((sysdate-sql_exec_start)*24*3600,1) dT,
       sql_opname||'-'||sql_plan_operation||'-'||sql_plan_options||','||sql_plan_line_id||','||nullif(current_obj#,-1) exec_plan_ln#_obj#,
       decode(session_state,'WAITING',event,'CPU') event,
       --blocking_session, wait_time,time_waited
       round(100*TM_DELTA_DB_TIME/TM_DELTA_TIME,0)||', '||round(100*TM_DELTA_CPU_TIME/TM_DELTA_TIME,0) "DB%,CPU%",
       round (1000000*delta_read_io_requests/delta_time,0)||', '||round(1000000*delta_write_io_requests/delta_time,0) "R,W_IOPS",
       round(delta_read_io_bytes/delta_time,1)||', '||round(delta_write_io_bytes/delta_time,1) "R,W_MBPS",
       round(pga_allocated/1000000,1)||', '||round(temp_space_allocated/1000000,1) "PGA,TEMP_MB"
--from v$active_session_history a where sample_id=&target_sample_id; this seems more  straightforward but perfoms worst than the code here below
from (select * from v$active_session_history where rownum<500) a
where sample_id=&target_sample_id;

#DT : SECOND秒

-- SAMPLE_ID SID_SER#   USERNAME                   SQL_ID           DT EXEC_PLAN_LN#_OBJ#                            EVENT                          DB%,CPU R,W_IOP R,W_MBP PGA,TEMP_
-------- ---------- -------------------------- ------------- ----- --------------------------------------------- ------------------------------ ------- ------- ------- ---------
  -- 33703289 880 1675   ADMIN                      6tsadnbw74zm2     3 SELECT-INDEX-RANGE SCAN,4,236857              CPU                            1, 1    0, 0    0, 0    4.1, 5.2
  -- 33703289 2848 43385 EEP                        3x3st5wfj2saz  3568 SELECT-INDEX-RANGE SCAN,11,168570             gc cr grant 2-way              100, 23 1789, 0 14.7, 0 1143.1, 2
                                                                                                                                                                          -- 12.9

  -- 33703289 3163 32005 ADMIN                      bt42hw14dxu0a     5 SELECT-TABLE ACCESS-BY LOCAL INDEX ROWID,26,8 CPU                            100, 10 0, 0    0, 0    4.5, 0
                                                                     -- 4483                                                                         0

  -- 33703289 6961 28635 ADMIN                      9bws3c5ya0gjf     3 SELECT-TABLE ACCESS-BY LOCAL INDEX ROWID,15,  CPU                            7, 7    0, 0    0, 0    4.9, 5.2
