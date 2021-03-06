USE [ETLFramework]
GO
/****** Object:  Schema [audit]    Script Date: 4/18/2013 9:52:04 AM ******/
CREATE SCHEMA [audit]
GO
/****** Object:  Schema [config]    Script Date: 4/18/2013 9:52:04 AM ******/
CREATE SCHEMA [config]
GO
/****** Object:  Schema [log]    Script Date: 4/18/2013 9:52:04 AM ******/
CREATE SCHEMA [log]
GO
/****** Object:  Schema [reports]    Script Date: 4/18/2013 9:52:04 AM ******/
CREATE SCHEMA [reports]
GO
/****** Object:  StoredProcedure [config].[CalculateNextScheduleRunDate]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [config].[CalculateNextScheduleRunDate]
	@LastRunDate datetime,
	@FrequencyType nchar(1),
	@FrequencyInterval int = null,
	@FrequencySubDayType nchar(1) = null,
	@FrequencySubDayInterval int = null,
	@nthInterval int = null,	
	@StartTime int = null,
	@EndTime int = null,
	@NextRunDate datetime OUTPUT
AS
	IF @LastRunDate IS NULL
	BEGIN
		RAISERROR('Last Run Date is Required.', 10, 1);
		RETURN;
	END
	
	IF @FrequencyType IS NULL
	BEGIN
		RAISERROR('Frequence Type Is Required.', 10, 1);
		RETURN;
	END
		
	--Daily Schedule
	IF @FrequencyType = 'D'
	BEGIN
		IF @FrequencySubDayType IS NULL
		BEGIN
			RAISERROR('Frequency Sub-Day Is Required.', 10, 1);
			RETURN;
		END
		
		--Schedule runs at a specified time each day
		IF @FrequencySubDayType = 'T'
		BEGIN
			SET @NextRunDate = DATEADD(dd, 1, @LastRunDate)
		END
		--Schedule runs evey XX minutes
		ELSE IF @FrequencySubDayType = 'M'
		BEGIN
			SET @NextRunDate = DATEADD(mi, @FrequencySubDayInterval, @LastRunDate)
		END
		--Schedule runs every XX hours
		ELSE IF @FrequencySubDayType = 'H'
		BEGIN
			SET @NextRunDate = DATEADD(hh, @FrequencySubDayInterval, @LastRunDate)
		END
		ELSE
		BEGIN
			RAISERROR('Invalid Frequency Sub-Day Type', 10, 1);
			RETURN;
		END
		
		--Determine if the next run time is outside the running window
		IF (@StartTime IS NOT NULL) AND (@EndTime IS NOT NULL)
		BEGIN
			DECLARE @RunTime int
			
			--Convert the runtime to an integer
			SET @RunTime = DATEPART(hh, @NextRunDate) * 100 +
							DATEPART(mi, @NextRunDate) * 10
			
			-- If the schedule run time is before the start time or after the end time modify it
			IF (@RunTime < @StartTime) OR (@RunTime > @EndTime)
			BEGIN
				IF (@RunTime < @StartTime)
					--Stay with the current day but drop the time
					SET @NextRunDate = DATEADD(dd, DATEDIFF(d, 0, @NextRunDate), 0)
				ELSE
					--Advance to the next day
					SET @NextRunDate = DATEADD(dd, DATEDIFF(d, -1, @NextRunDate), 0)
				
				DECLARE @hours int
				DECLARE @minutes int
				
				SET @hours = @StartTime / 100
				SET @minutes = (@StartTime - (@hours * 100))/10
				
				--Use the start time to correctly set the schedule
				SET @NextRunDate = DATEADD(hh, @hours, @NextRunDate)
				SET @NextRunDate = DATEADD(mi, @minutes, @NextRunDate)
			END
		END
	END
	--Weekly Schedule
	ELSE IF @FrequencyType = 'W'
	BEGIN
		IF @FrequencyInterval IS NULL
		BEGIN
			RAISERROR('Frequency Interval Is Required.', 10, 1);
			RETURN;
		END
		
		--Use bitwise operators to determine which days of the week the schedule is set to run for
		--Frequency interval is a bitwise or of the weekday values (1,2,4,8,16,32,64)
		--Calculate the next rundate based on the last run date week day
		
		DECLARE @WeekDays AS TABLE ([weekday] int, value tinyint, result tinyint, nextrundate datetime);
		DECLARE @LastRunDayOfWeek int
		
		SET @LastRunDayOfWeek = DATEPART(dw, @LastRunDate)

		INSERT INTO @WeekDays
		SELECT 1, 1, @FrequencyInterval & 1, DATEADD(wk, 1, DATEADD(dw, (7 - @LastRunDayOfWeek) - 6, @LastRunDate))
		UNION ALL
		SELECT 2, 2, @FrequencyInterval & 2, CASE WHEN (@LastRunDayOfWeek < 2) THEN DATEADD(dw, (7 - @LastRunDayOfWeek) - 5, @LastRunDate) ELSE DATEADD(wk, 1, DATEADD(dw, (7 - @LastRunDayOfWeek) - 5, @LastRunDate)) END
		UNION ALL
		SELECT 3, 4, @FrequencyInterval & 4, CASE WHEN (@LastRunDayOfWeek < 3) THEN DATEADD(dw, (7 - @LastRunDayOfWeek) - 4, @LastRunDate) ELSE DATEADD(wk, 1, DATEADD(dw, (7 - @LastRunDayOfWeek) - 4, @LastRunDate)) END
		UNION ALL
		SELECT 4, 8, @FrequencyInterval & 8, CASE WHEN (@LastRunDayOfWeek < 4) THEN DATEADD(dw, (7 - @LastRunDayOfWeek) - 3, @LastRunDate) ELSE DATEADD(wk, 1, DATEADD(dw, (7 - @LastRunDayOfWeek) - 3, @LastRunDate)) END
		UNION ALL
		SELECT 5, 16, @FrequencyInterval & 16, CASE WHEN (@LastRunDayOfWeek < 5) THEN DATEADD(dw, (7 - @LastRunDayOfWeek) - 2, @LastRunDate) ELSE DATEADD(wk, 1, DATEADD(dw, (7 - @LastRunDayOfWeek) - 2, @LastRunDate)) END
		UNION ALL
		SELECT 6, 32, @FrequencyInterval & 32, CASE WHEN (@LastRunDayOfWeek < 6) THEN DATEADD(dw, (7 - @LastRunDayOfWeek) - 1, @LastRunDate) ELSE DATEADD(wk, 1, DATEADD(dw, (7 - @LastRunDayOfWeek) - 1, @LastRunDate)) END
		UNION ALL
		SELECT 7, 64, @FrequencyInterval & 64, CASE WHEN (@LastRunDayOfWeek < 7) THEN DATEADD(dw, (7 - @LastRunDayOfWeek), @LastRunDate) ELSE DATEADD(wk, 1, DATEADD(dw, (7 - @LastRunDayOfWeek), @LastRunDate)) END
		
		SELECT TOP 1 @NextRunDate = nextrundate
		FROM @WeekDays
		WHERE result <> 0
		ORDER BY nextrundate
	END	
	--Monthly Schedule
	ELSE IF @FrequencyType = 'M'
	BEGIN
		IF @FrequencyInterval IS NULL
		BEGIN
			RAISERROR('Frequency Interval Is Required.', 10, 1);
			RETURN;
		END
		
		IF @nthInterval IS NULL
		BEGIN
			RAISERROR('Relative Interval Is Required.', 10, 1);
			RETURN;
		END
		
		DECLARE @FirstOfMonth datetime
		DECLARE @DaysToAdd int
		DECLARE @FirstOccurence datetime

		--Get the first day of the month
		SET @FirstOfMonth = CONVERT(smalldatetime, 
			 CONVERT(varchar(4), YEAR(DATEADD(mm, 1, @LastRunDate))) + '/' +
			 CONVERT(varchar(2), MONTH(DATEADD(mm, 1, @LastRunDate))) + '/01'
			, 110)

		--Figure out how many days we need to get to the first occurence of the specified day
		SET @DaysToAdd = (7 - (DATEPART(dw, @FirstOfMonth) - @FrequencyInterval)) % 7

		--Find the first occuring date
		SET @FirstOccurence = DATEADD(d, @DaysToAdd, @FirstOfMonth)

		--Find the next run date
		SET @NextRunDate = DATEADD(d, 7 * (@nthInterval - 1), @FirstOccurence)

		--Safety-check just in case we over shoot the end of the month
		--(i.e. We say the last(5th) Saturday of a month when there are only 4)
		IF MONTH(@NextRunDate) <> MONTH(@FirstOfMonth)
		BEGIN
			SET @NextRunDate = DATEADD(d, 7 * (@nthInterval - 2), @FirstOccurence)	
		END
	END
	ELSE
	BEGIN
		RAISERROR('Invalid Frequency Type.', 10, 1);
		RETURN;
	END
GO
/****** Object:  StoredProcedure [config].[ResetAllLogs]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [config].[ResetAllLogs]
AS
truncate table [dbo].[ApplicationExecutionInstance]
truncate table [dbo].[TaskExecutionInstance]
truncate table [log].[ApplicationExecutionError]
truncate table [log].[TaskExecutionError]
truncate table [log].[TaskExecutionVariableLog]
GO
/****** Object:  StoredProcedure [config].[UpdateApplicationSchedule]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [config].[UpdateApplicationSchedule]
	@ApplicationScheduleID int
AS
	DECLARE @LastRunDate datetime
	DECLARE @FrequencyType nchar(1)
	DECLARE @FrequencyInterval int
	DECLARE @FrequencySubDayType nchar(1)
	DECLARE @FrequencySubDayInterval int
	DECLARE @nthInterval int	
	DECLARE @StartTime int
	DECLARE @EndTime int
	DECLARE @NextRunDate datetime

	SELECT
		@LastRunDate = COALESCE(COALESCE(NextRunDateTime, LastRunDateTime), getdate()),
		@FrequencyType = FrequencyType,
		@FrequencyInterval = FrequencyInterval,
		@FrequencySubDayType = SubdayType,
		@FrequencySubDayInterval = SubdayInterval,
		@nthInterval = RelativeInterval,
		@StartTime = StartTime,
		@EndTime = EndTime
	FROM config.ApplicationSchedule a
	JOIN config.Schedule s ON (a.ScheduleID = s.ScheduleID)
	WHERE a.ApplicationScheduleID = @ApplicationScheduleID
	AND a.IsEnabled = '1'
	AND a.IsDisabled = '0'
	
	EXEC config.CalculateNextScheduleRunDate 
		@LastRunDate,
		@FrequencyType,
		@FrequencyInterval,
		@FrequencySubDayType,
		@FrequencySubDayInterval,
		@nthInterval,
		@StartTime,
		@EndTime,
		@NextRunDate OUT

	UPDATE config.ApplicationSchedule
	SET
		LastRunDateTime	= NextRunDateTime,
		NextRunDateTime = @NextRunDate
	WHERE ApplicationScheduleID = @ApplicationScheduleID
GO
/****** Object:  StoredProcedure [dbo].[AbortApplicationExecution]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AbortApplicationExecution]
	@ApplicationExecutionInstanceID int
AS
	UPDATE dbo.ApplicationExecutionInstance
	SET
		ExecutionAborted = '1',
		StatusCode = 'F'
	WHERE ApplicationExecutionInstanceID = @ApplicationExecutionInstanceID

GO
/****** Object:  StoredProcedure [dbo].[ApplicationExecutionErrored]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ApplicationExecutionErrored]
	@ApplicationExecutionID int,
	@ErrorCode int,
	@ErrorDescription ntext,
	@SourceName nvarchar(255)
AS
	UPDATE dbo.ApplicationExecutionInstance
	SET
		EndDateTime = getdate(),
		StatusCode = 'F'
	WHERE ApplicationExecutionInstanceID = @ApplicationExecutionID
	
	INSERT INTO log.ApplicationExecutionError
	(
		ApplicationExecutionInstanceID,
		ErrorCode,
		ErrorDescription,
		ErrorDateTime,
		SourceName	
	)
	VALUES
	(
		@ApplicationExecutionID,
		@ErrorCode,
		@ErrorDescription,
		getdate(),
		@SourceName
	)
GO
/****** Object:  StoredProcedure [dbo].[CheckTaskPrecendent]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CheckTaskPrecendent]
	@TaskExecutionID int
AS
	SET NOCOUNT ON;
	
	DECLARE @ApplicationExecutionID int
	DECLARE @PrecendentTaskID int
	DECLARE @PrecendentStatus nchar(1)
	DECLARE @PrecendentComplete	int
	
	SELECT
		@ApplicationExecutionID = ApplicationExecutionInstanceID,
		@PrecendentTaskID = PrecendentTaskID
	FROM dbo.TaskExecutionInstance
	WHERE TaskExecutionInstanceID = @TaskExecutionID
		
	SELECT
		@PrecendentStatus = StatusCode
	FROM dbo.TaskExecutionInstance
	WHERE ApplicationExecutionInstanceID = @ApplicationExecutionID
	AND TaskID = @PrecendentTaskID
	
	IF (@PrecendentStatus IS NULL OR @PrecendentStatus = 'S')
	BEGIN
		SET @PrecendentComplete = '1'
	END
	ELSE IF (@PrecendentStatus = 'E' OR @PrecendentStatus = 'F' OR @PrecendentStatus = 'U' OR @PrecendentStatus = 'P')
	BEGIN
		SET @PrecendentComplete = '-1'
	END
	ELSE
	BEGIN
		SET @PrecendentComplete = '0'
	END
	
	SELECT @PrecendentComplete
GO
/****** Object:  StoredProcedure [dbo].[CompleteApplicationExecutionInstance]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CompleteApplicationExecutionInstance]
	@ApplicationExecutionInstanceID int
AS
	DECLARE @Status nchar(1)
	
	SET @Status = 'S' -- Default to 'Successful' ExecutionInstance
	
	-- Any task that were initialized but not attempted set them to unattempted
	UPDATE dbo.TaskExecutionInstance
	SET
		StatusCode = 'U',
		StatusUpdateDateTime = getdate()
	WHERE ApplicationExecutionInstanceID = @ApplicationExecutionInstanceID
	AND StatusCode = 'I'
	
	--If the application aborted set the status to 'Failed'
	IF (SELECT ExecutionAborted 
		FROM dbo.ApplicationExecutionInstance
		WHERE ApplicationExecutionInstanceID = @ApplicationExecutionInstanceID) = '1'
	BEGIN
		SET @Status = 'F' 
	END
	
	UPDATE dbo.ApplicationExecutionInstance
	SET
		EndDateTime = getdate(),
		StatusCode = @Status
	WHERE ApplicationExecutionInstanceID = @ApplicationExecutionInstanceID
GO
/****** Object:  StoredProcedure [dbo].[CompleteTaskExecutionInstance]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CompleteTaskExecutionInstance]
	@TaskExecutionInstanceID int,
	@TaskFailed bit
AS
	DECLARE @LogDtTime DATETIME
	
	SET @LogDtTime = getdate()
	
	UPDATE dbo.TaskExecutionInstance
	SET
		StatusCode = CASE WHEN (@TaskFailed = '0') THEN 'S' ELSE 'F' END,
		StatusUpdateDateTime = @LogDtTime,
		EndDateTime = @LogDtTime
	WHERE TaskExecutionInstanceID = @TaskExecutionInstanceID
	
	IF (@TaskFailed= '0')
	BEGIN
		UPDATE t
		SET LastRunDateTime = @LogDtTime
		FROM config.Task t
		JOIN dbo.TaskExecutionInstance l ON (l.TaskID = t.TaskID)
		WHERE l.TaskExecutionInstanceID = @TaskExecutionInstanceID
	END
		
GO
/****** Object:  StoredProcedure [dbo].[GetScheduledApplications]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetScheduledApplications]
AS	
	SELECT 
		l.ApplicationExecutionInstanceID,
		l.ApplicationID,
		l.ApplicationScheduleID
	FROM dbo.ApplicationExecutionInstance l
	WHERE l.ApplicationScheduleID IS NOT NULL --Ignore Application that are not run as a result of schedule
	AND (l.StatusCode = 'I' --Initialized Apps
	OR (l.StatusCode = 'F' AND l.RecoveryActionCode = 'R')) --Recovering Apps
GO
/****** Object:  StoredProcedure [dbo].[GetTaskDetail]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetTaskDetail]
	@TaskExecutionInstanceID int
AS
	SELECT
		ApplicationExecutionInstanceID,
		PackageName,
		PackagePath,
		FailureActionCode,
		ExecuteAsync
	FROM dbo.TaskExecutionInstance
	WHERE TaskExecutionInstanceID = @TaskExecutionInstanceID
GO
/****** Object:  StoredProcedure [dbo].[GetTasksForChannel]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetTasksForChannel]
	@ApplicationExecutionInstanceID int,
	@Channel int
AS
	SELECT
		l.TaskExecutionInstanceID
	FROM dbo.TaskExecutionInstance l
	WHERE l.ApplicationExecutionInstanceID = @ApplicationExecutionInstanceID
	AND l.ParallelChannel = @Channel	
	AND (
		(l.StatusCode = 'I')
		OR
		(
			l.StatusCode <> 'S'
			AND l.RecoveryActionCode = 'R'
		)
	)
	ORDER BY l.ExecutionOrder ASC
GO
/****** Object:  StoredProcedure [dbo].[InitializeScheduledApplications]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InitializeScheduledApplications]

AS
	INSERT INTO dbo.ApplicationExecutionInstance (
		ApplicationID,
		ApplicationScheduleID,
		ApplicationName,
		RecoveryActionCode,
		StatusCode,
		ExecutionAborted
	)
	SELECT
		a.ApplicationID,
		s.ApplicationScheduleID,
		a.ApplicationName,
		a.RecoveryActionCode,
		'I' AS StatusCode, --Status Code Initialized
		'0' AS ExecutionInstanceAborted
	FROM config.Application a
	JOIN config.ApplicationSchedule s ON (a.ApplicationID = s.ApplicationID)
	WHERE NextRunDateTime <= getdate()
	AND a.IsDisabled = '0'
	AND NOT EXISTS (
		SELECT *
		FROM dbo.ApplicationExecutionInstance l
		WHERE (
			(StatusCode = 'I' OR StatusCode = 'E')  OR --pending or active runs
			(StatusCode = 'F' AND RecoveryActionCode = 'R') --failed runs that will be retried
		)
	)
GO
/****** Object:  StoredProcedure [dbo].[InitializeTasks]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InitializeTasks]
	@ApplicationExecutionInstanceID int
AS
	SET NOCOUNT ON;
	
	DECLARE @ApplicationID int
	DECLARE @ErrorMessage nvarchar(255)
	
	IF (
		SELECT COUNT(*)
		FROM dbo.TaskExecutionInstance
		WHERE ApplicationExecutionInstanceID = @ApplicationExecutionInstanceID
		) > 0
	BEGIN
		SET @ErrorMessage = 'Tasks cannot be intialized more than once (Application ExecutionInstance ID: ' +
			CONVERT(nvarchar(50), @ApplicationExecutionInstanceID) + ').'
		RAISERROR(@ErrorMessage, 10, 1)
		
		RETURN
	END
	
	
	SELECT @ApplicationID = ApplicationID
	FROM dbo.ApplicationExecutionInstance
	WHERE ApplicationExecutionInstanceID = @ApplicationExecutionInstanceID
	
	INSERT INTO dbo.TaskExecutionInstance
	(
		ApplicationExecutionInstanceID,
		TaskID,
		PrecendentTaskID,
		ExecuteAsync,
		FailureActionCode,
		RecoveryActionCode,
		ParallelChannel,
		ExecutionOrder,
		PackagePath,
		PackageName,
		StatusCode,
		StatusUpdateDateTime
	)	
	SELECT
		@ApplicationExecutionInstanceID,
		t.TaskID,
		t.PrecendentTaskID,	
		t.ExecuteAsync,
		t.FailureActionCode,
		t.RecoveryActionCode,
		t.ParallelChannel,
		t.ExecutionOrder,
		p.PackagePath,
		p.PackageName,
		'I', -- Status Code for Pending
		getdate()
	FROM config.Task t
	JOIN config.Package p ON (t.PackageID = p.PackageID)
	WHERE t.ApplicationID = @ApplicationID 
	AND t.IsActive = '1'
	AND t.IsDisabled = '0'
GO
/****** Object:  StoredProcedure [dbo].[IsApplicationAborted]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[IsApplicationAborted]
	@ApplicationExecutionInstanceID int
AS
	SELECT
		ExecutionAborted
	FROM dbo.ApplicationExecutionInstance
	WHERE ApplicationExecutionInstanceID=@ApplicationExecutionInstanceID
GO
/****** Object:  StoredProcedure [dbo].[IsApplicationRunning]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[IsApplicationRunning]
	@ApplicationID int
AS
	DECLARE @IsRunning bit
	
	IF (
		SELECT
			COUNT(*)
		FROM dbo.ApplicationExecutionInstance
		WHERE ApplicationID = @ApplicationID
		AND StatusCode = 'E'
		) > 0
	BEGIN
		SET @IsRunning = '1'
	END
	ELSE
	BEGIN
		SET @IsRunning = '0'
	END
	
	SELECT @IsRunning
GO
/****** Object:  StoredProcedure [dbo].[IsParallelChannelEnabled]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[IsParallelChannelEnabled]
	@Channel int,
	@ApplicationExecutionInstanceID int
AS
	SELECT 
		CASE WHEN (AllowParallelExecution = '1') THEN
			CASE WHEN (ParallelChannels >= @Channel) THEN
				CONVERT(bit, '1')
			ELSE
				CONVERT(bit, '0')
			END
		ELSE
			CASE WHEN (@Channel  = 1) THEN
				CONVERT(bit, '1')
			ELSE
				CONVERT(bit, '0')
			END
		END AS ChannelEnabled
	FROM dbo.ApplicationExecutionInstance e
	JOIN config.[Application] a ON (e.ApplicationID = a.ApplicationID)
	WHERE e.ApplicationExecutionInstanceID = @ApplicationExecutionInstanceID

GO
/****** Object:  StoredProcedure [dbo].[LaunchApplicationExecutionInstance]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LaunchApplicationExecutionInstance]
	@ApplicationID int,
	@ApplicationScheduleID int,
	@SSISExecutionInstanceID bigint,
	@PkgExecutionID nvarchar(50)
AS
	SET NOCOUNT ON;
	
	DECLARE @ApplicationExecutionInstanceID int
	DECLARE @out TABLE (ExecutionInstanceID int);
	DECLARE @RecoveryActionCode nchar(1)
	DECLARE @StatusCode nchar(1)
	DECLARE @ApplicationName nvarchar(50)
	DECLARE @IsApplicationRecovery bit
	DECLARE @PackageExecutionID uniqueidentifier

	SET @PackageExecutionID = CAST(@PkgExecutionID AS uniqueidentifier)

	--Determine if we are either running an initialized app
	--or if we are recovering an app
	SELECT
		@ApplicationName = ApplicationName,
		@ApplicationExecutionInstanceID = ApplicationExecutionInstanceID,
		@StatusCode = StatusCode
	FROM dbo.ApplicationExecutionInstance
	WHERE ApplicationID = @ApplicationID
	AND (StatusCode = 'I'
	OR (StatusCode = 'F' AND RecoveryActionCode = 'R'))
			
	IF (@ApplicationExecutionInstanceID IS NULL)
	BEGIN
		--Get the application info
		SELECT 
			@ApplicationName = ApplicationName,
			@RecoveryActionCode = RecoveryActionCode
		FROM config.Application
		WHERE ApplicationID = @ApplicationID
		
		SET @IsApplicationRecovery = '0'
		SET @ApplicationScheduleID = NULL
		
		--Insert our app ExecutionInstance record and get the id		
		INSERT INTO dbo.ApplicationExecutionInstance
		(
			ApplicationID,
			ApplicationScheduleID,
			ApplicationName,
			RecoveryActionCode,
			SSISExecutionID,
			PackageExecutionID,
			StartDateTime,
			StatusCode,
			ExecutionAborted			
		)
		OUTPUT INSERTED.ApplicationExecutionInstanceID INTO @out
		VALUES
		(
			@ApplicationID,
			@ApplicationScheduleID,
			@ApplicationName,
			@RecoveryActionCode,
			@SSISExecutionInstanceID,
			@PackageExecutionID,
			getdate(),
			'E',
			'0'
		)
		
		SELECT @ApplicationExecutionInstanceID = ExecutionInstanceID FROM @out
	END
	ELSE
	BEGIN
		--This is either an initialized ExecutionInstance or we are recovering		
		IF (@StatusCode = 'F') --We are recovering the app
		BEGIN		
			SET @IsApplicationRecovery = '1'
		END
		
		UPDATE dbo.ApplicationExecutionInstance
		SET
			SSISExecutionID = @SSISExecutionInstanceID,
			PackageExecutionID = @PackageExecutionID,
			StartDateTime = getdate(),
			StatusCode = 'E',
			ExecutionAborted = '0'
		WHERE
			ApplicationExecutionInstanceID = @ApplicationExecutionInstanceID
	END
	
	SELECT @ApplicationExecutionInstanceID, @ApplicationName, @IsApplicationRecovery
GO
/****** Object:  StoredProcedure [dbo].[LaunchTaskExecutionInstance]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LaunchTaskExecutionInstance]
	@TaskExecutionInstanceID int,
	@PkgExecutionID nvarchar(50)
AS
	DECLARE @PackageExecutionID uniqueidentifier

	SET @PackageExecutionID = CAST(@PkgExecutionID AS uniqueidentifier)

	UPDATE dbo.TaskExecutionInstance
	SET
		StatusCode = 'R', -- Started Code
		PackageExecutionID = @PackageExecutionID,
		StatusUpdateDateTime = getdate(),
		StartDateTime = getdate()
	WHERE TaskExecutionInstanceID = @TaskExecutionInstanceID
	
	
		
		
GO
/****** Object:  StoredProcedure [dbo].[RethrowError]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROC [dbo].[RethrowError]
AS
	DECLARE @ErrorMessage NVARCHAR(4000),
	@ErrorNumber INT,
	@ErrorSeverity INT,
	@ErrorState INT,
	@ErrorLine INT,
	@ErrorProcedure NVARCHAR(200);
	
	SELECT 
		@ErrorNumber = ERROR_NUMBER(),
		@ErrorSeverity = ERROR_SEVERITY(),
		@ErrorState = CASE WHEN ERROR_STATE() > 0 THEN ERROR_STATE() ELSE 1 END,
		@ErrorLine = ERROR_LINE(),
		@ErrorProcedure = ISNULL(ERROR_PROCEDURE(), '-'),
		@ErrorMessage = N'Error %d, Level %d, State %d, Procedure %s, Line %d, Message: ' + ERROR_MESSAGE();

	RAISERROR ( @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorSeverity, @ErrorState, @ErrorProcedure, @ErrorLine );
GO
/****** Object:  StoredProcedure [dbo].[SetPackageExecutionID]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SetPackageExecutionID]
	@TaskExecutionInstanceID int,
	@PkgExecutionID nvarchar(50),
	@PkgID nvarchar(50)
AS
	DECLARE @PackageExecutionID uniqueidentifier
	DECLARE @PackageID uniqueidentifier

	SET @PackageExecutionID = CAST(@PkgExecutionID AS uniqueidentifier)
	SET @PackageID = CAST(@PkgID AS uniqueidentifier)

	UPDATE dbo.TaskExecutionInstance
	SET
		TaskPackageID = @PackageID,
		TaskPackageExecutionID = @PackageExecutionID
	WHERE TaskExecutionInstanceID = @TaskExecutionInstanceID
	
	
		
		
GO
/****** Object:  StoredProcedure [dbo].[UpdateTaskExecutionStatus]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateTaskExecutionStatus]
	@TaskExecutionID int,
	@StatusCode nchar(1)
AS
	UPDATE dbo.TaskExecutionInstance
	SET
		StatusCode = @StatusCode,
		StatusUpdateDateTime = getdate()
	WHERE TaskExecutionInstanceID = @TaskExecutionID
GO
/****** Object:  StoredProcedure [log].[LogTaskExecutionError]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [log].[LogTaskExecutionError]
	@TaskExecutionInstanceID int,
	@ErrorCode int = NULL,
	@ErrorDescription ntext = NULL,
	@SourceName nvarchar(255) = NULL
AS
	IF @ErrorCode IS NOT NULL AND
		@ErrorDescription IS NOT NULL AND
		@SourceName IS NOT NULL 
	BEGIN
		INSERT INTO log.TaskExecutionError
		(
			TaskExecutionInstanceID,
			ErrorCode,
			ErrorDescription,
			ErrorDateTime,
			SourceName	
		)
		VALUES
		(
			@TaskExecutionInstanceID,
			@ErrorCode,
			@ErrorDescription,
			getdate(),
			@SourceName
		)
	END
GO
/****** Object:  StoredProcedure [log].[LogTaskRowCount]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [log].[LogTaskRowCount]
	@TaskExecutionInstanceID int,
	@ExtractRowCount int,
	@InsertRowCount int,
	@UpdateRowCount int,
	@DeleteRowCount int,
	@ErrorRowCount int	
AS
	UPDATE dbo.TaskExecutionInstance
	SET
		ExtractRowCount = @ExtractRowCount,
		InsertRowCount = @InsertRowCount,
		UpdateRowCount = @UpdateRowCount,
		DeleteRowCount = @DeleteRowCount,
		ErrorRowCount = @ErrorRowCount
	WHERE TaskExecutionInstanceID = @TaskExecutionInstanceID
GO
/****** Object:  StoredProcedure [log].[LogTaskVariableChange]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [log].[LogTaskVariableChange]
	@TaskExecutionInstanceID int, 
	@VariableName varchar(255), 
	@VariableValue ntext
AS
	INSERT [log].[TaskExecutionVariableLog] (
		TaskExecutionInstanceID, VariableName, VariableValue, LoggedDateTime
	) VALUES (
		@TaskExecutionInstanceID, 
		@VariableName, 
		@VariableValue, 
		GETDATE()
	)
GO
/****** Object:  StoredProcedure [log].[TaskExecutionInstanceHeartBeat]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [log].[TaskExecutionInstanceHeartBeat]
	@TaskExecutionInstanceID int
AS
	UPDATE dbo.TaskExecutionInstance
	SET
		StatusUpdateDateTime = getdate()
	WHERE TaskExecutionInstanceID = @TaskExecutionInstanceID
	
	
		
		
GO
/****** Object:  StoredProcedure [reports].[GetApplicationExecutionOverview]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [reports].[GetApplicationExecutionOverview]
	@ApplicationExecutionInstanceID int
AS
	SELECT
		l.TaskExecutionInstanceID,
		l.TaskID,
		l.TaskPackageExecutionID,
		l.TaskPackageID,
		a.SSISExecutionID,
		t.TaskName,
		l.PackageName,
		l.StartDateTime,
		l.EndDateTime,
		CAST(DATEDIFF(n, l.StartDateTime, l.EndDateTime) AS varchar(50)) + ':' +
					RIGHT('0' + CAST(DATEDIFF(s, l.StartDateTime, l.EndDateTime) AS varchar(50)), 2) + ':' +
						CAST(DATEDIFF(ms, l.StartDateTime, l.EndDateTime) AS varchar(50))
					AS ExecutionTime,
		s.CodeDescription AS StatusCodeDescription,
		f.CodeDescription AS FailureActionCodeDescription,
		r.CodeDescription AS RecoveryActionCodeDescription,
		l.ParallelChannel,
		l.ExecutionOrder,
		l.ExtractRowCount,
		l.InsertRowCount,
		l.UpdateRowCount,
		l.DeleteRowCount,
		l.ErrorRowCount
	FROM dbo.TaskExecutionInstance l
	JOIN dbo.ApplicationExecutionInstance a ON (l.ApplicationExecutionInstanceID = a.ApplicationExecutionInstanceID)
	JOIN config.Task t ON (t.TaskID = l.TaskID)
	JOIN config.FrameworkCodes f ON (l.FailureActionCode = f.FrameworkCode AND f.CodeType='Failure Action')
	JOIN config.FrameworkCodes r ON (l.RecoveryActionCode = r.FrameworkCode AND r.CodeType='Recovery Mode')
	JOIN config.FrameworkCodes s ON (l.StatusCode = s.FrameworkCode AND s.CodeType='Task Status')
	WHERE l.ApplicationExecutionInstanceID=@ApplicationExecutionInstanceID
	ORDER BY l.ParallelChannel, l.ExecutionOrder
GO
/****** Object:  StoredProcedure [reports].[GetApplicationHistory]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [reports].[GetApplicationHistory]
(
	@ApplicationID int
)
AS
	SELECT
		l.ApplicationExecutionInstanceID,
		l.SSISExecutionID,
		f.CodeDescription AS StatusCodeDescription,
		r.CodeDescription AS RecoveryActionCodeDescription,
		l.ApplicationName,
		l.StartDateTime,
		l.EndDateTime,
		CAST(DATEDIFF(n, l.StartDateTime, l.EndDateTime) AS varchar(50)) + ':' +
					RIGHT('0' + CAST(DATEDIFF(s, l.StartDateTime, l.EndDateTime) AS varchar(50)), 2) + ':' +
						CAST(DATEDIFF(ms, l.StartDateTime, l.EndDateTime) AS varchar(50))
					AS ExecutionTime,
		CASE WHEN (l.ExecutionAborted = '0') THEN 'False' ELSE 'True' END AS ExecutionAborted,
		CASE WHEN (l.ApplicationScheduleID IS NULL) THEN 'False' ELSE 'True' END AS ScheduledExecution
	FROM dbo.ApplicationExecutionInstance l
	JOIN config.Application a ON (l.ApplicationID = a.ApplicationID)
	JOIN config.FrameworkCodes f ON (f.FrameworkCode=l.StatusCode AND f.CodeType='Run Status')
	JOIN config.FrameworkCodes r ON (r.FrameworkCode=l.RecoveryActionCode AND r.CodeType='Recovery Mode')
	WHERE l.ApplicationID = @ApplicationID
	AND a.IsDisabled='0'
	ORDER BY l.StartDateTime DESC
GO
/****** Object:  StoredProcedure [reports].[GetApplicationsOverview]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [reports].[GetApplicationsOverview]

AS
	WITH cte AS
	(
		SELECT
			a.ApplicationID,
			a.ApplicationName,
			l.StartDateTime AS LastStartDateTime,
			l.EndDateTime AS LastEndDateTime,
			CAST(DATEDIFF(n, l.StartDateTime, l.EndDateTime) AS varchar(50)) + ':' +
				RIGHT('0' + CAST(DATEDIFF(s, l.StartDateTime, l.EndDateTime) AS varchar(50)), 2) + ':' +
					CAST(DATEDIFF(ms, l.StartDateTime, l.EndDateTime) AS varchar(50))
				AS LastExecutionTime,
			CASE WHEN (l.ExecutionAborted = '0') THEN 'False' ELSE 'True' END AS LastExecutionAborted,
			f.CodeDescription AS LastStatusCodeDescription,
			s.NextScheduleRunDateTime,
			ExecutionRank = ROW_NUMBER() OVER (
				PARTITION BY l.ApplicationID
				ORDER BY l.StartDateTime DESC
			)
		FROM dbo.ApplicationExecutionInstance l
		OUTER APPLY (
			SELECT
				s.ApplicationID,
				MIN(s.NextRunDateTime) AS NextScheduleRunDateTime
			FROM config.ApplicationSchedule s
			WHERE s.ApplicationID = l.ApplicationID
			GROUP BY s.ApplicationID		
		) s
		JOIN config.Application a ON (l.ApplicationID = a.ApplicationID)
		JOIN config.FrameworkCodes f ON (f.FrameworkCode=l.StatusCode AND f.CodeType='Run Status')
		WHERE a.IsDisabled = '0'
	)

	SELECT
		ApplicationID,
		ApplicationName,
		LastStartDateTime,
		LastEndDateTime,
		LastExecutionTime,
		LastExecutionAborted,
		LastStatusCodeDescription,
		NextScheduleRunDateTime
	FROM cte
	WHERE ExecutionRank = 1
	ORDER BY ApplicationName
GO
/****** Object:  StoredProcedure [reports].[GetTaskHistory]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [reports].[GetTaskHistory]
	@TaskID int
AS
	SELECT
		l.TaskExecutionInstanceID,
		l.TaskID,
		l.TaskPackageExecutionID,
		l.TaskPackageID,
		a.SSISExecutionID,
		t.TaskName,
		l.PackageName,
		l.StartDateTime,
		l.EndDateTime,
		CAST(DATEDIFF(n, l.StartDateTime, l.EndDateTime) AS varchar(50)) + ':' +
					RIGHT('0' + CAST(DATEDIFF(s, l.StartDateTime, l.EndDateTime) AS varchar(50)), 2) + ':' +
						CAST(DATEDIFF(ms, l.StartDateTime, l.EndDateTime) AS varchar(50))
					AS ExecutionTime,
		s.CodeDescription AS StatusCodeDescription,
		f.CodeDescription AS FailureActionCodeDescription,
		r.CodeDescription AS RecoveryActionCodeDescription,
		l.ParallelChannel,
		l.ExecutionOrder,
		l.ExecuteAsync,
		l.ExtractRowCount,
		l.InsertRowCount,
		l.UpdateRowCount,
		l.DeleteRowCount,
		l.ErrorRowCount
	FROM dbo.TaskExecutionInstance l
	JOIN dbo.ApplicationExecutionInstance a ON (l.ApplicationExecutionInstanceID = a.ApplicationExecutionInstanceID)
	JOIN config.Task t ON (t.TaskID = l.TaskID)
	JOIN config.FrameworkCodes f ON (l.FailureActionCode = f.FrameworkCode AND f.CodeType='Failure Action')
	JOIN config.FrameworkCodes r ON (l.RecoveryActionCode = r.FrameworkCode AND r.CodeType='Recovery Mode')
	JOIN config.FrameworkCodes s ON (l.StatusCode = s.FrameworkCode AND s.CodeType='Task Status')
	WHERE l.TaskID=@TaskID
	ORDER BY l.StartDateTime DESC
GO
/****** Object:  Table [config].[Application]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [config].[Application](
	[ApplicationID] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationName] [nvarchar](50) NOT NULL,
	[RecoveryActionCode] [nchar](1) NOT NULL,
	[AllowParallelExecution] [bit] NOT NULL,
	[ParallelChannels] [int] NOT NULL,
	[IsDisabled] [bit] NOT NULL,
 CONSTRAINT [PK_Application] PRIMARY KEY CLUSTERED 
(
	[ApplicationID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [config].[ApplicationSchedule]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [config].[ApplicationSchedule](
	[ApplicationScheduleID] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationID] [int] NOT NULL,
	[ScheduleID] [int] NOT NULL,
	[LastRunDateTime] [datetime] NULL,
	[NextRunDateTime] [datetime] NULL,
	[IsEnabled] [bit] NOT NULL,
	[IsDisabled] [bit] NOT NULL,
 CONSTRAINT [PK_ApplicationSchedule] PRIMARY KEY CLUSTERED 
(
	[ApplicationScheduleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [config].[FrameworkCodes]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [config].[FrameworkCodes](
	[CodeType] [nvarchar](50) NOT NULL,
	[FrameworkCode] [nchar](1) NOT NULL,
	[CodeDescription] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_FrameworkCodes] PRIMARY KEY CLUSTERED 
(
	[FrameworkCode] ASC,
	[CodeType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [config].[Package]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [config].[Package](
	[PackageID] [int] IDENTITY(1,1) NOT NULL,
	[PackagePath] [nvarchar](255) NOT NULL,
	[PackageName] [nvarchar](255) NOT NULL,
	[IsDisabled] [bit] NOT NULL,
 CONSTRAINT [PK_Package] PRIMARY KEY CLUSTERED 
(
	[PackageID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [config].[Schedule]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [config].[Schedule](
	[ScheduleID] [int] IDENTITY(1,1) NOT NULL,
	[ScheduleName] [nvarchar](50) NOT NULL,
	[FrequencyType] [nchar](1) NOT NULL,
	[FrequencyInterval] [int] NULL,
	[SubdayType] [nchar](1) NULL,
	[SubdayInterval] [int] NULL,
	[RelativeInterval] [int] NULL,
	[StartTime] [int] NULL,
	[EndTime] [int] NULL,
 CONSTRAINT [PK_Schedules] PRIMARY KEY CLUSTERED 
(
	[ScheduleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [config].[SSISConfiguration]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [config].[SSISConfiguration](
	[ConfigurationFilter] [nvarchar](255) NOT NULL,
	[ConfiguredValue] [nvarchar](255) NULL,
	[PackagePath] [nvarchar](255) NOT NULL,
	[ConfiguredValueType] [nvarchar](20) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [config].[Task]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [config].[Task](
	[TaskID] [int] IDENTITY(1,1) NOT NULL,
	[TaskName] [nvarchar](50) NOT NULL,
	[ApplicationID] [int] NOT NULL,
	[PackageID] [int] NOT NULL,
	[ParallelChannel] [int] NOT NULL,
	[ExecutionOrder] [int] NOT NULL,
	[PrecendentTaskID] [int] NULL,
	[ExecuteAsync] [bit] NOT NULL,
	[FailureActionCode] [nchar](1) NOT NULL,
	[RecoveryActionCode] [nchar](1) NOT NULL,
	[LastRunDateTime] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
	[IsDisabled] [bit] NOT NULL,
 CONSTRAINT [PK_Task] PRIMARY KEY CLUSTERED 
(
	[TaskID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ApplicationExecutionInstance]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApplicationExecutionInstance](
	[ApplicationExecutionInstanceID] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationID] [int] NOT NULL,
	[ApplicationScheduleID] [int] NULL,
	[ApplicationName] [nvarchar](50) NOT NULL,
	[RecoveryActionCode] [nchar](1) NOT NULL,
	[StartDateTime] [datetime] NULL,
	[EndDateTime] [datetime] NULL,
	[StatusCode] [nchar](1) NOT NULL,
	[ExecutionAborted] [bit] NOT NULL,
	[SSISExecutionID] [bigint] NULL,
	[PackageExecutionID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_ApplicationExecutionInstance] PRIMARY KEY CLUSTERED 
(
	[ApplicationExecutionInstanceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TaskExecutionInstance]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaskExecutionInstance](
	[TaskExecutionInstanceID] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationExecutionInstanceID] [int] NOT NULL,
	[TaskID] [int] NOT NULL,
	[PrecendentTaskID] [int] NULL,
	[PackageName] [nvarchar](255) NOT NULL,
	[PackagePath] [nvarchar](255) NOT NULL,
	[FailureActionCode] [nchar](1) NOT NULL,
	[RecoveryActionCode] [nchar](1) NOT NULL,
	[ParallelChannel] [int] NOT NULL,
	[ExecutionOrder] [int] NOT NULL,
	[ExecuteAsync] [bit] NOT NULL,
	[StatusCode] [nchar](1) NOT NULL,
	[StatusUpdateDateTime] [datetime] NOT NULL,
	[StartDateTime] [datetime] NULL,
	[EndDateTime] [datetime] NULL,
	[PackageExecutionID] [uniqueidentifier] NULL,
	[TaskPackageExecutionID] [uniqueidentifier] NULL,
	[TaskPackageID] [uniqueidentifier] NULL,
	[ExtractRowCount] [int] NULL,
	[InsertRowCount] [int] NULL,
	[UpdateRowCount] [int] NULL,
	[DeleteRowCount] [int] NULL,
	[ErrorRowCount] [int] NULL,
 CONSTRAINT [PK_TaskExecutionInstance] PRIMARY KEY CLUSTERED 
(
	[TaskExecutionInstanceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [log].[ApplicationExecutionError]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [log].[ApplicationExecutionError](
	[ApplicationErrorID] [int] IDENTITY(1,1) NOT NULL,
	[ApplicationExecutionInstanceID] [int] NOT NULL,
	[ErrorCode] [int] NOT NULL,
	[ErrorDescription] [ntext] NOT NULL,
	[ErrorDateTime] [datetime] NOT NULL,
	[SourceName] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_ApplicationExecutionError] PRIMARY KEY CLUSTERED 
(
	[ApplicationErrorID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [log].[TaskExecutionError]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [log].[TaskExecutionError](
	[TaskErrorID] [int] IDENTITY(1,1) NOT NULL,
	[TaskExecutionInstanceID] [int] NOT NULL,
	[ErrorCode] [int] NOT NULL,
	[ErrorDescription] [ntext] NOT NULL,
	[ErrorDateTime] [datetime] NOT NULL,
	[SourceName] [nvarchar](255) NOT NULL,
 CONSTRAINT [PK_TaskExecutionError] PRIMARY KEY CLUSTERED 
(
	[TaskErrorID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [log].[TaskExecutionVariableLog]    Script Date: 4/18/2013 9:52:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [log].[TaskExecutionVariableLog](
	[VariableLogID] [int] IDENTITY(1,1) NOT NULL,
	[TaskExecutionInstanceID] [int] NOT NULL,
	[VariableName] [nvarchar](255) NOT NULL,
	[VariableValue] [ntext] NULL,
	[LoggedDateTime] [datetime] NOT NULL,
 CONSTRAINT [PK_TaskExecutionVariableLog] PRIMARY KEY CLUSTERED 
(
	[VariableLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
ALTER TABLE [config].[Application] ADD  CONSTRAINT [DF_Application_IsDisabled]  DEFAULT ('0') FOR [IsDisabled]
GO
ALTER TABLE [config].[ApplicationSchedule] ADD  CONSTRAINT [DF_ApplicationSchedule_IsDisabled]  DEFAULT ('0') FOR [IsDisabled]
GO
ALTER TABLE [config].[Package] ADD  CONSTRAINT [DF_Package_IsDisabled]  DEFAULT ('0') FOR [IsDisabled]
GO
ALTER TABLE [config].[Task] ADD  CONSTRAINT [DF_Task_IsDisabled]  DEFAULT ('0') FOR [IsDisabled]
GO
ALTER TABLE [dbo].[ApplicationExecutionInstance] ADD  CONSTRAINT [DF_ApplicationExecutionInstance_ExecutionAborted]  DEFAULT ('0') FOR [ExecutionAborted]
GO
ALTER TABLE [config].[ApplicationSchedule]  WITH CHECK ADD  CONSTRAINT [FK_ApplicationSchedule_Application] FOREIGN KEY([ApplicationID])
REFERENCES [config].[Application] ([ApplicationID])
GO
ALTER TABLE [config].[ApplicationSchedule] CHECK CONSTRAINT [FK_ApplicationSchedule_Application]
GO
ALTER TABLE [config].[ApplicationSchedule]  WITH CHECK ADD  CONSTRAINT [FK_ApplicationSchedule_Schedule] FOREIGN KEY([ScheduleID])
REFERENCES [config].[Schedule] ([ScheduleID])
GO
ALTER TABLE [config].[ApplicationSchedule] CHECK CONSTRAINT [FK_ApplicationSchedule_Schedule]
GO
ALTER TABLE [config].[Task]  WITH CHECK ADD  CONSTRAINT [FK_Task_Application] FOREIGN KEY([ApplicationID])
REFERENCES [config].[Application] ([ApplicationID])
GO
ALTER TABLE [config].[Task] CHECK CONSTRAINT [FK_Task_Application]
GO
ALTER TABLE [config].[Task]  WITH CHECK ADD  CONSTRAINT [FK_Task_Package] FOREIGN KEY([PackageID])
REFERENCES [config].[Package] ([PackageID])
GO
ALTER TABLE [config].[Task] CHECK CONSTRAINT [FK_Task_Package]
GO
ALTER TABLE [config].[Task]  WITH CHECK ADD  CONSTRAINT [FK_Task_Task] FOREIGN KEY([PrecendentTaskID])
REFERENCES [config].[Task] ([TaskID])
GO
ALTER TABLE [config].[Task] CHECK CONSTRAINT [FK_Task_Task]
GO
