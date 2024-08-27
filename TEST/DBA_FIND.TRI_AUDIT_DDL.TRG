CREATE OR REPLACE TRIGGER DBA_FIND.TRI_AUDIT_DDL
    --after ddl on wcdma.schema
    AFTER LOGON
    ON DATABASE
DECLARE
    sql_text    ora_name_list_t;
    i           INTEGER;
    state_sql   VARCHAR2 (4000);
BEGIN
    FOR i IN 1 .. ora_sql_txt (sql_text)
    LOOP
        state_sql := state_sql || sql_text (i);
    END LOOP;

    state_sql := SUBSTRB (state_sql, 1, 4000);

    INSERT INTO AUDIT_DDL (ddl_time,
                                   session_id,
                                   os_user,
                                   ip_address,
                                   terminal,
                                   HOST,
                                   user_name,
                                   ddl_type,
                                   object_type,
                                   owner,
                                   object_name,
                                   sql_text)
         VALUES (TO_CHAR (SYSDATE, 'yyyy-mm-dd hh:mm:ss'),
                 SYS_CONTEXT ('USERENV', 'SESSIONID'),
                 SYS_CONTEXT ('USERENV', 'OS_USER'),
                 SYS_CONTEXT ('USERENV', 'IP_ADDRESS'),
                 SYS_CONTEXT ('USERENV', 'TERMINAL'),
                 SYS_CONTEXT ('USERENV', 'HOST'),
                 ora_login_user,
                 ora_sysevent,
                 ora_dict_obj_type,
                 ora_dict_obj_owner,
                 ora_dict_obj_name,
                 state_sql);
EXCEPTION
    WHEN OTHERS
    THEN
        NULL;
END;
/
