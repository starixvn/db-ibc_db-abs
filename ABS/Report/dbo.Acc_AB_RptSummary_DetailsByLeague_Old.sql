 ALTER PROCEDURE [dbo].[Acc_AB_RptSummary_DetailsByLeague_Old]
	@punterids		VARCHAR(4000),
	@leagueids		VARCHAR(4000),
	@fromdate		DATETIME,
	@todate			DATETIME,
	@bettype		INT,
	@ABServer		VARCHAR(50) = 'DBABS'	
AS
	/*
		Created: Johnson
		Date: 12Dec2011
		Task: Get report summary details by league that member bets
		DB: DBARC/bodb_Archive
		
		Revisions:
			- 20120210@Johnson: get leagueid			
			- 20120702@Johnson: filter by bettype
			- 20121017@Johnson: add param @ABServer to config linked sever
			- 20130121@Johnson: Move sp from DB06.BODB02 to DBARC.bodb_Archive
		Paramters Explanation:
			- @bettype : 0: all bettype
						 1: hdp
						 7: 1st hdp
						 ...
			
	*/
SET NOCOUNT ON

	DECLARE @sql NVARCHAR(4000)
	
	SELECT @sql = '
	SELECT
		ab.punterid,
		p.code,
		b.transid,
		ab.remark,	
		m.leagueid,			
		m.matchid,
		m.homeid,
		m.awayid,
		m.kickofftime,
		b.bettype,
		b.betteam,
		b.livehomescore,
		b.liveawayscore,
		b.liveindicator,
		b.statusid,
		b.stake,	
		b.winlost - b.actual_stake as totalPL,
		b.odds,
		b.hdp1,
		b.hdp2,
		m.finalhomescore,
		m.finalawayscore
	FROM ' + @ABServer + '.bodb_ABS.dbo.ABPunterCode p WITH(NOLOCK) 
		INNER JOIN ' + @ABServer + '.bodb_ABS.dbo.ABTransaction_BK ab WITH(NOLOCK) ON ab.punterid = p.punterid
		INNER JOIN dbo.bettrans_bk b WITH(NOLOCK, INDEX= IX_transid) ON ab.transid = b.transid 
		INNER JOIN dbo.match_bk m WITH(NOLOCK) ON b.matchid = m.matchid 
	WHERE 
		b.winlostdate BETWEEN''' +  CONVERT(VARCHAR(10),@fromdate,120) + ''' AND '''+  CONVERT(VARCHAR(10),@todate,120) +'''
		AND ab.punterid IN (' +  @punterids + ')' +
		CASE WHEN @leagueids <> '' THEN 'AND m.leagueid IN (' + @leagueids + ')' ELSE '' END +
		'AND b.statusid NOT IN (101,102,103)'+
		CASE WHEN @bettype <> 0 THEN '
		AND ab.bettype = ' + CONVERT(VARCHAR(10),@bettype) ELSE '' END + '
	ORDER BY kickofftime ASC	
		'
		
		
		EXEC sp_executesql @sql
		
		
		
GO
GRANT EXECUTE ON [dbo].[Acc_AB_RptSummary_DetailsByLeague_Old] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_RptSummary_DetailsByLeague_Old] TO [vnteam]
		