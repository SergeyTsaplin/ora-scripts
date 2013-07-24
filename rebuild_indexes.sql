/**
 * vim:filetype=plsql
 * Script trying to rebuild all indexes on each table from tables_list.
 * To use just specify table_list variable and run this script in SQL*Plus
 * or any other Oralce client or IDE
 */
set serveroutput on size 1000000
declare
    type t_table_list is table of varchar2(128);

    table_list t_table_list := t_table_list('SOME_TABLE_NAME',
                                             'ANOTHER_TABLE_NAME');

    -- service variables
    cmd varchar2(1024) := null;
begin
  dbms_output.enable(1000000);
  if table_list.count = 0 then
    raise_application_error(-20001, 'Table list not specified.');
  end if;
  for i in table_list.first..table_list.last
  loop
    dbms_application_info.set_module(module_name=>'Rebuilding '
      ||table_list(i)||'indexes', action_name=>null);
    dbms_output.put_line('Rebuilding indexes for '||table_list(i));

    for rec in (select index_name
                from user_indexes
                where table_name = upper(table_list(i)))
    loop
      dbms_application_info.set_action(action_name => 'Trying to rebuild '
        ||rec.index_name);
      dbms_output.put_line('  Trying to rebuild '||rec.index_name);
      cmd := 'ALTER INDEX '||rec.index_name||' REBUILD';
      dbms_output.put_line('    '||cmd);

      begin
        execute immediate cmd;
        dbms_output.put_line('    Success!!!');
      exception
        when others then
          begin
            dbms_application_info.set_action(
              action_name=>'Trying to online rebuild '||rec.index_name);

            dbms_output.put_line('     Trying to rebuild online');
            dbms_output.put_line('     '||cmd||' ONLINE');
            execute immediate cmd||' ONLINE';
            dbms_output.put_line('     Success!!!');
          exception
            when others then
              dbms_output.put_line('    Error: '||sqlerrm(sqlcode));
          end;
      end;
    end loop;
  end loop;
end;
/
