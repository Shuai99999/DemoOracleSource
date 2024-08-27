CREATE OR REPLACE TRIGGER DBA_FIND.TRI_AUDIT_LOGON
   AFTER LOGON
   ON DATABASE
DISABLE
BEGIN
   
   IF ora_login_user NOT IN ('SYS', 'SYSMAN', 'BMC', 'DBA_FIND', 'DBSNMP') 
      OR SYS_CONTEXT ('USERENV', 'IP_ADDRESS') NOT IN ('10.135.30.96')
   THEN
      INSERT INTO audit_logon (LOGON_TIME,
                               session_id,
                               os_user,
                               ip_address,
                               terminal,
                               HOST,
                               user_name)
           VALUES (SYSDATE,
                   SYS_CONTEXT ('USERENV', 'SESSIONID'),
                   SYS_CONTEXT ('USERENV', 'OS_USER'),
                   SYS_CONTEXT ('USERENV', 'IP_ADDRESS'),
                   SYS_CONTEXT ('USERENV', 'TERMINAL'),
                   SYS_CONTEXT ('USERENV', 'HOST'),
                   ora_login_user);
      COMMIT;
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      NULL;
END;
/
