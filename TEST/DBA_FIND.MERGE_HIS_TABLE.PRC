CREATE OR REPLACE PROCEDURE DBA_FIND.MERGE_HIS_TABLE (
    OWNER         IN VARCHAR2,
    FROM_TB       IN VARCHAR2,
    TO_TB         IN VARCHAR2,
    STEP          IN NUMBER,
    DBLINK_NAME   IN VARCHAR2)
    AUTHID CURRENT_USER
AS
    V_SQL           VARCHAR2 (2000);
    V_ORA_ERR       VARCHAR2 (2000);
    V_SUM_COUNT     NUMBER;
    V_PK            VARCHAR2 (50);
    V_PK_TYPE       VARCHAR2 (100);
    V_TMP_PK_CHAR   VARCHAR2 (100);
    V_TMP_PK_NUM    NUMBER;

    TYPE VAR_CUR_TYPE IS REF CURSOR;

    VAR_CUR         VAR_CUR_TYPE;
    V_PROCESS_NUM   NUMBER;
BEGIN
    IF TO_TB = 'MD_LOG'
    THEN
        V_PK := 'ROW_ID';
    ELSE
        V_SQL :=
               'SELECT COLUMN_NAME FROM DBA_CONS_COLUMNS WHERE CONSTRAINT_NAME=(SELECT CONSTRAINT_NAME FROM DBA_CONSTRAINTS WHERE OWNER= '''
            || OWNER
            || ''' AND TABLE_NAME='''
            || TO_TB
            || ''' AND CONSTRAINT_TYPE=''P'') AND POSITION = 1';

        EXECUTE IMMEDIATE V_SQL
            INTO V_PK;
    END IF;

    V_SQL :=
           'SELECT DATA_TYPE FROM DBA_TAB_COLUMNS WHERE OWNER= '''
        || OWNER
        || ''' AND TABLE_NAME='''
        || TO_TB
        || ''' AND COLUMN_NAME='''
        || V_PK
        || '''';

    EXECUTE IMMEDIATE V_SQL
        INTO V_PK_TYPE;

    V_SQL :=
           'SELECT COUNT(*) FROM '
        || OWNER
        || '.'
        || FROM_TB
        || '@'
        || DBLINK_NAME
        || '';

    EXECUTE IMMEDIATE V_SQL
        INTO V_SUM_COUNT;

    IF VAR_CUR%ISOPEN
    THEN
        CLOSE VAR_CUR;
    END IF;

    V_SQL :=
           'SELECT '
        || V_PK
        || ' FROM '
        || OWNER
        || '.'
        || FROM_TB
        || '@'
        || DBLINK_NAME
        || '';

    OPEN VAR_CUR FOR V_SQL;

    INSERT INTO PROC_ERROR (OP_TYPE,
                            TABLE_NAME,
                            ERROR_MESSAGE,
                            SQL_TEXT)
         VALUES ('MERGE_HIS_TABLE_START',
                 '' || OWNER || '.' || FROM_TB || '',
                 '',
                 '');

    COMMIT;

    IF V_PK_TYPE LIKE '%CHAR%'
    THEN
        LOOP
            BEGIN
                FETCH VAR_CUR INTO V_TMP_PK_CHAR;

                EXIT WHEN VAR_CUR%NOTFOUND;

                V_SQL :=
                       'INSERT INTO '
                    || OWNER
                    || '.'
                    || TO_TB
                    || '
            SELECT * FROM '
                    || OWNER
                    || '.'
                    || FROM_TB
                    || '@'
                    || DBLINK_NAME
                    || '
              WHERE '
                    || V_PK
                    || '=:V_PK_DATA';

                EXECUTE IMMEDIATE V_SQL
                    USING V_TMP_PK_CHAR;

                IF MOD (VAR_CUR%ROWCOUNT, STEP) = 0
                THEN
                    V_PROCESS_NUM := VAR_CUR%ROWCOUNT;

                    INSERT INTO PROC_ERROR (OP_TYPE,
                                            TABLE_NAME,
                                            ERROR_MESSAGE,
                                            SQL_TEXT)
                             VALUES (
                                           'MERGE_HIS_TABLE_PROCESSING: '
                                        || V_PROCESS_NUM
                                        || '/'
                                        || V_SUM_COUNT
                                        || '',
                                        '' || OWNER || '.' || FROM_TB || '',
                                        '',
                                        '');

                    COMMIT;
                END IF;
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX
                THEN
                    NULL;
                WHEN OTHERS
                THEN
                    BEGIN
                        ROLLBACK;

                        V_ORA_ERR := SQLERRM;

                        INSERT INTO PROC_ERROR (OP_TYPE,
                                                TABLE_NAME,
                                                ERROR_MESSAGE,
                                                SQL_TEXT)
                             VALUES ('MERGE_HIS_TABLE_PROCESSING ',
                                     '' || OWNER || '.' || FROM_TB || '',
                                     V_ORA_ERR,
                                     V_SQL);

                        COMMIT;
                        CONTINUE;
                    END;
            END;
        END LOOP;
    ELSE
        LOOP
            BEGIN
                FETCH VAR_CUR INTO V_TMP_PK_NUM;

                EXIT WHEN VAR_CUR%NOTFOUND;

                V_SQL :=
                       'INSERT INTO '
                    || OWNER
                    || '.'
                    || TO_TB
                    || '
            SELECT * FROM '
                    || OWNER
                    || '.'
                    || FROM_TB
                    || '@'
                    || DBLINK_NAME
                    || '
              WHERE '
                    || V_PK
                    || '=:V_PK_DATA';

                EXECUTE IMMEDIATE V_SQL
                    USING V_TMP_PK_NUM;

                IF MOD (VAR_CUR%ROWCOUNT, STEP) = 0
                THEN
                    V_PROCESS_NUM := VAR_CUR%ROWCOUNT;

                    INSERT INTO PROC_ERROR (OP_TYPE,
                                            TABLE_NAME,
                                            ERROR_MESSAGE,
                                            SQL_TEXT)
                             VALUES (
                                           'MERGE_HIS_TABLE_PROCESSING: '
                                        || V_PROCESS_NUM
                                        || '/'
                                        || V_SUM_COUNT
                                        || '',
                                        '' || OWNER || '.' || FROM_TB || '',
                                        '',
                                        '');

                    COMMIT;
                END IF;
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX
                THEN
                    NULL;
                WHEN OTHERS
                THEN
                    BEGIN
                        ROLLBACK;

                        V_ORA_ERR := SQLERRM;

                        INSERT INTO PROC_ERROR (OP_TYPE,
                                                TABLE_NAME,
                                                ERROR_MESSAGE,
                                                SQL_TEXT)
                             VALUES ('MERGE_HIS_TABLE_PROCESSING ',
                                     '' || OWNER || '.' || FROM_TB || '',
                                     V_ORA_ERR,
                                     V_SQL);

                        COMMIT;
                        CONTINUE;
                    END;
            END;
        END LOOP;
    END IF;

    COMMIT;

    V_PROCESS_NUM := VAR_CUR%ROWCOUNT;

    INSERT INTO PROC_ERROR (OP_TYPE,
                            TABLE_NAME,
                            ERROR_MESSAGE,
                            SQL_TEXT)
         VALUES ('MERGE_HIS_TABLE_END' || V_PROCESS_NUM,
                 '' || OWNER || '.' || FROM_TB || '',
                 '',
                 '');

    COMMIT;
EXCEPTION
    WHEN OTHERS
    THEN
        BEGIN
            ROLLBACK;

            V_ORA_ERR := SQLERRM;

            INSERT INTO PROC_ERROR (OP_TYPE,
                                    TABLE_NAME,
                                    ERROR_MESSAGE,
                                    SQL_TEXT)
                 VALUES ('MERGE_HIS_TABLE_PROCESSING ',
                         '' || OWNER || '.' || FROM_TB || '',
                         V_ORA_ERR,
                         V_SQL);

            COMMIT;
        END;
END;
/
