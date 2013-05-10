 ALTER PROCEDURE [dbo].[Acc_AB_CustomerDel]
	@userid		INT,
	@punterid	INT,
	@custids	VARCHAR(1000),	
	@Ip			VARCHAR(40),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Johnson
		Date: 2011-11-01
		Task: Delete member 
		DB: DBABS/bodb_ABS
		
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
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[ABSCustomerManegement]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
		
	IF (SELECT 1 FROM ABPunterCode WITH(NOLOCK) WHERE punterid = @punterid AND enabled = 0) = 1
	BEGIN
		SELECT @ErrMsg = 'This punter code is currently disabled. Enable before modifying its information.',
				@ErrCode = 100
		RETURN
	END
	
	DELETE ABCustomer 
	WHERE custid IN (SELECT val FROM f_AB_strSplit(@custids,','))
		AND punterid = @punterid

	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	DECLARE @LogData VARCHAR(4000)
	
	SELECT @LogData = '<Acc_AB_CustomerDel custids="' + COALESCE(@custids ,SPACE(1)) + '" '							
							+ 'ip="' + COALESCE(@ip , SPACE(1)) + '" />'
							
		
	 EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@Userid = @userid,		
		@ActionID = 1903,
		@TrackingValue = @LogData,
		@Duration = @duration
	

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_CustomerDel] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_CustomerDel] TO [bodbAdminNet]
GO
