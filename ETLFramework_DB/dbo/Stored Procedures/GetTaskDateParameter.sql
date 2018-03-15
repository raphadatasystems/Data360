
CREATE PROCEDURE [dbo].[GetTaskDateParameter]
	@TaskExecutionInstanceID int
AS
	DECLARE @TaskID int

	SELECT @TaskID = TaskID
	FROM dbo.TaskExecutionInstance
	WHERE TaskExecutionInstanceID = @TaskExecutionInstanceID

	IF @TaskID > 0
	BEGIN
		SELECT
			convert(varchar(10), a.StartDate, 126),
			convert(varchar(10), a.EndDate, 126)
		FROM config.TaskDateParameter a
		WHERE a.TaskID = (
			SELECT TOP 1 b.TaskID
			FROM dbo.TaskExecutionInstance b
			WHERE b.TaskExecutionInstanceID = @TaskExecutionInstanceID
		)
	END
	ELSE
	BEGIN
		SELECT CONVERT(varchar(10), GetDate(),126), CONVERT(varchar(10), GetDate(),126)
	END