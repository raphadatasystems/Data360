CREATE PROCEDURE [dbo].[GetValidationScreenID]
	@TaskExecInstanceID int
AS
	SELECT a.TaskID, b.TaskName
	FROM   dbo.TaskExecutionInstance a
		   JOIN config.Task b on a.TaskID = b.TaskID
	WHERE  TaskExecutionInstanceID = @TaskExecInstanceID