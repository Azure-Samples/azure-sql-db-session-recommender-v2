create or alter procedure [web].[update_session_embeddings]
@id int,
@embeddings nvarchar(max)
as

update 
    web.sessions 
set 
    embeddings = json_array_to_vector(@embeddings),
    require_embeddings_update = 0
where   
    id = @id

GO

