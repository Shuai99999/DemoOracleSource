CREATE OR REPLACE PROCEDURE DBA_FIND.ARCH_DATA_BYDATE (
    V_TABLE_NAME   IN VARCHAR2,
    V_THREAD_NUM   IN NUMBER)
AS
    V_SQL                VARCHAR2 (2000);
    V_ORA_ERR            VARCHAR2 (2000);
    V_TABLE_LENGTH       NUMBER;
    V_TABLE_SHORT_NAME   VARCHAR2 (50);
    V_SUB_COUNT          NUMBER;
    V_DATE_COL           VARCHAR2 (50);
    V_DATE_TYPE          VARCHAR2 (100);
    V_TMP_DATE           DATE;
    V_TMP_TS             TIMESTAMP;

    TYPE VAR_CUR_TYPE IS REF CURSOR;

    VAR_CUR              VAR_CUR_TYPE;
    V_PROCESS_NUM        NUMBER;
BEGIN

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
               'SELECT COLUMN_NAME FROM USER_TAB_COLUMNS WHERE TABLE_NAME='''
            || V_TABLE_SHORT_NAME
            || ''' AND COLUMN_NAME <> ''THREAD_NUM''';

    EXECUTE IMMEDIATE V_SQL
        INTO V_DATE_COL;

    V_SQL :=
           'SELECT DATA_TYPE FROM USER_TAB_COLUMNS WHERE TABLE_NAME='''
        || V_TABLE_NAME
        || ''' AND COLUMN_NAME='''
        || V_DATE_COL
        || '''';

    EXECUTE IMMEDIATE V_SQL
        INTO V_DATE_TYPE;

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
        || V_DATE_COL
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
         VALUES ('ARCH_DATA_BYDATE_START',
                 '' || V_TABLE_NAME || '',
                 '',
                 '');

    COMMIT;

    IF V_DATE_TYPE LIKE '%DATE%'
    THEN
        LOOP
            BEGIN
                FETCH VAR_CUR INTO V_TMP_DATE;

                EXIT WHEN VAR_CUR%NOTFOUND;

                V_SQL :=
                       'INSERT INTO '
                    || V_TABLE_NAME
                    || '@ARCH_DB 
            SELECT * FROM '
                    || V_TABLE_NAME
                    || '
              WHERE '
                    || V_DATE_COL
                    || '=:V_DATE_COL_DATA';

                EXECUTE IMMEDIATE V_SQL
                    USING V_TMP_DATE;

                V_SQL :=
                       'DELETE FROM '
                    || V_TABLE_NAME
                    || '
              WHERE '
                    || V_DATE_COL
                    || '=:V_DATE_COL_DATA';

                EXECUTE IMMEDIATE V_SQL
                    USING V_TMP_DATE;

                IF MOD (VAR_CUR%ROWCOUNT, 10000) = 0
                THEN
                    V_PROCESS_NUM := VAR_CUR%ROWCOUNT;

                    INSERT INTO PROC_ERROR (OP_TYPE,
                                            TABLE_NAME,
                                            ERROR_MESSAGE,
                                            SQL_TEXT)
                             VALUES (
                                           'ARCH_DATA_BYDATE_PROCESSING: '
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
                            || V_DATE_COL
                            || '=:V_DATE_COL_DATA';

                        EXECUTE IMMEDIATE V_SQL
                            USING V_TMP_DATE;

                        V_SQL :=
                               'INSERT INTO '
                            || V_TABLE_NAME
                            || '@ARCH_DB 
            SELECT * FROM '
                            || V_TABLE_NAME
                            || '
              WHERE '
                            || V_DATE_COL
                            || '=:V_DATE_COL_DATA';

                        EXECUTE IMMEDIATE V_SQL
                            USING V_TMP_DATE;

                        V_SQL :=
                               'DELETE FROM '
                            || V_TABLE_NAME
                            || '
              WHERE '
                            || V_DATE_COL
                            || '=:V_DATE_COL_DATA';

                        EXECUTE IMMEDIATE V_SQL
                            USING V_TMP_DATE;

                        COMMIT;

                        IF MOD (VAR_CUR%ROWCOUNT, 10000) = 0
                        THEN
                            V_PROCESS_NUM := VAR_CUR%ROWCOUNT;

                            INSERT INTO PROC_ERROR (OP_TYPE,
                                                    TABLE_NAME,
                                                    ERROR_MESSAGE,
                                                    SQL_TEXT)
                                     VALUES (
                                                   'ARCH_DATA_BYDATE_PROCESSING: '
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
                WHEN NO_DATA_FOUND
                THEN
                    BEGIN
                        NULL;
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
                             VALUES ('ARCH_DATA_BYDATE_PROCESSING ',
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
                FETCH VAR_CUR INTO V_TMP_TS;

                EXIT WHEN VAR_CUR%NOTFOUND;

                V_SQL :=
                       'INSERT INTO '
                    || V_TABLE_NAME
                    || '@ARCH_DB 
            SELECT * FROM '
                    || V_TABLE_NAME
                    || '
              WHERE '
                    || V_DATE_COL
                    || '=:V_DATE_COL_DATA';

                EXECUTE IMMEDIATE V_SQL
                    USING V_TMP_TS;

                V_SQL :=
                       'DELETE FROM '
                    || V_TABLE_NAME
                    || '
              WHERE '
                    || V_DATE_COL
                    || '=:V_DATE_COL_DATA';

                EXECUTE IMMEDIATE V_SQL
                    USING V_TMP_TS;

                IF MOD (VAR_CUR%ROWCOUNT, 10000) = 0
                THEN
                    V_PROCESS_NUM := VAR_CUR%ROWCOUNT;

                    INSERT INTO PROC_ERROR (OP_TYPE,
                                            TABLE_NAME,
                                            ERROR_MESSAGE,
                                            SQL_TEXT)
                             VALUES (
                                           'ARCH_DATA_BYDATE_PROCESSING: '
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
                            || V_DATE_COL
                            || '=:V_DATE_COL_DATA';

                        EXECUTE IMMEDIATE V_SQL
                            USING V_TMP_TS;

                        V_SQL :=
                               'INSERT INTO '
                            || V_TABLE_NAME
                            || '@ARCH_DB 
            SELECT * FROM '
                            || V_TABLE_NAME
                            || '
              WHERE '
                            || V_DATE_COL
                            || '=:V_DATE_COL_DATA';

                        EXECUTE IMMEDIATE V_SQL
                            USING V_TMP_TS;

                        V_SQL :=
                               'DELETE FROM '
                            || V_TABLE_NAME
                            || '
              WHERE '
                            || V_DATE_COL
                            || '=:V_DATE_COL_DATA';

                        EXECUTE IMMEDIATE V_SQL
                            USING V_TMP_TS;

                        IF MOD (VAR_CUR%ROWCOUNT, 10000) = 0
                        THEN
                            V_PROCESS_NUM := VAR_CUR%ROWCOUNT;

                            INSERT INTO PROC_ERROR (OP_TYPE,
                                                    TABLE_NAME,
                                                    ERROR_MESSAGE,
                                                    SQL_TEXT)
                                     VALUES (
                                                   'ARCH_DATA_BYDATE_PROCESSING: '
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
                             VALUES ('ARCH_DATA_BYDATE_PROCESSING ',
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
         VALUES ('ARCH_DATA_BYDATE_END' || V_PROCESS_NUM,
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
                 VALUES ('ARCH_DATA_BYDATE_PROCESSING ',
                         '' || V_TABLE_NAME || '',
                         V_ORA_ERR,
                         V_SQL);

            COMMIT;
        END;
END;
/
