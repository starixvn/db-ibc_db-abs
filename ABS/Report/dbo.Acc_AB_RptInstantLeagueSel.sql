ALTER PROCEDURE [dbo].[Acc_AB_RptInstantLeagueSel]
	@adminID		INT,
	@winlostdate	DATETIME,
	@movebetsday	DATETIME
WITH RECOMPILE
AS
	/*
		Created: Johnson
		Date: 19Oct2011
		Task: Get leagues which have ABD member place bets on that date
		DB: DB054.bodb_ABS
		
		Revisions:
			- 20120306@Johnson: filter by admin monitoring
			- 20120426@Jamie:Optimze WHERE condition 
			- 20121119@Johnson: Get data from ABTransaction_BK if winlostdate <= movebetsday
		Parameters Explanation:
			- @adminID : id of admin is monitoring
	*/
SET NOCOUNT ON
	DECLARE	@todate DATETIME 
	SELECT	@todate = DATEADD(s,-1, DATEADD(d, 1, @winlostdate))
	
	IF @winlostdate > @movebetsday
	BEGIN 
		SELECT	DISTINCT m.leagueid
		FROM	ABPunterGroup pg WITH(NOLOCK) 
				INNER JOIN ABTransaction ab WITH(NOLOCK) ON pg.punterid = ab.punterid
				INNER JOIN bodb02.dbo.bettrans b WITH(NOLOCK) ON ab.transid = b.transid
				INNER JOIN bodb02.dbo.Match m WITH (NOLOCK) ON m.matchid = b.matchid			
		WHERE	pg.adminID = @adminID 
				AND b.bettype IN (1,7,3,8,5,15)
				AND m.kickofftime BETWEEN @winlostdate AND @todate
	END		  
	ELSE
	BEGIN		
		SELECT	DISTINCT m.leagueid
		FROM	ABPunterGroup pg WITH(NOLOCK) 
				INNER JOIN ABTransaction_BK ab WITH(NOLOCK) ON pg.punterid = ab.punterid
				INNER JOIN bodb02.dbo.bettrans14 b WITH(NOLOCK) ON ab.transid = b.transid
				INNER JOIN bodb02.dbo.match14 m WITH(NOLOCK) ON m.matchid = b.matchid
		WHERE	pg.adminID = @adminID 
				AND b.bettype IN (1,7,3,8,5,15)
				AND m.kickofftime BETWEEN @winlostdate AND @todate
	END
GO
GRANT EXECUTE ON [dbo].[Acc_AB_RptInstantLeagueSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_RptInstantLeagueSel] TO [vnteam]