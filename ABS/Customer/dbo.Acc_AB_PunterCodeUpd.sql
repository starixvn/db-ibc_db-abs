ALTER PROCEDURE [dbo].[Acc_AB_PunterCodeUpd]
	@userid		INT,
	@punterid	INT,	
	@code		VARCHAR(10),	
	@color		VARCHAR(7),
	@fb_ah		MONEY,
	@fb_ou		MONEY,
	@fb_1x2		MONEY,
	@enabled	BIT,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(1000) = '' OUTPUT
	AS	 
	/*
		Created: Johnson
		Date:31Oct2011
		Task: Update punter code 
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
	
	IF NOT EXISTS(SELECT 1 FROM ABPunterCode WITH(NOLOCK) WHERE punterid = @punterid)
	BEGIN
		SELECT @ErrMsg = 'Punter code not available.',
			@ErrCode = 100
		RETURN
	END
	
	DECLARE @db_code VARCHAR(10), @db_color VARCHAR(30), @db_fb1 MONEY, @db_fb3 MONEY, @db_enabled BIT, @db_fb5 MONEY
	
	SELECT @db_code = code,
			@db_color = color,
			@db_fb1 = fb_1,
			@db_fb3 = fb_3,
			@db_fb5 = fb_5,
			@db_enabled = enabled
	FROM ABPunterCode WITH(NOLOCK)
	WHERE punterid = @punterid
	
	IF @db_color = @color AND @db_fb1 = @fb_ah AND @db_fb3 = @fb_ou AND @db_fb5 = @fb_1x2 AND @db_enabled = @enabled AND @db_code = @code 
		RETURN
	
	IF EXISTS(SELECT 1 FROM ABPunterCode WITH(NOLOCK) WHERE code = @code AND punterid <> @punterid)
	BEGIN
		SELECT @ErrMsg = 'This punter code is currently used.',
			@ErrCode = 101
		RETURN	
	END
	
	UPDATE ABPunterCode
	SET code = @code,
		color = @color,
		fb_1 = @fb_ah,
		fb_3 = @fb_ou,
		fb_5 = @fb_1x2,
		enabled = @enabled
	WHERE punterid = @punterid
		
	IF @@ERROR > 0 
	BEGIN
		SELECT @ErrMsg= 'Update process unsuccessful.',
				@ErrCode = 102
			RETURN
	END
	
	IF @db_enabled <> @enabled 
		UPDATE ABCustomer WITH(UPDLOCK, ROWLOCK)
		SET updatedtime = GETDATE()
		WHERE punterid = @punterid
		
	DECLARE @LogData VARCHAR(4000), @LogData_Old VARCHAR(4000)
		
	SELECT @LogData = '<Acc_AB_PunterCodeUpd punterid="'+ COALESCE(CAST(@punterid AS VARCHAR(10)), SPACE(1)) + '" ' +
										'code="' + COALESCE(@code , SPACE(1)) + '" ' +
										'color="' + COALESCE(@color, SPACE(1)) + '" ' +
										'fb_1="' + COALESCE(CAST(@fb_ah AS VARCHAR(30)), SPACE(1)) + '" ' +
										'fb_3="' + COALESCE(CAST(@fb_ou AS VARCHAR(30)), SPACE(1)) + '" ' +
										'fb_5="' + COALESCE(CAST(@fb_1x2 AS VARCHAR(30)), SPACE(1)) + '" ' +
										'enabled="' + COALESCE(CAST(@enabled AS VARCHAR(1)), SPACE(1)) + '" />' 
	
	SELECT @LogData_Old = '<Acc_AB_PunterCodeUpd punterid="'+ COALESCE(CAST(@punterid AS VARCHAR(10)), SPACE(1)) + '" ' +
										'code="' + COALESCE(@db_code, SPACE(1)) + '" ' +
										'color="' + COALESCE(@db_color, SPACE(1)) + '" ' +
										'fb_1="' + COALESCE(CAST(@db_fb1 AS VARCHAR(30)), SPACE(1)) + '" ' +
										'fb_3="' + COALESCE(CAST(@db_fb3 AS VARCHAR(30)), SPACE(1)) + '" ' +
										'fb_5="' + COALESCE(CAST(@db_fb5 AS VARCHAR(30)), SPACE(1)) + '" ' +
										'enabled="' + COALESCE(CAST(@db_enabled AS VARCHAR(1)), SPACE(1)) + '" />'
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@Userid = @userid,	
		@ActionID = 1901,
		@TrackingValue = @LogData,
		@TrackingValue2 = @LogData_Old,
		@Duration = @duration


GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_PunterCodeUpd] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_PunterCodeUpd] TO [bodbAdminNet]