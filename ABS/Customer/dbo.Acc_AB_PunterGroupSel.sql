

ALTER PROCEDURE [dbo].[Acc_AB_PunterGroupSel]
	@adminID	INT
AS
	/*
		Created: Johnson
		Date: 20120307
		Task: get punter code is assigned to admin
		DB: DB054.bodb_ABS
		
		Revisions:
	*/
SET NOCOUNT ON
	
	SELECT p.punterid, p.code , p.color, CASE WHEN pg.punterid IS NOT NULL THEN 1 ELSE 0 END isChecked
	FROM ABPunterCode p WITH(NOLOCK)
		LEFT JOIN (SELECT punterid 
				FROM ABPunterGroup pg WITH(NOLOCK) 
				WHERE adminID = @adminid) pg ON p.punterid = pg.punterid 
	WHERE enabled = 1


GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_PunterGroupSel] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_PunterGroupSel] TO [bodbAdminNet]