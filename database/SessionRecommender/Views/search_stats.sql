create view [web].search_stats
as
select 
    count(*) as total_searches, 
    avg(ms_vector_search) as avg_ms_vector_search 
from 
    [web].searched_text
GO

