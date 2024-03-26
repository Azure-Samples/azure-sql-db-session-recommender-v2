
create procedure [web].[upsert_speaker_embeddings]
@id int,
@embeddings nvarchar(max)
as

set xact_abort on
set transaction isolation level serializable

begin transaction

    delete from web.speakers_embeddings 
    where id = @id

    insert into web.speakers_embeddings
    select @id, cast([key] as int), cast([value] as float) 
    from openjson(@embeddings)

    update 
        web.speakers 
    set 
        embeddings = @embeddings,
        require_embeddings_update = 0 
    where 
        id = @id

commit
GO

