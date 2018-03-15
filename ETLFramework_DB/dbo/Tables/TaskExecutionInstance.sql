﻿CREATE TABLE [dbo].[TaskExecutionInstance] (
    [TaskExecutionInstanceID]        INT              IDENTITY (1, 1) NOT NULL,
    [ApplicationExecutionInstanceID] INT              NOT NULL,
    [TaskID]                         INT              NOT NULL,
    [PrecendentTaskID]               INT              NULL,
    [PackageName]                    NVARCHAR (255)   NOT NULL,
    [PackagePath]                    NVARCHAR (255)   NOT NULL,
    [FailureActionCode]              NCHAR (1)        NOT NULL,
    [RecoveryActionCode]             NCHAR (1)        NOT NULL,
    [ParallelChannel]                INT              NOT NULL,
    [ExecutionOrder]                 INT              NOT NULL,
    [ExecuteAsync]                   BIT              NOT NULL,
    [StatusCode]                     NCHAR (1)        NOT NULL,
    [StatusUpdateDateTime]           DATETIME         NOT NULL,
    [StartDateTime]                  DATETIME         NULL,
    [EndDateTime]                    DATETIME         NULL,
    [PackageExecutionID]             UNIQUEIDENTIFIER NULL,
    [TaskPackageExecutionID]         UNIQUEIDENTIFIER NULL,
    [TaskPackageID]                  UNIQUEIDENTIFIER NULL,
    [ExtractRowCount]                INT              NULL,
    [InsertRowCount]                 INT              NULL,
    [UpdateRowCount]                 INT              NULL,
    [DeleteRowCount]                 INT              NULL,
    [ErrorRowCount]                  INT              NULL,
    CONSTRAINT [PK_TaskExecutionInstance] PRIMARY KEY CLUSTERED ([TaskExecutionInstanceID] ASC)
);

