/**
 * vim:filetype=plsql
 * Script (re)create ddl instruction to recreate all sequence for given database
 * user and roll these sequence on offset value
 */
set serveroutput on size 1000000
declare
    owner           varchar2(128)   := 'SYS';
    offset          integer         := 1000;

    -- service variables
    ddl_string      varchar2(32000) := null;
    current_sq_ddl  varchar2(512)   := null;
    full_name       varchar2(512)   := null;
begin
    dbms_output.enable(1000000);
    for rec in (select *
                from all_sequences
                where sequence_owner = owner)
    loop
        full_name := rec.sequence_owner||'.'||rec.sequence_name;
        current_sq_ddl := 'DROP SEQUENCE '||full_name||';'||chr(10)||chr(10);
        current_sq_ddl := current_sq_ddl||'CREATE SEQUENCE '||full_name
            ||' START WITH '||to_char(rec.last_number + offset)||' INCREMENT BY '
            ||rec.increment_by||' MAXVALUE '||rec.max_value ||' MINVALUE '
            ||rec.min_value;
        if rec.cycle_flag = 'Y' then
            current_sq_ddl := current_sq_ddl||' CYCLE';
        else
            current_sq_ddl := current_sq_ddl||' NOCYCLE';
        end if;
        if rec.cache_size = 0 then
            current_sq_ddl := current_sq_ddl||' NOCACHE';
        else
            current_sq_ddl := current_sq_ddl||' CACHE '||rec.cache_size;
        end if;
        if rec.order_flag = 'Y' then
            current_sq_ddl := current_sq_ddl||' ORDER';
        else
            current_sq_ddl := current_sq_ddl||' NOORDER';
        end if;
        current_sq_ddl := current_sq_ddl||';'||chr(10)||chr(10);
        ddl_string := ddl_string||current_sq_ddl;
    end loop;
    dbms_output.put_line(ddl_string);
end;
/
