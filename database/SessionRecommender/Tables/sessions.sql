CREATE TABLE [web].[sessions] (
    [id]                        INT            DEFAULT (NEXT VALUE FOR [web].[global_id]) NOT NULL,
    [title]                     NVARCHAR (200) NOT NULL,
    [abstract]                  NVARCHAR (MAX) NOT NULL,
    [external_id]               VARCHAR (100)  COLLATE Latin1_General_100_BIN2 NULL,
    [last_fetched]              DATETIME2 (7)  NULL,    
    [start_time_PST]            DATETIME2 (0)  NULL,
    [end_time_PST]              DATETIME2 (0)  NULL,
    [tags]                      NVARCHAR (MAX) NULL,
    [recording_url]             VARCHAR (1000) NULL,
    [require_embeddings_update] BIT            DEFAULT ((0)) NOT NULL,
    [embeddings]                NVARCHAR (MAX) NULL,
    PRIMARY KEY CLUSTERED ([id] ASC),
    CHECK (isjson([tags])=(1)),
    UNIQUE NONCLUSTERED ([title] ASC)
);
GO



