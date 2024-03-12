using System;
using System.Data;
using System.Text.Json;
using Azure;
using Azure.AI.OpenAI;
using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using FromBodyAttribute = Microsoft.Azure.Functions.Worker.Http.FromBodyAttribute;

namespace SessionRecommender.RequestHandler;

public record ChatTurn(string userPrompt, string? responseMessage);

public record FoundSession(
    int Id, 
    string Title, 
    string Abstract,     
    double Similarity, 
    //string RecordingUrl, 
    string Speakers,
    string ExternalId,
    DateTimeOffset Start, 
    DateTimeOffset End
);

public class ChatHandler(OpenAIClient openAIClient, SqlConnection conn, ILogger<ChatHandler> logger)
{
    private readonly string _openAIDeploymentName = Environment.GetEnvironmentVariable("AZURE_OPENAI_GPT_DEPLOYMENT_NAME") ?? "gpt-4";

    private const string SystemMessage = """
You are a system assistant who helps users find the right session to watch from the conference, based off the sessions that are provided to you.

Sessions will be provided in an assistant message in the format of `title|abstract|speakers|start-time|end-time`. You can use this information to help you answer the user's question.
""";

    [Function("ChatHandler")]
    public async Task<IActionResult> AskAsync(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "ask")] HttpRequest req,
        [FromBody] ChatTurn[] history)
    {
        logger.LogInformation("Retrieving similar sessions...");

        DynamicParameters p = new();
        p.Add("@text", history.Last().userPrompt);
        p.Add("@top", 25);
        p.Add("@min_similarity", 0.70);

        using IDataReader foundSessions = await conn.ExecuteReaderAsync("[web].[find_sessions]", commandType: CommandType.StoredProcedure, param: p);

        List<FoundSession> sessions = [];
        while (foundSessions.Read())
        {
            sessions.Add(new(
                Id: foundSessions.GetInt32(0),
                Title: foundSessions.GetString(1),
                Abstract: foundSessions.GetString(2),
                ExternalId: foundSessions.GetString(3),
                Start: foundSessions.GetDateTime(4),
                End: foundSessions.GetDateTime(5),
                //RecordingUrl: foundSessions.GetString(6),
                Speakers: foundSessions.GetString(7),
                Similarity: foundSessions.GetDouble(8)
            ));
        }

        logger.LogInformation("Calling GPT...");

        string sessionDescriptions = string.Join("\r", sessions.Select(s => $"{s.Title}|{s.Abstract}|{s.Speakers}|{s.Start}|{s.End}"));

        List<ChatRequestMessage> messages = [new ChatRequestSystemMessage(SystemMessage)];

        foreach (ChatTurn turn in history)
        {
            messages.Add(new ChatRequestUserMessage(turn.userPrompt));
            if (turn.responseMessage is not null)
            {
                messages.Add(new ChatRequestAssistantMessage(turn.responseMessage));
            }
        }

        messages.Add(new ChatRequestUserMessage($@"## Source ##
{sessionDescriptions}
## End ##

You answer needs to divided in two sections: in the first section you'll add the answer to the question.
In the second section, that must be named exactly '###thoughts###', and you must use the section name as typed, without any changes, you'll write brief thoughts on how you came up with the answer, e.g. what sources you used, what you thought about, etc.
}}"));

        ChatCompletionsOptions options = new(_openAIDeploymentName, messages);

        try
        {
            var answerPayload = await openAIClient.GetChatCompletionsAsync(options);
            var answerContent = answerPayload.Value.Choices[0].Message.Content;
            
            //logger.LogInformation(answerContent);            
            
            var answerPieces = answerContent
                .Replace("###Thoughts###", "###thoughts###", StringComparison.InvariantCultureIgnoreCase)
                .Replace("### Thoughts ###", "###thoughts###", StringComparison.InvariantCultureIgnoreCase)
                .Split("###thoughts###", StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
            var answer = answerPieces[0];
            var thoughts = answerPieces.Length == 2 ? answerPieces[1] : "No thoughts provided.";
            
            logger.LogInformation("Done.");

            return new OkObjectResult(new
            {
                answer,
                thoughts                
            });
        }
        catch (Exception e)
        {
            logger.LogError(e, "Failed to get answer from OpenAI.");
            return new BadRequestObjectResult(e.Message);
        }
    }
}