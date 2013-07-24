 /**
  * vim:filetype=plsql
  * Script generates merge command for tables from tables_for_sync.
  * It's usefull for synchronization with remote databse with the same schema.
  * If you want only generate merge command, set generate_only = True.
  * If you want to execute it command automaticaly set generate_only = False.
  * The db_link_name specified remote databace-receiver.
  */
declare
    type t_table_list is table of varchar2(128);

    tables_for_sync t_table_list := t_table_list('SOME_TABLE_NAME',
                                                 'ANOTHER_TABLE_NAME');
    db_link_name    varchar2(128)   := 'DB_LINK';
    eol_char        varchar2(1)     := chr(10);
    generate_only   boolean         := true;

    -- service variables
    query_str       varchar2(32000) := null;
    current_table   varchar2(128)   := null;
    current_pk      varchar2(128)   := null;
    field_list      t_table_list;

    /**
     * Function returns Primary Key Column for table
     */
    function get_pk_column(p_table_name in varchar2,
                           p_owner      in varchar2 := null)
                           return varchar2 as
        pk_column varchar2(128) := null;
    begin
        select distinct cols.column_name
        into pk_column
        from all_constraints cons,
             all_cons_columns cols
        where cols.table_name = upper(p_table_name)
              and cons.constraint_type = 'P'
              and cons.constraint_name = cols.constraint_name
              and cons.owner = cols.owner;

        return pk_column;
    end;

    /**
     * Function returns list of table columns except Primary Key column
     */
    function get_table_columns(p_table_name in varchar2,
                               p_owner      in varchar2 := null)
                               return t_table_list as
        l_field_list t_table_list;
        pk_column varchar2(128) := get_pk_column(p_table_name, p_owner);
    begin
        select column_name
        bulk collect into l_field_list
        from all_tab_cols
        where table_name = upper(p_table_name)
              and (owner = upper(p_owner)
                  or p_owner is null)
              and column_name != pk_column
              and hidden_column = 'NO'
              and virtual_column = 'NO';
        return l_field_list;
    end;

begin
    dbms_output.enable(1000000);
    if tables_for_sync.count = 0 then
        raise_application_error(-20001, 'Table list not specified.');
    end if;
    for i in tables_for_sync.first .. tables_for_sync.last
    loop
        current_table := upper(tables_for_sync(i));
        begin
            current_pk := get_pk_column(current_table);
            field_list := get_table_columns(current_table);
        exception
            when no_data_found then
                raise_application_error(-20001, 'Cannot get Primary Key for '
                    ||current_table);
        end;
        query_str := 'merge into '||current_table||'@'||db_link_name
            ||' t'||eol_char||'using '||current_table||' s on '
            ||'(s.'||current_pk||' = t.'||current_pk||')'||eol_char
            ||'when matched then'||eol_char
            ||'update set'||eol_char;
        for j in field_list.first .. field_list.last
        loop
            query_str := query_str||'t.'||field_list(j)||' = s.'
                ||field_list(j);
            if j < field_list.last then
                query_str := query_str || ',';
            end if;
            query_str := query_str || eol_char;
        end loop;

        query_str := query_str||'when not matched then'||eol_char||
            'insert (t.'||current_pk||','||eol_char;
        for j in field_list.first..field_list.last
        loop
            query_str := query_str||'t.'||field_list(j);
            if j < field_list.last then
                query_str := query_str||','||eol_char;
            end if;
        end loop;
        query_str := query_str||')'||eol_char||'values (s.'||current_pk||','
            ||eol_char;

        for j in field_list.first .. field_list.last
        loop
            query_str := query_str||'s.'||field_list(j);
            if j < field_list.last then
                query_str := query_str||','||eol_char;
            end if;
        end loop;
        if generate_only then
            query_str := query_str||');'||eol_char||'commit;'||eol_char
                ||eol_char;
            dbms_output.put_line(query_str);
        else
            query_str := query_str||')';
            execute immediate query_str;
            commit;
        end if;
    end loop;
end;
/
