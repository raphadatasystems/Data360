USE [ETLFramework]
GO
SET IDENTITY_INSERT [config].[Schedule] ON 

GO
INSERT [config].[Schedule] ([ScheduleID], [ScheduleName], [FrequencyType], [FrequencyInterval], [SubdayType], [SubdayInterval], [RelativeInterval], [StartTime], [EndTime]) 
VALUES (1, N'Hourly Schedule', N'D', 0, N'H', 1, NULL, 800, 1700)
GO
SET IDENTITY_INSERT [config].[Schedule] OFF
GO
SET IDENTITY_INSERT [config].[Application] ON 

GO
INSERT [config].[Application] ([ApplicationID], [ApplicationName], [RecoveryActionCode], [AllowParallelExecution], [ParallelChannels], [IsDisabled]) VALUES (1, N'Demo App', N'R', 1, 4, 0)
GO
SET IDENTITY_INSERT [config].[Application] OFF
GO
SET IDENTITY_INSERT [config].[ApplicationSchedule] ON 

GO
INSERT [config].[ApplicationSchedule] ([ApplicationScheduleID], [ApplicationID], [ScheduleID], [LastRunDateTime], [NextRunDateTime], [IsEnabled], [IsDisabled])
VALUES (1, 1, 1, CAST(0x0000A1A40083D600 AS DateTime), CAST(0x0000A1A4009450C0 AS DateTime), 1, 0)
GO
SET IDENTITY_INSERT [config].[ApplicationSchedule] OFF
GO
SET IDENTITY_INSERT [config].[Package] ON 

GO
INSERT [config].[Package] ([PackageID], [PackagePath], [PackageName], [IsDisabled]) VALUES (1, N'Demo1.dtsx', N'Demo Package #1', 0)
GO
INSERT [config].[Package] ([PackageID], [PackagePath], [PackageName], [IsDisabled]) VALUES (3, N'Demo2.dtsx', N'Demo Package #2', 0)
GO
INSERT [config].[Package] ([PackageID], [PackagePath], [PackageName], [IsDisabled]) VALUES (4, N'Demo3.dtsx', N'Demo Package #3', 0)
GO
INSERT [config].[Package] ([PackageID], [PackagePath], [PackageName], [IsDisabled]) VALUES (5, N'DemoError.dtsx', N'Demo Package Error', 0)
GO
SET IDENTITY_INSERT [config].[Package] OFF
GO
SET IDENTITY_INSERT [config].[Task] ON 

GO
INSERT [config].[Task] ([TaskID], [TaskName], [ApplicationID], [PackageID], [ParallelChannel], [ExecutionOrder], [PrecendentTaskID], [ExecuteAsync], [FailureActionCode], [RecoveryActionCode], [LastRunDateTime], [IsActive], [IsDisabled])
VALUES (1, N'Demo Task #1', 1, 1, 1, 4, NULL, 0, N'A', N'R', CAST(0x0000A1A400BF80BC AS DateTime), 1, 0)
GO
INSERT [config].[Task] ([TaskID], [TaskName], [ApplicationID], [PackageID], [ParallelChannel], [ExecutionOrder], [PrecendentTaskID], [ExecuteAsync], [FailureActionCode], [RecoveryActionCode], [LastRunDateTime], [IsActive], [IsDisabled])
VALUES (4, N'Demo Task #2', 1, 3, 2, 2, NULL, 0, N'A', N'R', CAST(0x0000A1A400BF8070 AS DateTime), 1, 0)
GO
INSERT [config].[Task] ([TaskID], [TaskName], [ApplicationID], [PackageID], [ParallelChannel], [ExecutionOrder], [PrecendentTaskID], [ExecuteAsync], [FailureActionCode], [RecoveryActionCode], [LastRunDateTime], [IsActive], [IsDisabled]) 
VALUES (5, N'Demo Task #3', 1, 4, 3, 3, 1, 0, N'A', N'R', CAST(0x0000A1A400BFBF81 AS DateTime), 1, 0)
GO
INSERT [config].[Task] ([TaskID], [TaskName], [ApplicationID], [PackageID], [ParallelChannel], [ExecutionOrder], [PrecendentTaskID], [ExecuteAsync], [FailureActionCode], [RecoveryActionCode], [LastRunDateTime], [IsActive], [IsDisabled])
VALUES (6, N'Demo Task #4', 1, 5, 4, 1, NULL, 0, N'A', N'R', CAST(0x0000A1A400BF9FDC AS DateTime), 1, 0)
GO
SET IDENTITY_INSERT [config].[Task] OFF
GO