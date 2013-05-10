 ALTER PROCEDURE [dbo].[Acc_AB_PunterGroupUpd]
	@userid		INT,
	@adminID	INT,
	@punterdel	VARCHAR(4000) = '',
	@punterins	VARCHAR(4000) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Johnson
		Date: 20120305
		DB: DBABS/bodb_ABS
		Task: Assign punter code to admin for monitoring
		
		Revisions:
			- 20130121@Johnson: change linked server DB03 to DBPOLICY
			- 20130308@Johnson: fix format log by xml format
		Parameters Explanation:
			- AdminID: id of admin have permission to monitor
			- userid: id of user grant permission
			- punterdel: string of punter ids removed 
			- punterins: string of punter ids inserted
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
	
	IF @punterdel <> ''
	BEGIN
		DELETE ABPunterGroup
		WHERE adminid = @adminID AND punterid IN (SELECT val FROM f_AB_strSplit(@punterdel,','))
		
		IF @@ERROR <> 0
		BEGIN
			SELECT @ErrCode = 100,@ErrMsg = 'Remove punter code unsuccessful.'
			RETURN
		END
	END
	
	IF @punterins <> ''
	BEGIN
		INSERT INTO ABPunterGroup(adminid,punterid)
		SELECT @adminID,val FROM f_AB_strSplit(@punterins,',')
		WHERE val NOT IN (SELECT punterid FROM ABPunterGroup WITH(NOLOCK) WHERE adminID = @adminID)
		
		IF @@ERROR <> 0
		BEGIN
			SELECT @ErrCode = 101,@ErrMsg = 'Assign punter code unsuccessful.'
			RETURN
		END
	END
	
	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<Acc_AB_PunterGroupUpd punterdel ="' + COALESCE(@punterdel,SPACE(1)) + '" ' 
							+ 'punterins ="' + COALESCE(@punterins, SPACE(1)) + '" />'
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@Userid = @userid,
		@Custid = @adminid,
		@ActionID = 1904,
		@TrackingValue = @LogData,
		@Duration = @duration
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_PunterGroupUpd] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_PunterGroupUpd] TO [bodbAdminNet]