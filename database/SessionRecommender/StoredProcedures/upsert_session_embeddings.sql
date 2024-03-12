
create procedure [web].[upsert_session_embeddings]
@id int,
@embeddings nvarchar(max)
as

set xact_abort on
set transaction isolation level serializable

begin transaction

    delete from web.sessions_embeddings 
    where id = @id

    insert into web.sessions_embeddings
    select @id, cast([key] as int), cast([value] as float) 
    from openjson(@embeddings)

    update web.sessions set require_embeddings_update = 0 where id = @id

commit
GO

