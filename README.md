---
page_type: sample
languages:
- azdeveloper
- csharp
- sql
- tsql
- javascript
- html
- bicep
products:
- azure-functions
- azure-sql-database
- static-web-apps
- sql-server
- azure-sql-managed-instance
- azure-sqlserver-vm
- azure-openai
urlFragment: azure-sql-db-session-recommender-v2
name: Retrieval Augmented Generation with Azure SQL DB and OpenAI
description: Build a session recommender using Jamstack and Event-Driven architecture, using Azure SQL DB to store and search vectors embeddings generated using OpenAI
---
# Session Assistant Sample - Retrieval Augmented Generation with Azure SQL DB and OpenAI

This sample demonstrates how to build a session recommender using Jamstack and Event-Driven architecture, using Azure SQL DB to store and search vectors embeddings generated using OpenAI. The solution is built using Azure Static Web Apps, Azure Functions, Azure SQL Database, and Azure OpenAI.

A fully working, production ready, version of this sample, that has been used at [VS Live](https://vslive.com/) conferences, is available here: https://ai.microsofthq.vslive.com/

![Retrieval Augmented Generator flow](./_docs/rag.png)

This repository is a evoution of the [Session Recommender](https://github.com/azure-samples/azure-sql-db-session-recommender) sample. In addition to vector search, also Retrieval Augmented Generation (RAG) is used to generate the response to the user query. If you are completely new to this topic, you may want to start there, and then come back here.

![Architecture Diagram](./_docs/session-recommender-architecture.png)

A session recommender built using

- [Azure Static Web Apps](https://learn.microsoft.com/en-us/azure/static-web-apps/overview)
- [Azure OpenAI](https://learn.microsoft.com/azure/ai-services/openai/)
- [Azure Functions](https://learn.microsoft.com/azure/azure-functions/functions-overview?pivots=programming-language-csharp)
- [Azure Functions SQL Trigger Binding](https://learn.microsoft.com/azure/azure-functions/functions-bindings-azure-sql-trigger)
- [Azure SQL Database](https://www.sqlservercentral.com/articles/the-sql-developer-experience-beyond-rdbms)
- [Data API builder](https://aka.ms/dab)

For more details on the solution check also the following articles:

- [How I built a session recommender in 1 hour using Open AI](https://dev.to/azure/how-i-built-a-session-recommender-in-1-hour-using-open-ai-5419)
- [Vector Similarity Search with Azure SQL database and OpenAI](https://devblogs.microsoft.com/azure-sql/vector-similarity-search-with-azure-sql-database-and-openai/)

# Native or Classic ?
Azure SQL database can be used to easily and quickly perform vector similarity search. There are two options for this: a native option and a classic option.

The **native option** uses the new Vector Functions, recently introduced in Azure SQL database. Vector Functions are a set of functions that can be used to perform vector operations directly in the database. 

> [!NOTE]  
> Vector Functions are in Public Preview. Learn the details about vectors in Azure SQL here: https://aka.ms/azure-sql-vector-public-preview

```sql
DECLARE @embedding VECTOR(1536)

EXEC [web].[get_embedding] 'I want to learn about security in SQL', @embedding OUTPUT

SELECT TOP(10)
    s.id,
    s.title,
    s.abstract,
    VECTOR_DISTANCE('cosine', @embedding, s.embeddings) AS cosine_distance
FROM
    [web].[sessions] s
ORDER BY
    cosine_distance 
```

The **classic option** uses the classic T-SQL to perform vector operations, with the support for columnstore indexes for getting good performances.

> [!IMPORTANT]  
> This branch (the `main` branch) uses the native vector support in Azure SQL. If you want to use the classic T-SQL, switch to the `classic` branch.

# Deploy the sample using the Azure Developer CLI (azd) template

The Azure Developer CLI (`azd`) is a developer-centric command-line interface (CLI) tool for creating Azure applications.

## Prerequisites

- Install [AZD CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd).
- Install [.NET SDK](https://dotnet.microsoft.com/download).
- Install [Node.js](https://nodejs.org/download/).
- Install [SWA CLI](https://azure.github.io/static-web-apps-cli/docs/use/install#installing-the-cli).

## Install AZD CLI

You need to install it before running and deploying with the Azure Developer CLI.

### Windows

```powershell
powershell -ex AllSigned -c "Invoke-RestMethod 'https://aka.ms/install-azd.ps1' | Invoke-Expression"
```

### Linux/MacOS

```bash
curl -fsSL https://aka.ms/install-azd.sh | bash
```

After logging in with the following command, you will be able to use azd cli to quickly provision and deploy the application.

## Authenticate with Azure

Make sure AZD CLI can access Azure resources. You can use the following command to log in to Azure:

```bash
azd auth login
```

## Initialize the template

Then, execute the `azd init` command to initialize the environment (You do not need to run this command if you already have the code or have opened this in a Codespace or DevContainer).

```bash
azd init -t Azure-Samples/azure-sql-db-session-recommender-v2
```

Enter an environment name.

## Deploy the sample

Run `azd up` to provision all the resources to Azure and deploy the code to those resources.

```bash
azd up 
```

Select your desired `subscription` and `location`. Then choose a resource group or create a new resource group. Wait a moment for the resource deployment to complete, click the Website endpoint and you will see the web app page.

**Note**: Make sure to pick a region where all services are available like, for example, *West Europe* or *East US 2*

## GitHub Actions

Using the Azure Developer CLI, you can setup your pipelines, monitor your application, test and debug locally.

```bash
azd pipeline config
```

## Deploy the database

Since the database is using features that are in Private Preview, it must be deployed manually. After all resources have been deployed, get the database connection string and OpenAI endpoint and key and create a `.env` file from the `.env.sample` file. Once that is done, go into the `database` folder and run the following command:

```bash
dotnet run
```

The .NET application will create the database schema and the required objects.

## Test the solution

Add a new row to the `Sessions` table using the following SQL statement (you can use tools like [Azure Data Studio](https://learn.microsoft.com/en-us/azure-data-studio/quickstart-sql-database) or [SQL Server Management Studio](https://learn.microsoft.com/en-us/azure/azure-sql/database/connect-query-ssms?view=azuresql) to connect to the database. No need to install them if you don't want. In that case you can use the [SQL Editor in the Azure Portal](https://learn.microsoft.com/en-us/azure/azure-sql/database/connect-query-portal?view=azuresql)):

```sql
insert into web.speakers
    (id, full_name, require_embeddings_update)
values
    (5000, 'John Doe', 1)
go

insert into web.sessions 
    (id, title, abstract, external_id, start_time, end_time, require_embeddings_update)
values
    (
        1000,
        'Building a session recommender using OpenAI and Azure SQL', 
        'In this fun and demo-driven session you''ll learn how to integrate Azure SQL with OpenAI to generate text embeddings, store them in the database, index them and calculate cosine distance to build a session recommender. And once that is done, you’ll publish it as a REST and GraphQL API to be consumed by a modern JavaScript frontend. Sounds pretty cool, uh? Well, it is!',
        'S1',
        '2024-06-01 10:00:00',
        '2024-06-01 11:00:00',
        1
    )
go

insert into web.sessions_speakers
    (session_id, speaker_id)
values
    (1000, 5000)
go

insert into web.sessions 
    (id, title, abstract, external_id, start_time, end_time, require_embeddings_update)
values
    (
        1001,
        'Unlock the Art of Pizza Making with John Doe!', 
        'Whether you’re an avid home pizza oven enthusiast, contemplating a purchase, or nurturing dreams of launching your very own pizza venture, this course is tailor-made for you! Join John Doe, the visionary behind Great Pizza, as he guides you through the captivating world of pizza craftsmanship. With over six years of experience running his thriving pizza business, John has honed his skills to perfection, earning the title of a master pizzaiolo. Before embarking on his entrepreneurial journey, John—a former chef—also completed a pizza-making course at The School. Now, he’s excited to share his expertise with you in this hands-on workshop. During the course, you’ll learn to create three distinct pizza styles: Neapolitan, thin Roman “Tonda,” and Calzone. Dive into the art of dough preparation, experimenting with both high and low hydration doughs, all while adjusting temperatures to achieve pizza perfection. Don’t miss this opportunity to elevate your pizza-making game and impress your taste buds! ',
        'S2',
        '2024-06-01 11:00:00',
        '2024-06-01 12:00:00',
        1
    )
go

insert into web.sessions_speakers
    (session_id, speaker_id)
values
    (1001, 5000)
go

```

immediately the deployed Azure Function will get executed in response to the `INSERT` statement. The Azure Function will call the OpenAI service to generate the text embedding for the session title and abstract, and then store the embedding in the database, specifically in the `web.sessions` table.

```sql
select * from web.sessions
```

You can now open the URL associated with the created Static Web App to see the session recommender in action. You can get the URL from the Static Web App overview page in the Azure portal.

![Website running](./_docs/session-recommender.png)

## Run the solution locally

The whole solution can be executed locally, using [Static Web App CLI](https://github.com/Azure/static-web-apps-cli) and [Azure Function CLI](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=windows%2Cisolated-process%2Cnode-v4%2Cpython-v2%2Chttp-trigger%2Ccontainer-apps&pivots=programming-language-csharp).

Install the required node packages needed by the fronted:

```bash
cd client
npm install
```

once finished, create a `./func/local.settings.json` and `.env` starting from provided samples files, and fill out the settings using the correct values for your environment.

Go back to the sample root folder and then run:

```bash
swa build
```

to build the fronted and then start everything with:

```bash
swa start 
```

and once the local Static Web App environment is running, you can connect to

```text
http://localhost:4280/
```

and test the solution locally.

## Fluent UI

The solution uses Fluent UI for the UI components. The Fluent UI is a collection of UX frameworks from Microsoft that provides a consistent design language for web, mobile, and desktop applications. More details about Fluent UI can be found at the following links: 

- https://github.com/microsoft/fluentui
- https://react.fluentui.dev/ 

## Credits

Thanks a lot to [Aaron Powell](https://www.aaron-powell.com/) for having helped in building the RAG sample, doing a complete UI revamp using the Fluent UI and for the implementaiton of the `ask` endpoint.
