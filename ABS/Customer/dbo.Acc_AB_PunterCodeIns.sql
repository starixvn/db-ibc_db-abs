 ALTER PROCEDURE [dbo].[Acc_AB_PunterCodeIns]
	@userid		INT,
	@PunterCode	VARCHAR(10),	
	@color		VARCHAR(7),		
	@fb_ah		MONEY = 0,
	@fb_ou		MONEY = 0,
	@fb_1x2		MONEY = 0,
	@IP			VARCHAR(40),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(4000) = '' OUTPUT
AS
	/*
		Created: Johnson
		Date: 31Oct2011
		Task: Create punter code for ABS 
		DB: DBABS/bodb_ABS
		
		Revsions:
			- 20120307@Johnson: Assign new punter code to admins have permission
			- 20130121@Johnson: change linked server DB03 to DBPOLICY
			- 20130308@Johnson: fix format log by xml format
		Paramters Explanation:
	*/
SET NOCOUNT ON
	
	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT, 
			@punterid INT
	SET	@startRun = GETDATE()

	--Check permission
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[ABSCustomerManegement]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
		
	IF EXISTS (SELECT 1 FROM ABPunterCode WITH(NOLOCK) WHERE code = @puntercode)
	BEGIN
		SELECT @ErrMsg = 'Punter code is currently used.',
				@ErrCode = 100
		RETURN		
	END
	
	INSERT INTO ABPunterCode (code, color, fb_1, fb_3, enabled, fb_5)
	VALUES (@puntercode, @color, @fb_ah, @fb_ou, 1, @fb_1x2)
	
	IF @@ERROR > 0
	BEGIN
		SELECT @ErrMsg = 'Insert process not successful.',
				@ErrCode = 101
			RETURN
	END
	
	SELECT @punterid = scope_identity()
				
	EXEC Acc_AB_PunterCodeAssign @punterid 
	
	DECLARE @LogData VARCHAR(4000)
	SELECT @LogData = '<Acc_AB_PunterCodeIns code="' + COALESCE(@puntercode,SPACE(1)) + '" ' +
												'color="' + COALESCE(@color, SPACE(1)) + '" ' +
												'fb_1="' + COALESCE(CAST(@fb_ah AS VARCHAR(30)),SPACE(1)) + '" ' +
												'fb_3="' + COALESCE(CAST(@fb_ou AS VARCHAR(30)),SPACE(1)) + '" ' +
												'fb_5="' + COALESCE(CAST(@fb_1x2 AS VARCHAR(30)),SPACE(1)) + '" ' +
												'ip="' + COALESCE(@ip, SPACE(1)) + '" />'
	
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@Userid = @userid,	
		@ActionID = 1900,
		@TrackingValue = @LogData,
		@Duration = @duration
	
	
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_PunterCodeIns] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_PunterCodeIns] TO [bodbAdminNet]
	