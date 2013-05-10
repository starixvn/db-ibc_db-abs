ALTER PROCEDURE [dbo].[Acc_AB_PunterCodeAssignAll]
	@adminID	INT,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(100) = '' OUTPUT
AS
	/*
		Created: Johnson
		Date: 2012-03-12
		DB: DB054.bodb_ABS
		Task: Assign default punter codes to admin after creating new admin successful
		
		Revisions:
		
		Parameter Explanation:
	*/ 
SET NOCOUNT ON 

	INSERT INTO ABPunterGroup (adminID, punterID)
	SELECT @adminID, punterid 
	FROM ABPunterCode WITH(NOLOCK) 
	WHERE enabled = 1
		AND punterid NOT IN (SELECT punterid 
							FROM ABPunterGroup WITH(NOLOCK) 
							WHERE adminID = @adminID)
	
	IF @@ERROR > 0
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Assign default punter code unsuccessful'
		RETURN
	END

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_PunterCodeAssignAll] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_PunterCodeAssignAll] TO [bodbAdminNet]