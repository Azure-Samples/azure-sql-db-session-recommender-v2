CREATE TABLE [web].[speakers_embeddings] (
    [id]      INT              NOT NULL,
    [vector_value_id] INT              NOT NULL,
    [vector_value]    DECIMAL (19, 16) NOT NULL,
    CONSTRAINT fk__speakers_embeddings__speakers FOREIGN KEY ([id]) REFERENCES [web].[speakers] ([id])
);
GO

CREATE CLUSTERED COLUMNSTORE INDEX [IXCC]
    ON [web].[speakers_embeddings];
GO

