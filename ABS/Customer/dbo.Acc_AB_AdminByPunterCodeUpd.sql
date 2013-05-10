 ALTER PROCEDURE [dbo].[Acc_AB_AdminByPunterCodeUpd]
	 @userid  INT, 
	 @punterid INT,
	 @adminDel VARCHAR(4000),
	 @adminIns VARCHAR(4000),
	 @ErrCode INT= 0 OUTPUT,
	 @ErrMsg  VARCHAR(1000) = '' OUTPUT
 AS
	/*
		Created: Johnson
		Date: 2012-03-09
		DB: DBABS/bodb_ABS
		Task: Update admins assigned to punter code
		
		Revisions:
			- 20130121@Johnson: change linked server DB03 to DBPOLICY
			- 20130308@Johnson: fix format log by xml format 
		Parameters Explanation:
	*/
SET NOCOUNT ON

	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()

	--Check permission
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[ABSAdminUserControl]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
		
	IF EXISTS(SELECT 1 FROM ABPunterCode WITH(NOLOCK) WHERE punterid = @punterid AND enabled = 0)
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'This punter code is disabled'
		RETURN
	END
		
	IF @adminDel <> ''
	BEGIN 
		DELETE ABPunterGroup
		WHERE punterid = @punterid 
			AND adminID IN (SELECT val FROM f_AB_strSplit(@adminDel,','))
			
		IF @@ERROR > 0
		BEGIN
			SELECT @ErrCode = 101,@ErrMsg = 'Update process unsucessful'
			RETURN
		END
	END
	
	IF @adminIns <> ''
	BEGIN
		INSERT INTO ABPunterGroup (adminID, punterid)
		SELECT val, @punterid
		FROM f_AB_strSplit(@adminIns,',')
		WHERE val NOT IN (SELECT adminID 
						FROM ABPunterGroup WITH(NOLOCK) 
						WHERE punterid = @punterid
					)
					
		IF @@ERROR > 0
		BEGIN
			SELECT @ErrCode = 102,@ErrMsg = 'Update process unsucessful'
			RETURN
		END
	END
	
	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<Acc_AB_AdminByPunterCodeUpd punterid="' + COALESCE(CAST (@punterid AS VARCHAR(10)),SPACE(1)) + '" ' 
							+ 'adminDel="' + COALESCE(@adminDel, SPACE(1)) + '" '
							+ 'adminIns="' + COALESCE(@adminIns, SPACE(1)) + '" />'
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@Userid = @userid,		
		@ActionID = 1905,
		@TrackingValue = @LogData,
		@Duration = @duration
	

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_AdminByPunterCodeUpd] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_AdminByPunterCodeUpd] TO [bodbAdminNet]
	 
	 