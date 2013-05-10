ALTER PROCEDURE [dbo].[Acc_AB_ResultLeagueSel]
	@winlostdate	DATETIME,
	@movebetsday	DATETIME
	AS
	/*
		Created: Johnson
		Date: 22Nov2011
		Task: Get league info
		DB: DB054.bodb_ABS
		
		Revisions:
			- 20121119@Johnson: Get data from ABMatch_remark_BK if winlostdate <= movebetsday
		Parameters Explanation:
	*/ 
SET NOCOUNT ON
	
	IF @winlostdate > @movebetsday	
		SELECT DISTINCT m.leagueid, m.sporttype
		FROM ABMatch_Remark rm WITH(NOLOCK)
			INNER JOIN bodb02.dbo.match m WITH(NOLOCK) ON m.matchid = rm.matchid			
		WHERE CONVERT(VARCHAR(10),m.kickofftime,120) = @winlostdate
		ORDER BY m.sporttype
	ELSE
		SELECT DISTINCT m.leagueid, m.sporttype
		FROM ABMatch_Remark_BK rm WITH(NOLOCK)
			INNER JOIN bodb02.dbo.match14 m WITH(NOLOCK) ON m.matchid = rm.matchid			
		WHERE CONVERT(VARCHAR(10),m.kickofftime,120) = @winlostdate
		ORDER BY m.sporttype
		
GO
GRANT EXECUTE ON [dbo].[Acc_AB_ResultLeagueSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_ResultLeagueSel] TO [vnteam]