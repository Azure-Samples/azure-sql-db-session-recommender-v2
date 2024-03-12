CREATE TABLE [web].[speakers] (
    [id]                            INT            DEFAULT (NEXT VALUE FOR [web].[global_id]) NOT NULL,
    [external_id]                   VARCHAR (100)  COLLATE Latin1_General_100_BIN2 NULL,
    [full_name]                     NVARCHAR (100) NOT NULL,
    [require_embeddings_update]     BIT            DEFAULT ((0)) NOT NULL,
    [embeddings]                    NVARCHAR (MAX) NULL,

    PRIMARY KEY CLUSTERED ([id] ASC),
    UNIQUE NONCLUSTERED ([full_name] ASC),
    CHECK (isjson([embeddings])=(1))
);
GO
