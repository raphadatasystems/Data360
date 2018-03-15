CREATE TABLE [config].[TaskDateParameter] (
    [TaskID]    INT  NOT NULL,
    [StartDate] DATE NULL,
    [EndDate]   DATE NULL,
    CONSTRAINT [fk_tsk_id] FOREIGN KEY ([TaskID]) REFERENCES [config].[Task] ([TaskID])
);

