CREATE OR REPLACE PROCEDURE DBA_FIND.PROC_LOCK_TABLE_SQL
AS
BEGIN
    INSERT INTO LOCK_TABLE_SQL
        SELECT SQL_FULLTEXT, SYSDATE SQL_DATE
          FROM (SELECT    'alter system kill session '''
                       || S.SID
                       || ','
                       || S.SERIAL#
                       || ',@'
                       || S.INST_ID
                       || ''';',
                       SQL_FULLTEXT,
                       USERNAME,
                       EVENT,
                       STATUS,
                       SQL_TEXT,
                       ROW_NUMBER ()
                           OVER (
                               PARTITION BY    'alter system kill session '''
                                            || S.SID
                                            || ','
                                            || S.SERIAL#
                                            || ',@'
                                            || S.INST_ID
                                            || ''';'
                               ORDER BY 1)
                           RN
                  FROM GV$SESSION  S
                       LEFT JOIN GV$SQL Q
                           ON NVL (S.SQL_ID, S.PREV_SQL_ID) = Q.SQL_ID)
         WHERE     USERNAME <> UPPER ('SYS')
               AND STATUS = UPPER ('ACTIVE')
               AND EVENT = 'enq: TX - row lock contention'
               AND RN = 1;

    COMMIT;
END;
/
