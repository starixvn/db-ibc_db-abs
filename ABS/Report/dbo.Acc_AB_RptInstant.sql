 ALTER PROCEDURE [dbo].[Acc_AB_RptInstant]
	 @adminid		INT,
	 @kickoffdate	DATETIME,	 	 
	 @kickofftime	VARCHAR(500) = '',
	 @eventdate		DATETIME = '',
	 @movebetsday	DATETIME,
	 @leagueids		VARCHAR(4000) = '',
	 @punterids		VARCHAR(4000) = '',	
	 @matchids		VARCHAR(100) = '',
	 @homeid		INT = 0,
	 @awayid		INT = 0,
	 @eventstatus	BIT = 0,	
	 @bettype		TINYINT = 0,
	 @debug			BIT = 0
WITH RECOMPILE
AS	
	/*
		Created: Johnson
		Date: 20Oct2011
		Task: Get Details tickets on that the time selected
		DB: DB054.bodb_ABS
		
		Revisions:
			- 20120214@Johnson: get info of punter code
			- 20120306@Johnson: get report by admin id
			- 20120703@Johnson: get matchcode
			- 20121119@Johnson: Get data from ABTransaction_BK/ABMatch_remark_BK if winlostdate <= movebetsday
			- 20121227@Johnson: get betteam from ABMatch_Remark
		Parameters Explanation:
			- @leagues = '': All league
			- @punterids = '': All members	
			- @eventstatus = 0 running, 1: finished matches
			- @kickoffdate : the date is selected , ex: '2011-10-20 00:00:00'
			- @kickofftime : array times are selected ex: '0,1,5,6,23' and '' : all time on that date	
			- @mintrans : filter from transid is remarked		
			- @bettype - 0 :bettype 1,3,5,7,8,15
						1: bettype 1,3,5
						2: bettype 7,8,15
	 */
SET NOCOUNT ON
		
	DECLARE @sql	NVARCHAR(MAX)
	
	
	SELECT @sql = 
'SELECT 
	punterid,
	code,
	color,
	leagueid,
	matchid,
	matchcode,
	matchcode2,
	homeid,
	awayid,
	kickofftime,
	finalhomescore,
	finalawayscore,
	livehomescore,
	liveawayscore,
	transid,	
	bettype,
	betteam,
	liveindicator,
	transdate,		
	statusid,
	hdp1,
	hdp2,
	odds,
	stake,
	winlost,
	tstamp,
	remark,
	eod,
	ehd,
	betteam2
FROM(
	SELECT 
	p.punterid,
	p.code,
	p.color,
	m.leagueid,
	m.matchid,
	CONVERT(VARCHAR(10),m.leagueid)+' + ''',''' + '+CONVERT(VARCHAR(10),m.homeid)+' + ''',''' +  '+CONVERT(VARCHAR(10),m.awayid)+' + ''',''' + '+CONVERT(VARCHAR(10),m.eventdate,120) as matchcode,
	m.matchcode as matchcode2,
	m.homeid,
	m.awayid,
	m.kickofftime,
	m.finalhomescore,
	m.finalawayscore,
	b.livehomescore,
	b.liveawayscore,
	b.transid,	
	b.bettype,
	b.betteam,
	b.liveindicator,
	b.transdate,		
	CASE WHEN b.statusid = 0 AND b.SecAcceptFlag = 1 AND b.checktime > CURRENT_TIMESTAMP THEN 1 ELSE b.statusid END as statusid,
	b.hdp1,
	b.hdp2,
	b.odds,
	b.stake,
	CASE WHEN b.statusid NOT IN (0,1) THEN winlost - actual_stake ELSE 0 END AS winlost,
	b.tstamp,
	ab.remark,
	rm.odds as eod,
	rm.hdp as ehd,
	rm.betteam as betteam2
FROM ABPunterGroup pg WITH(NOLOCK)
	INNER JOIN ABPunterCode p WITH(NOLOCK) ON pg.punterid = p.punterid 	
	INNER JOIN ABTransaction ab WITH(NOLOCK) ON p.punterid = ab.punterid
	INNER JOIN bodb02.dbo.bettrans b WITH(NOLOCK, INDEX = IXU_transid) ON ab.transid = b.transid	
	INNER JOIN bodb02.dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
	LEFT JOIN ABMatch_Remark rm WITH(NOLOCK) ON b.matchid = rm.matchid AND b.bettype = rm.bettype
WHERE CONVERT(VARCHAR(10),m.kickofftime,120) = '''+ CONVERT(VARCHAR(10),@kickoffdate,120) + '''' +
	CASE WHEN @homeid > 0 AND @awayid > 0 THEN '
	AND m.homeid =' + CONVERT(VARCHAR(10),@homeid) + '
	AND m.awayid =' + CONVERT(VARCHAR(10),@awayid) + '
	AND m.eventdate=''' + CONVERT(VARCHAR(10),@eventdate,120) + ''''  ELSE CASE WHEN @matchids <> '' THEN '
	AND m.matchid IN (' + @matchids + ')' ELSE '' END END +'
	AND pg.adminID = ' + CONVERT(VARCHAR(10),@adminID) + 
	CASE WHEN @kickofftime <> '' THEN '
	AND DATEPART(hh,m.kickofftime) IN (' + @kickofftime +')'  ELSE '' END +
	CASE WHEN @punterids <> '' THEN '
	AND p.punterid IN (' + @punterids + ') ' ELSE '' END +
	CASE WHEN @bettype = 1 THEN '
		AND b.bettype IN (1,3,5)'
		 WHEN @bettype = 2 THEN '
		 AND b.bettype IN (7,8,15)' ELSE '' END + 
	CASE WHEN @eventstatus = 1 THEN '
	AND b.statusid IN (111,112,113)' ELSE '' END + '
	AND b.ruben ='+ CONVERT(VARCHAR(1),@eventstatus)+
	CASE WHEN @leagueids <> '' THEN '
	AND m.leagueid IN (' + @leagueids +') ' ELSE '' END + 
	CASE WHEN @eventstatus = 1 AND @kickoffdate <= @movebetsday THEN '
UNION ALL
	SELECT 
	p.punterid,
	p.code,
	p.color,
	m.leagueid,
	m.matchid,
	CONVERT(VARCHAR(10),m.leagueid)+' + ''',''' + '+CONVERT(VARCHAR(10),m.homeid)+' + ''',''' +  '+CONVERT(VARCHAR(10),m.awayid)+' + ''',''' + '+CONVERT(VARCHAR(10),m.eventdate,120) as matchcode,
	m.matchcode as matchcode2,
	m.homeid,
	m.awayid,
	m.kickofftime,
	m.finalhomescore,
	m.finalawayscore,
	b.livehomescore,
	b.liveawayscore,
	b.transid,	
	b.bettype,
	b.betteam,
	b.liveindicator,
	b.transdate,		
	b.statusid,
	b.hdp1,
	b.hdp2,
	b.odds,
	b.stake,
	winlost - actual_stake AS winlost,
	b.tstamp,
	ab.remark,
	rm.odds as eod,
	rm.hdp as ehd,
	rm.betteam as betteam2
FROM ABPunterGroup pg WITH(NOLOCK) 
	INNER JOIN ABPunterCode p WITH(NOLOCK) ON pg.punterid = p.punterid
	INNER JOIN ABTransaction_BK ab WITH(NOLOCK) ON p.punterid = ab.punterid
	INNER JOIN bodb02.dbo.bettrans14 b WITH(NOLOCK) ON ab.transid = b.transid	
	INNER JOIN bodb02.dbo.match14 m WITH(NOLOCK) ON b.matchid = m.matchid
	LEFT JOIN ABMatch_Remark_BK rm WITH(NOLOCK) ON b.matchid = rm.matchid AND b.bettype = rm.bettype
WHERE CONVERT(VARCHAR(10),m.kickofftime,120) = '''+ CONVERT(VARCHAR(10),@kickoffdate,120) + '''' +
	CASE WHEN @homeid > 0 AND @awayid > 0 THEN '
	AND m.homeid =' + CONVERT(VARCHAR(10),@homeid) + '
	AND m.awayid =' + CONVERT(VARCHAR(10),@awayid) +'
	AND m.eventdate=''' + CONVERT(VARCHAR(10),@eventdate,120) + ''''  ELSE CASE WHEN @matchids <> ''  THEN '
	AND m.matchid IN (' + @matchids + ')' ELSE '' END END+ 	
	CASE WHEN @kickofftime <> '' THEN '
	AND DATEPART(hh,m.kickofftime) IN (' + @kickofftime +')'  ELSE '' END +'
	AND pg.adminID = ' + CONVERT(VARCHAR(10),@adminID) +
	CASE WHEN @punterids <> '' THEN '
	AND p.punterid IN (' + @punterids + ') ' ELSE '' END +
	CASE WHEN @bettype = 1 THEN '
		AND b.bettype IN (1,3,5)'
		 WHEN @bettype = 2 THEN '
		 AND b.bettype IN (7,8,15)' ELSE '' END + 
	CASE WHEN @eventstatus = 1 THEN '
	AND b.statusid IN (111,112,113)' ELSE '' END + '
	AND b.ruben ='+ CONVERT(VARCHAR(1),@eventstatus)+
	CASE WHEN @leagueids <> '' THEN '
	AND m.leagueid IN (' + @leagueids +') ' ELSE '' END
	ELSE '' END +') r
ORDER BY  tstamp DESC,kickofftime ASC, leagueid, matchid, homeid, awayid, transdate DESC, punterid, bettype, betteam' 
	
	IF @debug = 1 
		PRINT @sql
		
	EXEC sp_executesql @sql
	
	-- get to check total turnover exceeded max full bet turnover or not	

	SELECT p. punterid, code, color, fb_1 as fb_ah, fb_3 as fb_ou, fb_5 as fb_1x2
	FROM ABPunterCode p WITH(NOLOCK)
		INNER JOIN ABPunterGroup pg WITH(NOLOCK) ON p.punterid = pg.punterid
	WHERE pg.adminID = @adminID
			

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_RptInstant] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_RptInstant] TO [bodbAdminNet]
