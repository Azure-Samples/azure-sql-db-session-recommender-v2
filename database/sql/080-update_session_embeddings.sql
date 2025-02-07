create or alter procedure [web].[update_session_embeddings]
@id int,
@embeddings nvarchar(max)
as

update 
    web.sessions 
set 
    embeddings = cast(@embeddings as vector(1536)),
    require_embeddings_update = 0
where   
    id = @id

GO

