CREATE OR REPLACE PROCEDURE DBA_FIND.ARCH_DATA_1 (V_TABLE_NAME   IN VARCHAR2,
                                              V_THREAD_NUM   IN NUMBER)
AS
    V_SQL                VARCHAR2 (2000);
    V_ORA_ERR            VARCHAR2 (2000);
    V_TABLE_LENGTH       NUMBER;
    V_TABLE_SHORT_NAME   VARCHAR2 (50);
    V_SUB_COUNT          NUMBER;
    V_PK                 VARCHAR2 (50);
    V_PK_TYPE            VARCHAR2 (100);
    V_TMP_PK_CHAR        VARCHAR2 (100);
    V_TMP_PK_NUM         NUMBER;

    TYPE VAR_CUR_TYPE IS REF CURSOR;

    VAR_CUR              VAR_CUR_TYPE;
    V_PROCESS_NUM        NUMBER;
BEGIN
    IF V_TABLE_NAME IN ('SYS_LOG_11', 'STG_VOM_NOTICE_11')
    THEN
        V_PK := 'ROW_ID';
    ELSIF V_TABLE_NAME IN ('STG_WLB_NOTICE')
    THEN
        V_PK := 'NOTIFY_ID';
    ELSE
        V_SQL :=
               'SELECT COLUMN_NAME FROM USER_CONS_COLUMNS WHERE CONSTRAINT_NAME=(SELECT CONSTRAINT_NAME FROM USER_CONSTRAINTS WHERE TABLE_NAME='''
            || V_TABLE_NAME
            || ''' AND CONSTRAINT_TYPE=''P'')';

        EXECUTE IMMEDIATE V_SQL
            INTO V_PK;
    END IF;

    V_SQL := 'SELECT LENGTH(''' || V_TABLE_NAME || ''') FROM DUAL';

    EXECUTE IMMEDIATE V_SQL
        INTO V_TABLE_LENGTH;

    IF V_TABLE_LENGTH > 15
    THEN
        V_TABLE_SHORT_NAME :=
               'DEL_'
            || SUBSTR (V_TABLE_NAME, 0, 7)
            || SUBSTR (V_TABLE_NAME, -8);
    ELSE
        V_TABLE_SHORT_NAME := 'DEL_' || V_TABLE_NAME;
    END IF;

    V_SQL :=
           'SELECT DATA_TYPE FROM USER_TAB_COLUMNS WHERE TABLE_NAME='''
        || V_TABLE_NAME
        || ''' AND COLUMN_NAME='''
        || V_PK
        || '''';

    EXECUTE IMMEDIATE V_SQL
        INTO V_PK_TYPE;

    V_SQL :=
           'SELECT COUNT(*) FROM '
        || V_TABLE_SHORT_NAME
        || ' WHERE THREAD_NUM='
        || V_THREAD_NUM
        || '';

    EXECUTE IMMEDIATE V_SQL
        INTO V_SUB_COUNT;

    IF VAR_CUR%ISOPEN
    THEN
        CLOSE VAR_CUR;
    END IF;

    V_SQL :=
           'SELECT '
        || V_PK
        || ' FROM '
        || V_TABLE_SHORT_NAME
        || ' WHERE THREAD_NUM='
        || V_THREAD_NUM
        || '';

    OPEN VAR_CUR FOR V_SQL;

    INSERT INTO PROC_ERROR (OP_TYPE,
                            TABLE_NAME,
                            ERROR_MESSAGE,
                            SQL_TEXT)
         VALUES ('ARCH_DATA_START',
                 '' || V_TABLE_NAME || '',
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
                    || V_TABLE_NAME
                    || '@ARCH_DB 
            SELECT * FROM '
                    || V_TABLE_NAME
                    || '
              WHERE '
                    || V_PK
                    || '=:V_PK_DATA';

                EXECUTE IMMEDIATE V_SQL
                    USING V_TMP_PK_CHAR;

                V_SQL :=
                       'DELETE FROM '
                    || V_TABLE_NAME
                    || '
              WHERE '
                    || V_PK
                    || '=:V_PK_DATA';

                EXECUTE IMMEDIATE V_SQL
                    USING V_TMP_PK_CHAR;

                IF MOD (VAR_CUR%ROWCOUNT, 10000) = 0
                THEN
                    V_PROCESS_NUM := VAR_CUR%ROWCOUNT;

                    INSERT INTO PROC_ERROR (OP_TYPE,
                                            TABLE_NAME,
                                            ERROR_MESSAGE,
                                            SQL_TEXT)
                             VALUES (
                                           'ARCH_DATA_PROCESSING: '
                                        || V_PROCESS_NUM
                                        || '/'
                                        || V_SUB_COUNT
                                        || '',
                                        '' || V_TABLE_NAME || '',
                                        '',
                                        '');

                    COMMIT;
                END IF;
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX
                THEN
                    BEGIN
                        V_SQL :=
                               'DELETE FROM '
                            || V_TABLE_NAME
                            || '@ARCH_DB 
              WHERE '
                            || V_PK
                            || '=:V_PK_DATA';

                        EXECUTE IMMEDIATE V_SQL
                            USING V_TMP_PK_CHAR;

                        V_SQL :=
                               'INSERT INTO '
                            || V_TABLE_NAME
                            || '@ARCH_DB 
            SELECT * FROM '
                            || V_TABLE_NAME
                            || '
              WHERE '
                            || V_PK
                            || '=:V_PK_DATA';

                        EXECUTE IMMEDIATE V_SQL
                            USING V_TMP_PK_CHAR;

                        V_SQL :=
                               'DELETE FROM '
                            || V_TABLE_NAME
                            || '
              WHERE '
                            || V_PK
                            || '=:V_PK_DATA';

                        EXECUTE IMMEDIATE V_SQL
                            USING V_TMP_PK_CHAR;

                        COMMIT;

                        IF MOD (VAR_CUR%ROWCOUNT, 10000) = 0
                        THEN
                            V_PROCESS_NUM := VAR_CUR%ROWCOUNT;

                            INSERT INTO PROC_ERROR (OP_TYPE,
                                                    TABLE_NAME,
                                                    ERROR_MESSAGE,
                                                    SQL_TEXT)
                                     VALUES (
                                                   'ARCH_DATA_PROCESSING: '
                                                || V_PROCESS_NUM
                                                || '/'
                                                || V_SUB_COUNT
                                                || '',
                                                '' || V_TABLE_NAME || '',
                                                '',
                                                '');

                            COMMIT;
                        END IF;
                    END;
                WHEN OTHERS
                THEN
                    BEGIN
                        ROLLBACK;

                        V_ORA_ERR := SQLERRM;

                        INSERT INTO PROC_ERROR (OP_TYPE,
                                                TABLE_NAME,
                                                ERROR_MESSAGE,
                                                SQL_TEXT)
                             VALUES ('ARCH_DATA_PROCESSING ',
                                     '' || V_TABLE_NAME || '',
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
                    || V_TABLE_NAME
                    || '@ARCH_DB 
            SELECT * FROM '
                    || V_TABLE_NAME
                    || '
              WHERE '
                    || V_PK
                    || '=:V_PK_DATA';

                EXECUTE IMMEDIATE V_SQL
                    USING V_TMP_PK_NUM;

                V_SQL :=
                       'DELETE FROM '
                    || V_TABLE_NAME
                    || '
              WHERE '
                    || V_PK
                    || '=:V_PK_DATA';

                EXECUTE IMMEDIATE V_SQL
                    USING V_TMP_PK_NUM;

                IF MOD (VAR_CUR%ROWCOUNT, 10000) = 0
                THEN
                    V_PROCESS_NUM := VAR_CUR%ROWCOUNT;

                    INSERT INTO PROC_ERROR (OP_TYPE,
                                            TABLE_NAME,
                                            ERROR_MESSAGE,
                                            SQL_TEXT)
                             VALUES (
                                           'ARCH_DATA_PROCESSING: '
                                        || V_PROCESS_NUM
                                        || '/'
                                        || V_SUB_COUNT
                                        || '',
                                        '' || V_TABLE_NAME || '',
                                        '',
                                        '');

                    COMMIT;
                END IF;
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX
                THEN
                    BEGIN
                        V_SQL :=
                               'DELETE FROM '
                            || V_TABLE_NAME
                            || '@ARCH_DB 
              WHERE '
                            || V_PK
                            || '=:V_PK_DATA';

                        EXECUTE IMMEDIATE V_SQL
                            USING V_TMP_PK_NUM;

                        V_SQL :=
                               'INSERT INTO '
                            || V_TABLE_NAME
                            || '@ARCH_DB 
            SELECT * FROM '
                            || V_TABLE_NAME
                            || '
              WHERE '
                            || V_PK
                            || '=:V_PK_DATA';

                        EXECUTE IMMEDIATE V_SQL
                            USING V_TMP_PK_NUM;

                        V_SQL :=
                               'DELETE FROM '
                            || V_TABLE_NAME
                            || '
              WHERE '
                            || V_PK
                            || '=:V_PK_DATA';

                        EXECUTE IMMEDIATE V_SQL
                            USING V_TMP_PK_NUM;

                        IF MOD (VAR_CUR%ROWCOUNT, 10000) = 0
                        THEN
                            V_PROCESS_NUM := VAR_CUR%ROWCOUNT;

                            INSERT INTO PROC_ERROR (OP_TYPE,
                                                    TABLE_NAME,
                                                    ERROR_MESSAGE,
                                                    SQL_TEXT)
                                     VALUES (
                                                   'ARCH_DATA_PROCESSING: '
                                                || V_PROCESS_NUM
                                                || '/'
                                                || V_SUB_COUNT
                                                || '',
                                                '' || V_TABLE_NAME || '',
                                                '',
                                                '');

                            COMMIT;
                        END IF;

                        COMMIT;
                    END;
                WHEN OTHERS
                THEN
                    BEGIN
                        ROLLBACK;

                        V_ORA_ERR := SQLERRM;

                        INSERT INTO PROC_ERROR (OP_TYPE,
                                                TABLE_NAME,
                                                ERROR_MESSAGE,
                                                SQL_TEXT)
                             VALUES ('ARCH_DATA_PROCESSING ',
                                     '' || V_TABLE_NAME || '',
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
         VALUES ('ARCH_DATA_END' || V_PROCESS_NUM,
                 '' || V_TABLE_NAME || '',
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
                 VALUES ('ARCH_DATA_PROCESSING ',
                         '' || V_TABLE_NAME || '',
                         V_ORA_ERR,
                         V_SQL);

            COMMIT;
        END;
END;
/
