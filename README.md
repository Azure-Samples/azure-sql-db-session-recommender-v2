Coming Soon!

In the meantime take a look at v1 of this project:

- https://sessionfinder.dotnetconf.net/
- https://github.com/Azure-Samples/azure-sql-db-session-recommender

Coming Soon!

In the meantime take a look at v1 of this project:

- https://sessionfinder.dotnetconf.net/
- https://github.com/Azure-Samples/azure-sql-db-session-recommender

# Session Recommender V2

Coming soon...


```

insert into web.sessions 
    (title, abstract, external_id, start_time_PST, end_time_PST, require_embeddings_update)
values
    (
        'Building a session recommender using OpenAI and Azure SQL', 
        'In this fun and demo-driven session you’ll learn how to integrate Azure SQL with OpenAI to generate text embeddings, store them in the database, index them and calculate cosine distance to build a session recommender. And once that is done, you’ll publish it as a REST and GraphQL API to be consumed by a modern JavaScript frontend. Sounds pretty cool, uh? Well, it is!',
        'S1',
		'2024-03-10 10:00:00',
        '2024-03-10 11:00:00',
        1
    )

```

```
swa start ./client --api-location ./func --data-api-location ./swa-db-connections
```

## Fluent UI

The solution uses Fluent UI for the UI components. The Fluent UI is a collection of UX frameworks from Microsoft that provides a consistent design language for web, mobile, and desktop applications. More details about Fluent UI can be found at the following links: 

- https://github.com/microsoft/fluentui
- https://react.fluentui.dev/ 