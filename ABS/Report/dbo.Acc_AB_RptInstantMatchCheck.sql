ALTER PROCEDURE [dbo].[Acc_AB_RptInstantMatchCheck]
	@fromID		BIGINT,
	@toID		BIGINT,
	@mintstamp	TIMESTAMP = 0x
	AS
	/*
		Created: Johnson
		Date: 21Nov2011
		Task: get info of match changed after last timestamp
		DB: DB054.bodb_ABS
		
		Revisions:
		
		Paramters Explanation:
	*/ 
SET NOCOUNT ON

	SELECT DISTINCT m.matchid, m.tstamp, m.eventstatus, rm.isHTCal
	FROM  ABTransaction ab WITH(NOLOCK)
		INNER JOIN bodb02.dbo.bettrans b WITH(NOLOCK) ON ab.transid = b.transid
		INNER JOIN bodb02.dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
		INNER JOIN bodb02.dbo.match_remark rm WITH(NOLOCK) ON m.matchid = rm.matchid
	WHERE m.matchid BETWEEN @fromID AND @toID
		AND m.tstamp > @mintstamp
	ORDER BY m.tstamp DESC
		
GO
GRANT EXECUTE ON [dbo].[Acc_AB_RptInstantMatchCheck] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_RptInstantMatchCheck] TO [vnteam]