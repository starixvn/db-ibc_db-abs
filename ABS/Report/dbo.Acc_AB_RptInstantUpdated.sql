USE [bodb_ABS]
GO
/****** Object:  StoredProcedure [dbo].[Acc_AB_RptInstantUpdated]    Script Date: 11/21/2012 06:07:27 ******/
ALTER PROCEDURE [dbo].[Acc_AB_RptInstantUpdated]
	 @adminID		INT,
	 @kickoffdate	DATETIME,
	 @kickofftime	VARCHAR(500) = '',
	 @eventdate		DATETIME = '',
	 @leagueids		VARCHAR(4000) = '',
	 @punterids		VARCHAR(4000) = '',	
	 @matchids		VARCHAR(100) = '',	
	 @homeid		INT = 0,
	 @awayid		INT = 0,
	 @bettype		TINYINT = 0,
	 @mintstamp		BINARY(8) = 0x,
	 @debug			BIT = 0
AS	
	/*
		Created: Johnson
		Date: 21Nov2011
		Task: Get details tickets changed after the last timestamp record
		DB: DB052.bodb_ABS
		
		Revisions:			
			-20120306@Johnson: get report by admin
			- 20120314@Johnson: optimize get report
			- 20120703@Johnson: get matchcode
			- 20120829@Johnson: check if no data in @tmpBettrans return
			- 20121112@Viet: revise SP
			- 20121122@Jamie: Change database and function name to bodb_ABS
			- 20121227@Johnson: Get betteam from ABMatch_Remark
		Parameters Explanation:
			- @leagues = '': All league
			- @punterids = '': All members				
			- @kickoffdate : the date is selected , ex: '2011-10-20 00:00:00'
			- @kickofftime : array times are selected ex: '0,1,5,6,23' and '' : all time on that date	
			- @mintrans : filter from transid is remarked	
			- @maxtrans: max transid is filtered
			- @mintstamp: last timestamp is remarked	
			- @bettype - 0: bettype 1,3,5,7,8,15
						1: bettype 1,3,5
						2: bettype 7,8,15
	 */
SET NOCOUNT ON

	SET @eventdate = DATEADD(dd, DATEDIFF(dd, 0, @kickoffdate), 0)

	;WITH S as (
		SELECT
			ab.transid,
			p.punterid,
			p.code,
			p.color,
			m.leagueid,
			m.matchid,
			CONVERT(VARCHAR(10),m.leagueid)+','+CONVERT(VARCHAR(10),m.homeid)+','+CONVERT(VARCHAR(10),m.awayid)+','+CONVERT(VARCHAR(10),m.eventdate,120) as matchcode,
			m.matchcode as matchcode2,
			m.homeid,
			m.awayid,
			m.kickofftime,
			m.finalhomescore,
			m.finalawayscore,		
			ab.remark,
			rm.odds as eod,
			rm.hdp as ehd,
			rm.betteam as betteam2
		FROM bodb_abs.dbo.ABTransaction ab with(nolock)
			INNER JOIN dbo.ABPunterGroup pg with(nolock) ON pg.punterid = ab.punterid
			INNER JOIN dbo.ABPunterCode p ON pg.punterid = p.punterid 
			LEFT JOIN bodb_abs.dbo.ABMatch_Remark rm with(nolock) ON ab.matchid = rm.matchid and ab.bettype = rm.bettype
			INNER JOIN bodb02.dbo.match m with(nolock) on ab.matchid = m.matchid
		WHERE m.eventdate = @eventdate
			and pg.adminid = @adminID
			and m.homeid = case @homeid when 0 then m.homeid else @homeid end
			and m.awayid = case @awayid when 0 then m.awayid else @awayid end
			and case 
					when @matchids = '' then 1 
					when m.matchid in (select val from dbo.f_AB_strSplit(@matchids, ',')) then 1 
					else 0 
				end = 1
			and case 
					when @punterids = '' then 1
					when p.punterid in (select val from dbo.f_AB_strSplit(@punterids, ',')) then 1
					else 0
				end = 1
			and case 
					when @bettype = 0 then 1		
					when @bettype = 1 and ab.bettype in (1,3,5) then 1
					when @bettype = 2 and ab.bettype in (7,8,15) then 1
					else 0
				end	= 1	
			and case 
					when @leagueids = '' then 1 
					when m.leagueid in (select val from dbo.f_AB_strSplit(@leagueids, ',')) then 1 
					else 0 
				end = 1		
			and case 
					when @kickofftime = '' then 1 
					when DATEPART(hh,m.kickofftime) in (select val from dbo.f_AB_strSplit(@kickofftime, ',')) then 1 
					else 0 
				end = 1		
	)
	SELECT 
		s.punterid
		,s.code
		,s.color
		,s.leagueid
		,s.matchid
		,s.matchcode
		,s.matchcode2
		,s.homeid
		,s.awayid
		,s.kickofftime
		,s.finalhomescore
		,s.finalawayscore
		,s.remark
		,b.livehomescore
		,b.liveawayscore
		,b.transid
		,b.bettype
		,b.betteam
		,b.liveindicator
		,b.transdate	
		,CASE WHEN b.statusid = 0 AND b.SecAcceptFlag = 1 AND b.checktime > CURRENT_TIMESTAMP THEN 1 ELSE b.statusid END as statusid
		,b.hdp1
		,b.hdp2
		,b.odds
		,b.stake
		,CASE WHEN b.statusid NOT IN (0,1) THEN winlost - actual_stake ELSE 0 END AS winlost
		,b.tstamp		
		,s.eod
		,s.ehd	
		,s.betteam2	
	FROM bodb02.dbo.bettrans b with(nolock, index=IXU_transid)
		INNER JOIN S on b.transid = s.transid
	WHERE b.tstamp > @mintstamp
	ORDER BY b.tstamp DESC, s.kickofftime ASC, s.leagueid, s.matchid, s.homeid, s.awayid, b.transdate DESC, s.punterid, b.bettype, b.betteam

/*
----Delay for 1 seconds
--WAITFOR DELAY '000:00:02'		
	DECLARE @sql	NVARCHAR(MAX)
	
	SELECT @sql = 
'DECLARE @tmpBettrans TABLE (transid BIGINT, remark nvarchar(100), punterid int, hdp smallmoney, 
				odds smallmoney, code varchar(10), color varchar(7))
				
declare @maxActiveID bigint
select @maxActiveID = max(transid) from ABTransaction_ACTIVE with(nolock)

INSERT INTO @tmpBettrans (transid, remark, punterid, hdp, odds, code, color)
SELECT 
	b.transid, ab.remark, ab.punterid, rm.hdp, rm.odds, p.code, p.color
FROM ABPunterGroup pg WITH(NOLOCK) 
	INNER JOIN ABPunterCode p WITH(NOLOCK) ON pg.punterid = p.punterid 
	INNER JOIN (
			select transid, punterid, remark from ABTransaction_ACTIVE with(nolock)
			UNION
			select transid, punterid, remark from ABTransaction with(nolock) where transid > @maxActiveID
		) ab ON p.punterid = ab.punterid
	INNER JOIN bettrans b WITH(NOLOCK) ON ab.transid = b.transid	
	INNER JOIN match m WITH(NOLOCK) ON b.matchid = m.matchid
	LEFT JOIN ABMatch_Remark rm WITH(NOLOCK) ON b.matchid = rm.matchid AND b.bettype = rm.bettype
WHERE b.winlostdate = '''+ CONVERT(VARCHAR(10),@kickoffdate,120) + '''' + '
	AND b.tstamp > ' + sys.fn_sqlvarbasetostr(@mintstamp)+ ' ' +
	CASE WHEN @homeid > 0 AND @awayid > 0 THEN '
	AND m.homeid =' + CONVERT(VARCHAR(10),@homeid) + '
	AND m.awayid =' + CONVERT(VARCHAR(10),@awayid) + '
	AND m.eventdate='''+ CONVERT(VARCHAR(10),@eventdate,120) + '''' ELSE 
		CASE WHEN @matchids <> '' THEN '
	AND m.matchid IN ( ' + @matchids +' ) ' ELSE '' END END +
	CASE WHEN @kickofftime <> '' THEN '
	AND DATEPART(hh,m.kickofftime) IN (' + @kickofftime +')'  ELSE '' END +'
	AND pg.adminID = ' + CONVERT(VARCHAR(10),@adminID) + 
	CASE WHEN @punterids <> '' THEN '
	AND p.punterid IN (' + @punterids + ') ' ELSE '' END +
	CASE WHEN @bettype = 1 THEN '
		AND b.bettype IN (1,3,5)'
		 WHEN @bettype = 2 THEN '
		 AND b.bettype IN (7,8,15)' ELSE '' END + 
	CASE WHEN @leagueids <> '' THEN '
	AND m.leagueid IN (' + @leagueids +') ' ELSE '' END +'

IF @@ROWCOUNT = 0
	RETURN

SELECT 
	t.punterid,
	t.code,
	t.color,
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
	t.remark,
	t.odds as eod,
	t.hdp as ehd
FROM @tmpBettrans t	
	INNER JOIN bettrans b WITH(NOLOCK, INDEX = IXU_transid) ON t.transid = b.transid	
	INNER JOIN match m WITH(NOLOCK) ON b.matchid = m.matchid	
ORDER BY b.tstamp DESC, m.kickofftime ASC, m.leagueid, m.matchid, m.homeid, m.awayid, b.transdate DESC, t.punterid, b.bettype, b.betteam'

	
	IF @debug = 1 
		PRINT @sql
		
	EXEC sp_executesql @sql




*/

GO
GRANT EXECUTE ON [dbo].[Acc_AB_RptInstantUpdated] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_RptInstantUpdated] TO [vnteam] AS [dbo]