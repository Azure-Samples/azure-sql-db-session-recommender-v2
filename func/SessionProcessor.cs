using Microsoft.Extensions.Logging;
using Microsoft.Data.SqlClient;
using System.Data;
using Dapper;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Extensions.Sql;
using Azure.AI.OpenAI;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace SessionRecommender.RequestHandler;

public class Item 
{
    public required int Id { get; set; }

    [JsonPropertyName("require_embeddings_update")]
    public bool RequireEmbeddingsUpdate { get; set; }

    public override bool Equals(object? obj)
    {
        if (obj is null) return false;
        if (obj is not Item that) return false;         
        return Id == that.Id;
    }

    public override int GetHashCode()
    {
        return Id.GetHashCode();
    }

    public override string ToString()
    {
        return Id.ToString();
    }
}

public class Session: Item
{
    public string? Title { get; set; }

    public string? Abstract { get; set; }       
}

public class Speaker: Item
{
    [JsonPropertyName("full_name")]
    public string? FullName { get; set; }
}

public class ChangedItem: Item 
{
    public SqlChangeOperation Operation { get; set; }        
    public required string Payload { get; set; }
}

public class SessionProcessor(OpenAIClient openAIClient, SqlConnection conn, ILogger<SessionProcessor> logger)
{
    private readonly string _openAIDeploymentName = Environment.GetEnvironmentVariable("AZURE_OPENAI_EMBEDDINGS_DEPLOYMENT_NAME") ?? "embeddings";

    [Function(nameof(SessionTrigger))]
    public async Task SessionTrigger(
        [SqlTrigger("[web].[sessions]", "AZURE_SQL_CONNECTION_STRING")]
        IReadOnlyList<SqlChange<Session>> changes
        )
    {
        var ci = from c in changes 
                    where c.Operation != SqlChangeOperation.Delete 
                    where c.Item.RequireEmbeddingsUpdate == true
                    select new ChangedItem() { 
                        Id = c.Item.Id, 
                        Operation = c.Operation, 
                        Payload = c.Item.Title + ':' + c.Item.Abstract                       
                    };

        await ProcessChanges(ci, "web.sessions", "web.upsert_session_embeddings", logger);
    }

    [Function(nameof(SpeakerTrigger))]
    public async Task SpeakerTrigger(
        [SqlTrigger("[web].[speakers]", "AZURE_SQL_CONNECTION_STRING")]
        IReadOnlyList<SqlChange<Speaker>> changes        
        )
    {
        var ci = from c in changes 
                    where c.Operation != SqlChangeOperation.Delete 
                    where c.Item.RequireEmbeddingsUpdate == true
                    select new ChangedItem() { 
                        Id = c.Item.Id, 
                        Operation = c.Operation, 
                        Payload = c.Item.FullName ?? "",
                        RequireEmbeddingsUpdate = c.Item.RequireEmbeddingsUpdate
                    };

        await ProcessChanges(ci, "web.speakers", "web.upsert_speaker_embeddings", logger);          
    }

    private async Task ProcessChanges(IEnumerable<ChangedItem> changes, string referenceTable, string upsertStoredProcedure, ILogger logger)
    {
        var ct = changes.Count();
        if (ct == 0) {
            logger.LogInformation($"No useful changes detected on {referenceTable} table.");
            return;
        }

        logger.LogInformation($"There are {ct} changes that requires processing on table {referenceTable}.");

        foreach (var change in changes)
        {
            logger.LogInformation($"[{referenceTable}:{change.Id}] Processing change for operation: " + change.Operation.ToString());

            var attempts = 0;
            var embeddingsReceived = false;
            while (attempts < 3)
            {
                attempts++;

                logger.LogInformation($"[{referenceTable}:{change.Id}] Attempt {attempts}/3 to get embeddings.");

                var response = await openAIClient.GetEmbeddingsAsync(
                    new EmbeddingsOptions(_openAIDeploymentName, [change.Payload])
                );

                var e = response.Value.Data[0].Embedding;
                await conn.ExecuteAsync(
                    upsertStoredProcedure,
                    commandType: CommandType.StoredProcedure,
                    param: new
                    {
                        @id = change.Id,
                        @embeddings = JsonSerializer.Serialize(e)
                    });
                embeddingsReceived = true;

                logger.LogInformation($"[{referenceTable}:{change.Id}] Done.");                

                break;
            }
            if (!embeddingsReceived)
            {
                logger.LogInformation($"[{referenceTable}:{change.Id}] Failed to get embeddings.");
            }
        }
    }
}

