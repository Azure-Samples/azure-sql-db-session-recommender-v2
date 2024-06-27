create or alter procedure [web].[update_speaker_embeddings]
@id int,
@embeddings nvarchar(max)
as

update 
    web.speakers 
set 
    embeddings = json_array_to_vector(@embeddings),
    require_embeddings_update = 0
where   
    id = @id
    
GO

