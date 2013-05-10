 ALTER PROCEDURE [dbo].[Acc_AB_RptInstantPunterSel]
	@adminID	INT,
	@color VARCHAR(30) = ''
AS	
	/*
		Created: Johnson
		Date: 20Oct2011
		Task: Get list punter codes active
		DB: DB054.bodb_ABS
		
		Revisions:
			- 20120306@Johnson: get punter code by admin user 
		Parameters Explanation:
	*/
SET NOCOUNT ON

	IF @color = ''
		SET @color = NULL
		
	SELECT p.punterid,
		p.code,
		p.color
	FROM ABPunterGroup pg WITH(NOLOCK) 
		INNER JOIN ABPunterCode p WITH(NOLOCK) ON pg.punterid = p.punterid
	WHERE pg.adminID = @adminID AND p.color = ISNULL(@color,color)	
	ORDER BY code ASC
	



GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_RptInstantPunterSel] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_RptInstantPunterSel] TO [bodbAdminNet]