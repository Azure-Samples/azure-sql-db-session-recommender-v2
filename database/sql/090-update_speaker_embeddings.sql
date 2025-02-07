create or alter procedure [web].[update_speaker_embeddings]
@id int,
@embeddings nvarchar(max)
as

update 
    web.speakers 
set 
    embeddings = cast(@embeddings as vector(1536)),
    require_embeddings_update = 0
where   
    id = @id
    
GO

