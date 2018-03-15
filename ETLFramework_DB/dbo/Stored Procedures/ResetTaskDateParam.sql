
CREATE PROCEDURE [dbo].[ResetTaskDateParam]
	@TaskExecutionInstanceID int
AS
	SET NOCOUNT ON;

	DECLARE @NextStartDate DATE
	DECLARE @NextEndDate DATE
	DECLARE @CurrentStartDate DATE
	DECLARE @CurrentEndDate DATE
	DECLARE @TaskID INT
	DECLARE @ShiftInterval INT
BEGIN
	SELECT
		@TaskID = a.TaskID,
		@CurrentStartDate = a.StartDate,
		@CurrentEndDate = a.EndDate
	FROM config.TaskDateParameter a
	WHERE a.TaskID = (
		SELECT b.TaskID
		FROM dbo.TaskExecutionInstance b
		WHERE b.TaskExecutionInstanceID = @TaskExecutionInstanceID
	)

	IF @TaskID > 0
	BEGIN
		IF DATENAME(dw, @CurrentEndDate) = 'Friday'
		BEGIN
			SET @ShiftInterval = 3
		END
		ELSE
		BEGIN
			SET @ShiftInterval = 1
		END
		
		SET @NextStartDate = DATEADD(d, @ShiftInterval, @CurrentStartDate)
		SET @NextEndDate = DATEADD(d, @ShiftInterval, @CurrentEndDate)

		UPDATE config.TaskDateParameter
		SET
			StartDate = @NextStartDate,
			EndDate = @NextEndDate
		WHERE TaskID = @TaskID
	END
END