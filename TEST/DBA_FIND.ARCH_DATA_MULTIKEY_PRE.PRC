CREATE OR REPLACE PROCEDURE DBA_FIND.ARCH_DATA_MULTIKEY_PRE (
   V_TABLE_NAME   IN VARCHAR2,
   V_CONDITION    IN VARCHAR2)
   AUTHID CURRENT_USER
AS
   V_SQL                VARCHAR2 (2000);
   V_CT                 INT;
   V_ORA_ERR            VARCHAR2 (2000);
   V_TABLE_LENGTH       NUMBER;
   V_TABLE_SHORT_NAME   VARCHAR2 (50);
   V_SUB_PK             VARCHAR2 (50);
   V_PK                 VARCHAR2 (500);

   TYPE ID_CURSOR_TYPE IS REF CURSOR;

   ID_CURSOR            ID_CURSOR_TYPE;
BEGIN
   IF ID_CURSOR%ISOPEN
   THEN
      CLOSE ID_CURSOR;
   END IF;

   V_SQL :=
         'SELECT COLUMN_NAME FROM USER_CONS_COLUMNS WHERE CONSTRAINT_NAME=(SELECT CONSTRAINT_NAME FROM USER_CONSTRAINTS WHERE TABLE_NAME='''
      || V_TABLE_NAME
      || ''' AND CONSTRAINT_TYPE=''P'')';

   OPEN ID_CURSOR FOR V_SQL;

   --   V_MULTI_PK := '';

   LOOP
      BEGIN
         FETCH ID_CURSOR INTO V_SUB_PK;

         EXIT WHEN ID_CURSOR%NOTFOUND;

         V_PK := V_PK || '' || V_SUB_PK || ',';
      END;
   END LOOP;

   V_PK := SUBSTR (V_PK, 0, LENGTH (V_PK) - 1);

   V_SQL := 'SELECT LENGTH(''' || V_TABLE_NAME || ''') FROM DUAL';

   EXECUTE IMMEDIATE V_SQL INTO V_TABLE_LENGTH;

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
         'SELECT COUNT(*) FROM USER_TABLES WHERE TABLE_NAME='''
      || V_TABLE_SHORT_NAME
      || '_SEQ''';

   EXECUTE IMMEDIATE V_SQL INTO V_CT;

   IF V_CT = 1
   THEN
      V_SQL := 'DROP TABLE ' || V_TABLE_SHORT_NAME || '_SEQ';

      EXECUTE IMMEDIATE V_SQL;
   END IF;

   V_SQL :=
         'CREATE TABLE '
      || V_TABLE_SHORT_NAME
      || '_SEQ AS SELECT '
      || V_PK
      || ' FROM '
      || V_TABLE_NAME
      || ' WHERE '
      || V_CONDITION
      || '';

   EXECUTE IMMEDIATE V_SQL;

   V_SQL :=
         'SELECT COUNT(*) FROM USER_TABLES WHERE TABLE_NAME='''
      || V_TABLE_SHORT_NAME
      || '''';

   EXECUTE IMMEDIATE V_SQL INTO V_CT;

   IF V_CT = 1
   THEN
      V_SQL := 'DROP TABLE ' || V_TABLE_SHORT_NAME;

      EXECUTE IMMEDIATE V_SQL;
   END IF;

   V_SQL :=
         'CREATE TABLE '
      || V_TABLE_SHORT_NAME
      || ' AS SELECT TO_NUMBER(SUBSTR(ROWNUM, -1)) THREAD_NUM,'
      || V_PK
      || ' FROM '
      || V_TABLE_SHORT_NAME
      || '_SEQ';

   EXECUTE IMMEDIATE V_SQL;

   V_SQL := 'DROP TABLE ' || V_TABLE_SHORT_NAME || '_SEQ';

   EXECUTE IMMEDIATE V_SQL;

   V_SQL :=
         'ALTER TABLE '
      || V_TABLE_SHORT_NAME
      || ' ADD (PRIMARY KEY ( '
      || V_PK
      || '))';

   EXECUTE IMMEDIATE V_SQL;

   V_SQL :=
         'CREATE BITMAP INDEX BMAP_'
      || V_TABLE_SHORT_NAME
      || ' ON '
      || V_TABLE_SHORT_NAME
      || '(THREAD_NUM)';

   EXECUTE IMMEDIATE V_SQL;
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
              VALUES ('ARCH_DATA_PRE',
                      '' || V_TABLE_NAME || '',
                      V_ORA_ERR,
                      V_SQL);

         COMMIT;
      END;
END;
/
