create view [web].last_searches
as
select top (100)
    id, 
    searched_text, 
    switchoffset(search_datetime, '-08:00') as search_datetime_pst, 
    ms_rest_call, 
    ms_vector_search, 
    found_sessions
from 
    [web].searched_text 
order by 
    id desc
GO

