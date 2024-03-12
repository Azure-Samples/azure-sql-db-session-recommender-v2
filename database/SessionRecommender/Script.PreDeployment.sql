if not exists(select * from sys.symmetric_keys where [name] = '##MS_DatabaseMasterKey##')
begin
    create master key encryption by password = N'V3RYStr0NGP@ssw0rd!';
end
go

if exists(select * from sys.[database_scoped_credentials] where name = '$(OPEN_AI_ENDPOINT)')
begin
	drop database scoped credential [$(OPEN_AI_ENDPOINT)];
end
go

create database scoped credential [$(OPEN_AI_ENDPOINT)]
with identity = 'HTTPEndpointHeaders', secret = '{"api-key":"$(OPEN_AI_KEY)"}';
go
