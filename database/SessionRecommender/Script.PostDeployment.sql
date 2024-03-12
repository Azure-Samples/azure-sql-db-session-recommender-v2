-- This file contains SQL statements that will be executed after the build script.

alter table [web].[sessions] enable change_tracking with (track_columns_updated = off);
go

alter table [web].[speakers] enable change_tracking with (track_columns_updated = off);
go
