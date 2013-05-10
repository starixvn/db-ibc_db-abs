ALTER PROCEDURE [dbo].[Acc_AB_RptInstantUpdRemark]
	@transid	BIGINT,
	@remark		NVARCHAR(1000) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Johnson
		Date: 21Oct2011
		Task: Update remark of transaction
		DB: DB054.bodb_ABS
		
		Revisions:
		
		Parameters Explanation:
	*/
SET NOCOUNT ON

	IF NOT EXISTS (SELECT 1 FROM ABTransaction WITH(NOLOCK) WHERE transid = @transid)
	BEGIN
		SELECT @ErrMsg = 'Invalid transaction.',
			@ErrCode = 100
		RETURN
	END
	
	UPDATE ABTransaction WITH(ROWLOCK,UPDLOCK)
	SET remark = @remark
	WHERE transid = @transid
	
	IF @@ERROR > 0
	BEGIN
		SELECT @ErrMsg = 'Update unsuccessful.',
				@ErrCode = 101
		RETURN		
	END	


GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_RptInstantUpdRemark] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_RptInstantUpdRemark] TO [bodbAdminNet]