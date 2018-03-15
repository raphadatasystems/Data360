USE [ETLFramework]
GO

TRUNCATE TABLE [config].[Schedule]
TRUNCATE TABLE [config].[Application]
TRUNCATE TABLE [config].[ApplicationSchedule]
TRUNCATE TABLE [config].[Package]
TRUNCATE TABLE [config].[Task]

SET IDENTITY_INSERT [config].[Schedule] ON 
GO

INSERT INTO [config].[Schedule] (
	[ScheduleID],
	[ScheduleName], 
	[FrequencyType], 
	[FrequencyInterval], 
	[SubdayType], 
	[SubdayInterval], 
	[RelativeInterval], 
	[StartTime], 
	[EndTime]
) 
VALUES (
	1, 
	N'Hourly Schedule', 
	N'D', 
	0, 
	N'H', 
	1, 
	NULL, 
	800, 
	1700
)
GO

SET IDENTITY_INSERT [config].[Schedule] OFF
GO

SET IDENTITY_INSERT [config].[Application] ON 
GO

INSERT INTO [config].[Application] (
	[ApplicationID], 
	[ApplicationName], 
	[RecoveryActionCode], 
	[AllowParallelExecution], 
	[ParallelChannels], 
	[IsDisabled]
) 
VALUES (
	1, 
	N'Demo App', 
	N'R', 
	1, 
	4, 
	0
)
GO

SET IDENTITY_INSERT [config].[Application] OFF
GO

SET IDENTITY_INSERT [config].[ApplicationSchedule] ON 
GO

INSERT INTO [config].[ApplicationSchedule] (
	[ApplicationScheduleID], 
	[ApplicationID], 
	[ScheduleID], 
	[LastRunDateTime], 
	[NextRunDateTime], 
	[IsEnabled], 
	[IsDisabled]
)
VALUES (
	1, 
	1, 
	1, 
	CAST(0x0000A1A40083D600 AS DateTime), 
	CAST(0x0000A1A4009450C0 AS DateTime), 
	1, 
	0
)
GO

SET IDENTITY_INSERT [config].[ApplicationSchedule] OFF
GO

SET IDENTITY_INSERT [config].[Package] ON 
GO

INSERT INTO [config].[Package] ([PackageID], [PackagePath], [PackageName], [IsDisabled]) VALUES (1, N'Demo1.dtsx', N'Demo Package #1', 0)
GO

SET IDENTITY_INSERT [config].[Package] OFF
GO

SET IDENTITY_INSERT [config].[Task] ON 
GO

INSERT INTO [config].[Task] (
	[TaskID], 
	[TaskName], 
	[ApplicationID], 
	[PackageID], 
	[ParallelChannel], 
	[ExecutionOrder], 
	[PrecendentTaskID], 
	[ExecuteAsync], 
	[FailureActionCode], 
	[RecoveryActionCode], 
	[LastRunDateTime], 
	[IsActive], 
	[IsDisabled]
)
VALUES (
	1, 
	N'Demo Task #1', 
	1, 
	1, 
	1, 
	4, 
	NULL, 
	0, 
	N'A', 
	N'R', 
	CAST(0x0000A1A400BF80BC AS DateTime), 
	1, 
	0
)
GO

SET IDENTITY_INSERT [config].[Task] OFF
GO
