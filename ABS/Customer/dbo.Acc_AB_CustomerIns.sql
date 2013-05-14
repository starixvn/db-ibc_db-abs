 ALTER PROCEDURE [dbo].[Acc_AB_CustomerIns]	
 	@userid		INT,	
	@username	NVARCHAR(50),
	@punterid	INT,
	@IP			VARCHAR(40),
	@custid		INT = 0 OUTPUT,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Johnson
		Date: 2011-10-31
		DB: DBABS/bodb_ABS
		Task: Insert customer info for ABS
		
		Revisions:
			- 20130121@Johnson: change linked server DB03 to DBPOLICY
			- 20130308@Johnson: fix format log by xml format 
		Parameters Explanation:
			- @userid : id's admin user
			
		Jamie Testing
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
		
	DECLARE @roleid INT, @danger TINYINT, @currency INT, @currency2 INT, @enabled BIT
	
	SELECT @custid = custid, @roleid = roleid, @danger = danger2
	FROM bodb02.dbo.custinfo WITH(NOLOCK) 
	WHERE username = @username
	
	SELECT @enabled = enabled 
	FROM ABPunterCode WITH(NOLOCK)
	WHERE punterid = @punterid 
	
	IF @enabled = 0
	BEGIN
		SELECT @ErrMsg = 'This punter code is currently disabled. Enable before modifying its information.',
		@ErrCode = 100
		RETURN
	END
	
	IF @custid IS NULL OR  @custid = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid username.',
				@ErrCode = 101
		RETURN
	END 
	
	IF @roleid <> 1
	BEGIN
		SELECT @ErrMsg = 'This user is not a member.',
				@ErrCode = 102
			RETURN
	END
	
	IF @danger < 1
	BEGIN
		SELECT @ErrMsg = 'This member is not set dangerous.',
				@ErrCode = 103
		RETURN	
	END
	
	IF EXISTS( SELECT 1 FROM ABCustomer WITH(NOLOCK) WHERE custid = @custid )
	BEGIN
		SELECT @ErrMsg = 'This member exists in system',
				@ErrCode = 104		
		RETURN
	END		
		
	INSERT INTO ABCustomer (punterid , custid, updatedtime)	
	VALUES(@punterid, @custid, GETDATE())
		
	
	IF @@ERROR > 0
	BEGIN
		SELECT @ErrMsg = 'Insert member unsuccessful.',
				@ErrCode = 105
			RETURN
	END
	
	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<Acc_AB_CustomerIns punterid ="' + COALESCE(CAST (@punterid AS VARCHAR(10)),SPACE(1)) + '" ' 
							+ 'username ="' + COALESCE(@username, SPACE(1)) + '" />'							
					
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@Userid = @userid,
		@Custid = @custid,
		@ActionID = 1902,
		@TrackingValue = @LogData,
		@Duration = @duration


GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_CustomerIns] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_CustomerIns] TO [bodbAdminNet]
GO

	