create procedure [web].[find_sessions]
@text nvarchar(max),
@top int = 10,
@min_similarity decimal(19,16) = 0.75
as
if (@text is null) return;

declare @sid as int = -1;
if (@text like N'***%') begin    
    set @text = trim(cast(substring(@text, 4, len(@text) - 3) as nvarchar(max)));    
end else begin
    insert into web.searched_text (searched_text) values (@text);
    set @sid = scope_identity();
end;

declare @startTime as datetime2(7) = sysdatetime()

declare @retval int, @response nvarchar(max);
declare @payload nvarchar(max);
set @payload = json_object('input': @text);

begin try
    exec @retval = sp_invoke_external_rest_endpoint
        @url = '$(OPEN_AI_ENDPOINT)/openai/deployments/$(OPEN_AI_DEPLOYMENT)/embeddings?api-version=2023-03-15-preview',
        @method = 'POST',
        @credential = [$(OPEN_AI_ENDPOINT)],
        @payload = @payload,
        @response = @response output;
end try
begin catch
    select 
        'SQL' as error_source, 
        error_number() as error_code,
        error_message() as error_message
    return;
end catch

if (@retval != 0) begin
    select 
        'OPENAI' as error_source, 
        json_value(@response, '$.result.error.code') as error_code,
        json_value(@response, '$.result.error.message') as error_message,
        @response as error_response
    return;
end;

declare @endTime1 as datetime2(7) = sysdatetime();
update [web].[searched_text] set ms_rest_call = datediff(ms, @startTime, @endTime1) where id = @sid;

with cteVector as
(
    select 
        cast([key] as int) as [vector_value_id],
        cast([value] as float) as [vector_value]
    from 
        openjson(json_query(@response, '$.result.data[0].embedding'))
),
cteSimilarSpeakers as 
(
    select 
        v2.id as speaker_id, 
        -- Optimized as per https://platform.openai.com/docs/guides/embeddings/which-distance-function-should-i-use
        sum(v1.[vector_value] * v2.[vector_value]) as cosine_similarity
    from 
        cteVector v1
    inner join 
        web.speakers_embeddings v2 on v1.vector_value_id = v2.vector_value_id
    group by
        v2.id

),
cteSimilar as
(
    select 
        v2.id as session_id, 
        -- Optimized as per https://platform.openai.com/docs/guides/embeddings/which-distance-function-should-i-use
        sum(v1.[vector_value] * v2.[vector_value]) as cosine_similarity
    from 
        cteVector v1
    inner join 
        web.sessions_embeddings v2 on v1.vector_value_id = v2.vector_value_id
    group by
        v2.id
        
    union all

    select
        ss.session_id,
        s.cosine_similarity
    from
        web.sessions_speakers ss 
    inner join
        cteSimilarSpeakers s on s.speaker_id = ss.speaker_id
),
cteSimilar2 as (
    select
        *,
        rn = row_number() over (partition by session_id order by cosine_similarity desc)
    from
        cteSimilar
),
cteSpeakers as
(
    select 
        session_id, 
        json_query('["' + string_agg(string_escape(full_name, 'json'), '","') + '"]') as speakers
    from 
        web.sessions_speakers ss 
    inner join 
        web.speakers sp on sp.id = ss.speaker_id 
    group by 
        session_id
)
select top(@top)
    a.id,
    a.title,
    a.abstract,
    a.external_id,
    a.start_time,
    a.end_time,
    a.recording_url,
    isnull((select top (1) speakers from cteSpeakers where session_id = a.id), '[]') as speakers,
    r.cosine_similarity
from 
    cteSimilar2 r
inner join 
    web.sessions a on r.session_id = a.id
where   
    r.cosine_similarity > @min_similarity
and
    rn = 1
order by    
    r.cosine_similarity desc, a.title asc;

declare @rc int = @@rowcount;

declare @endTime2 as datetime2(7) = sysdatetime()
update 
    [web].[searched_text] 
set 
    ms_vector_search = datediff(ms, @endTime1, @endTime2),
    found_sessions = @rc
where 
    id = @sid
GO

