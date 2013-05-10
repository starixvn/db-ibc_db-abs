ALTER PROCEDURE [dbo].[Acc_AB_RptSummary_DetailsByLeague]
	@punterids		VARCHAR(4000),
	@leagueids		VARCHAR(4000),
	@fromdate		DATETIME,
	@todate			DATETIME,
	@MoveBetsDay	DATETIME,	
	@bettype		INT
WITH RECOMPILE
AS
	/*
		Created: Johnson
		Date: 09Nov2011
		Task: Get report summary details by league that member bets
		DB: DB054.bodb_ABS
		
		Revisions:
			- 20120210@Johnson: get leagueid
			- 20120702@Johnson: filter by bettype
			- 20121119@Johnson: Get data from ABTransaction_BK/ABMatch_remark_BK if winlostdate <= movebetsday
		Paramters Explanation:
			- @bettype : 0: all bettype
						 1: hdp
						 7: 1st hdp
						 ...
		
	*/
SET NOCOUNT ON
	
	DECLARE @tmpBets TABLE(punterid INT ,transid BIGINT, remark NVARCHAR(1000), leagueid INT, matchid INT, homeid INT, awayid INT, kickofftime DATETIME, bettype INT, 	betteam VARCHAR(10), livehomescore INT, liveawayscore INT,
	liveindicator BIT, statusid INT, stake MONEY, actual_stake MONEY, winlost MONEY, odds SMALLMONEY, hdp1 SMALLMONEY, hdp2 SMALLMONEY, finalhomescore INT, finalawayscore INT)
	
	SELECT @bettype = NULLIF(@bettype,0)
	
	IF @leagueids <> ''	
	BEGIN
		IF @todate > @MoveBetsDay
		BEGIN
			INSERT INTO @tmpBets
			SELECT 
				ab.punterid,
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
				b.actual_stake,
				b.winlost,
				b.odds,
				b.hdp1,
				b.hdp2,
				m.finalhomescore,
				m.finalawayscore
			FROM ABTransaction ab WITH(NOLOCK)
				INNER JOIN bodb02.dbo.bettrans b WITH(NOLOCK, INDEX = IXU_transid) ON ab.transid = b.transid	
				INNER JOIN bodb02.dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid		
			WHERE ab.punterid IN (SELECT val FROM f_AB_strSplit(@punterids, ',')) 			
				AND b.winlostdate BETWEEN @fromdate AND @todate			
				AND m.leagueid IN (SELECT val FROM f_AB_strSplit(@leagueids,','))
				AND b.statusid NOT IN (101,102,103)
				AND ab.bettype = ISNULL(@bettype,ab.bettype)
		END
		
		IF @fromdate <= @MoveBetsDay
		BEGIN
			IF @todate > @MoveBetsDay
				SELECT @todate = @MoveBetsDay
					
			INSERT INTO @tmpBets
			SELECT 
				ab.punterid,
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
				b.actual_stake,
				b.winlost,
				b.odds,
				b.hdp1,
				b.hdp2,
				m.finalhomescore,
				m.finalawayscore
			FROM ABTransaction_BK ab WITH(NOLOCK) 
				INNER JOIN bodb02.dbo.bettrans14 b WITH(NOLOCK) ON ab.transid = b.transid 
				INNER JOIN bodb02.dbo.match14 m WITH(NOLOCK) ON b.matchid = m.matchid 
			WHERE b.winlostdate BETWEEN @fromdate AND @todate 
				AND ab.punterid IN (SELECT val FROM f_AB_strSplit(@punterids, ','))
				AND m.leagueid IN (SELECT val FROM f_AB_strSplit(@leagueids,','))
				AND b.statusid NOT IN (101,102,103)
				AND ab.bettype = ISNULL(@bettype,ab.bettype)
		END
	END
	ELSE
	BEGIN 
		IF @todate > @MoveBetsDay
		BEGIN
			INSERT INTO @tmpBets
			SELECT 
				ab.punterid,
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
				b.actual_stake,
				b.winlost,
				b.odds,
				b.hdp1,
				b.hdp2,
				m.finalhomescore,
				m.finalawayscore
			FROM ABTransaction ab WITH(NOLOCK)
				INNER JOIN bodb02.dbo.bettrans b WITH(NOLOCK, INDEX = IXU_transid) ON ab.transid = b.transid	
				INNER JOIN bodb02.dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid		
			WHERE ab.punterid IN (SELECT val FROM f_AB_strSplit(@punterids, ',')	)	
				AND b.winlostdate BETWEEN @fromdate AND @todate							
				AND b.statusid NOT IN (101,102,103)
				AND ab.bettype = ISNULL(@bettype,ab.bettype)
		END
		
		IF @fromdate <= @MoveBetsDay
		BEGIN
			IF @todate > @MoveBetsDay
				SELECT @todate = @MoveBetsDay
					
			INSERT INTO @tmpBets
			SELECT 
				ab.punterid,
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
				b.actual_stake,
				b.winlost,
				b.odds,
				b.hdp1,
				b.hdp2,
				m.finalhomescore,
				m.finalawayscore
			FROM ABTransaction_BK ab WITH(NOLOCK) 
				INNER JOIN bodb02.dbo.bettrans14 b WITH(NOLOCK) ON ab.transid = b.transid 
				INNER JOIN bodb02.dbo.match14 m WITH(NOLOCK) ON b.matchid = m.matchid 
			WHERE b.winlostdate BETWEEN @fromdate AND @todate 
				AND ab.punterid IN (SELECT val FROM f_AB_strSplit(@punterids, ','))
				AND b.statusid NOT IN (101,102,103)
				AND ab.bettype = ISNULL(@bettype,ab.bettype)
		END
	END
	
	
	SELECT 
		t.punterid,
		code,
		transid,
		remark,		
		leagueid,
		matchid,
		homeid,
		awayid,
		kickofftime,
		bettype,
		betteam,
		livehomescore,
		liveawayscore,
		liveindicator,
		statusid,
		stake,
		CASE WHEN statusid NOT IN (0,1) THEN winlost - actual_stake ELSE 0 END AS totalPL,
		odds,
		hdp1,
		hdp2,
		finalhomescore,
		finalawayscore
	FROM @tmpBets t
		INNER JOIN ABPunterCode p WITH(NOLOCK) ON t.punterid = p.punterid
	ORDER BY kickofftime ASC


GO
GRANT EXECUTE ON [dbo].[Acc_AB_RptSummary_DetailsByLeague] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_RptSummary_DetailsByLeague] TO [vnteam]