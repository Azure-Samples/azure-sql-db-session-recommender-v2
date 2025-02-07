create or alter procedure [web].[find_sessions]
@text nvarchar(max),
@top int = 10,
@min_similarity decimal(19,16) = 0.30
as
if (@text is null) return;

insert into web.searched_text (searched_text) values (@text);
declare @sid int = scope_identity();

declare @startTime as datetime2(7) = sysdatetime()

declare @retval int, @qv vector(1536);

exec @retval = web.get_embedding @text, @qv output;

if (@retval != 0) return;

declare @endTime1 as datetime2(7) = sysdatetime();
update [web].[searched_text] set ms_rest_call = datediff(ms, @startTime, @endTime1) where id = @sid;

with cteSimilarSpeakers as 
(
    select top(@top)
        sp.id as speaker_id, 
        vector_distance('cosine', sp.[embeddings], @qv) as distance
    from 
        web.speakers sp
    order by
        distance 
),
cteSimilar as
(
     select top(@top)
        se.id as session_id, 
        vector_distance('cosine', se.[embeddings], @qv) as distance
    from 
        web.sessions se
    order by
        distance 
        
    union all

    select top(@top)
        ss.session_id,
        sp.distance
    from
        web.sessions_speakers ss 
    inner join
        cteSimilarSpeakers sp on sp.speaker_id = ss.speaker_id
        order by distance
),
cteSimilar2 as (
    select top(@top)
        *,
        rn = row_number() over (partition by session_id order by distance)
    from
        cteSimilar
    order by 
        distance
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
    1-distance as cosine_similarity
from 
    cteSimilar2 r
inner join 
    web.sessions a on r.session_id = a.id
where   
    (1-distance) > @min_similarity
and
    rn = 1
order by    
    distance asc, a.title asc;

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

