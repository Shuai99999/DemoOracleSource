CREATE OR REPLACE PROCEDURE DBA_FIND.kill_long_session
AS
    S   VARCHAR2 (1000);
BEGIN
    FOR CUR
        IN (  SELECT SID,
                     SERIAL#,
                     INST_ID,
                     SQL_ID
               FROM (SELECT    'alter system kill session '''
                            || S.SID
                            || ','
                            || S.SERIAL#
                            || ',@'
                            || S.INST_ID
                            || ''';',
                            S.INST_ID,
                            S.USERNAME,
                            SID,
                            SERIAL#,
                            STATUS,
                            MACHINE,
                            PROGRAM,
                            LAST_CALL_ET,
                            PREV_SQL_ID,
                            S.SQL_ID,
                            EVENT,
                            P1,
                            P2,
                            BLOCKING_INSTANCE,
                            BLOCKING_SESSION,
                            FINAL_BLOCKING_SESSION_STATUS,
                            FINAL_BLOCKING_INSTANCE,
                            FINAL_BLOCKING_SESSION,
                            SQL_FULLTEXT,
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
                       FROM GV$SESSION S
                            LEFT JOIN GV$SQL Q
                                ON NVL (S.SQL_ID, S.PREV_SQL_ID) = Q.SQL_ID)
              WHERE     USERNAME <> UPPER ('SYS')
                    AND STATUS = UPPER ('ACTIVE')
                    AND LAST_CALL_ET > 1000
                    AND MACHINE <> 'archdb'
                    AND RN = 1
--                    AND LOWER (SQL_TEXT) LIKE 'select%'
           ORDER BY LAST_CALL_ET DESC)
    LOOP
        INSERT INTO KILL_SESSION_SQL (SQL_ID, KILL_TYPE)
             VALUES ('' || CUR.SQL_ID || '', 'LONG');

        COMMIT;
        S :=
               'ALTER SYSTEM KILL SESSION '''
            || CUR.SID
            || ','
            || CUR.SERIAL#
            || ',@'
            || CUR.INST_ID
            || '''';

        EXECUTE IMMEDIATE S;
    END LOOP;
END;
/
