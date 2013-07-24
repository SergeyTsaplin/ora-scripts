/**
 * vim:filetype=plsql
 * Script trying to enable/disable each foreign key of tables specified in
 * table_list.
 * To use just specify table_list variable, action variable (c_action_enable
 * or c_action_disable) and run this script in SQL*Plus or any other Oralce
 * client or IDE
 */
set serveroutput on size 1000000
declare
    type t_table_list is table of varchar2(128);
    c_action_enable   constant varchar2(7)  := 'ENABLE';
    c_action_disable  constant varchar2(7)  := 'DISABLE';

    -- main variables
    table_list  t_table_list  := t_table_list('SOME_TABLE_NAME',
                                              'ANOTHER_TABLE_NAME');
    action      varchar2(7)   := c_action_enable;

    -- service variables
    processed   integer       := 0;
    successed   integer       := 0;
begin
    dbms_output.enable(1000000);
    if table_list.count = 0 then
        raise_application_error(-20001, 'Tables are not specified.');
    end if;
    if action not in (c_action_enable, c_action_disable) then
        raise_application_error(-20001, 'Invalid action.');
    end if;
    for i in table_list.first..table_list.last
    loop
        for rec in (select
                        *
                    from
                        user_constraints
                    where table_name=upper(table_list(i))
                        and constraint_type='R'
                   )
        loop
            processed := processed + 1;
            begin
                execute immediate 'ALTER TABLE '||rec.table_name
                    ||' '||action||' CONSTRAINT '||rec.constraint_name;
                dbms_output.put_line(rec.table_name||'.'||rec.constraint_name
                    ||': OK');
                  successed := successed + 1;
            exception
                when others then
                    dbms_output.put_line(sqlerrm(sqlcode)||' Table: '
                        ||rec.table_name||'; Constraint: '
                        ||rec.constraint_name);
            end;
        end loop;
    end loop;
    dbms_output.put_line('==================================================');
    dbms_output.put_line('Processed:    '||processed);
    dbms_output.put_line('Successfully: '||successed);
    dbms_output.put_line('Failed:       '||to_char(processed - successed));
end;
/
