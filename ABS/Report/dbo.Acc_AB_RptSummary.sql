 ALTER PROCEDURE [dbo].[Acc_AB_RptSummary]
	@adminID		INT,
	@fromdate		DATETIME,
	@todate			DATETIME,
	@punterids		VARCHAR(4000),
	@MoveBetsDay	DATETIME,
	@BalanceUpDay	DATETIME,
	@bettype		INT
WITH RECOMPILE 
AS
	/*
		Created: Johnson
		Date: 09Nov2011
		Task: Get report summary 		
		DB: DB054.bodb_ABS
		
		Revisions:
			- 20120306@Johnson: get report by admin user
			- 20120702@Johnson: filter by bettype
			- 20120912@Johnson: get data from ABSum_Winloss_Old before balance up date			
		Parameters Explanations:
			- @punterids = '' : All punters
			- @adminid : id of admin
			- @bettype : 0: all bettype
						 1: hdp
						 7: 1st hdp
						 ...
	*/
SET NOCOUNT ON

	DECLARE @tmpSum TABLE(punterid INT, betslip INT, betswin INT, betsdraw INT, betslose INT, turnover MONEY, winlost MONEY, isRunning BIT)
	DECLARE @tmpPunter TABLE(punterid INT)
	DECLARE @f_date DATETIME,
			@t_date DATETIME
		
	SELECT @bettype = NULLIF(@bettype,0)
		
	IF @punterids <> ''
		INSERT INTO @tmpPunter
		SELECT val
		FROM f_AB_strSplit (@punterids, ',')
	ELSE
		INSERT INTO @tmpPunter
		SELECT NULL
	
	IF @todate > @MoveBetsDay
	BEGIN
		SELECT @f_date = CASE WHEN @fromdate > @MoveBetsDay THEN @fromdate ELSE @MoveBetsDay END,
				@t_date = @todate
		
		INSERT INTO @tmpSum
			SELECT 
				pg.punterid, 
				COUNT(1) betslip,
				SUM(CASE WHEN statusid = 112 THEN 1 ELSE 0 END) betswin,
				SUM(CASE WHEN statusid = 111 THEN 1 ELSE 0 END) betsdraw,
				SUM(CASE WHEN statusid = 113 THEN 1 ELSE 0 END) betslose,
				SUM(stake) turnover,
				SUM(CASE WHEN statusid NOT IN (0,1) THEN winlost - actual_stake ELSE 0 END) winlost,
				MAX(CASE WHEN statusid IN (0,1) THEN 1 ELSE 0 END) isRunning
			FROM ABPunterGroup pg WITH(NOLOCK) 
				INNER JOIN ABTransaction ab WITH(NOLOCK) ON pg.punterid = ab.punterid
				INNER JOIN bodb02.dbo.bettrans b WITH(NOLOCK) ON ab.transid = b.transid
			WHERE pg.adminID = @adminID 
				AND pg.punterid IN (SELECT ISNULL(t.punterid,ab.punterid) FROM @tmpPunter t)
				AND winlostdate BETWEEN @f_date AND @t_date
				AND ab.bettype = ISNULL(@bettype,ab.bettype)
				AND statusid NOT IN (101,102,103)
			GROUP BY pg.punterid
	END
		
	IF @fromdate <= @MoveBetsDay
	BEGIN
		IF @todate > @BalanceUpDay
		BEGIN
			SELECT @f_date = CASE WHEN @fromdate < @BalanceUpday THEN DATEADD(dd,1,@BalanceUpday) ELSE @fromdate END,
					@t_date = CASE WHEN @todate > @MoveBetsDay THEN @MoveBetsDay ELSE @todate END
					
			INSERT INTO @tmpSum
			SELECT pg.punterid,
				SUM(betcount) betslip,
				SUM(CASE WHEN statusid = 112 THEN betcount ELSE 0 END) betswin,
				SUM(CASE WHEN statusid = 111 THEN betcount ELSE 0 END) betsdraw,
				SUM(CASE WHEN statusid = 113 THEN betcount ELSE 0 END) betslose,
				SUM(turnover) turnover,
				SUM(winlost) winlost,
				0 AS isRunning
			FROM ABPunterGroup pg WITH(NOLOCK)
				INNER JOIN ABSum_winloss ab WITH(NOLOCK) ON pg.punterid = ab.punterid
			WHERE pg.adminID = @adminID 
				AND pg.punterid IN (SELECT ISNULL(t.punterid, ab.punterid) FROM @tmpPunter t)
				AND winlostdate BETWEEN @f_date AND @t_date
				AND bettype = ISNULL(@bettype,bettype)
				AND statusid NOT IN (101,102,103)
			GROUP BY pg.punterid
		END
		
		IF @fromdate <=@BalanceUpDay
		BEGIN
			SELECT @f_date = @fromdate,
					@t_date = CASE WHEN @todate > @BalanceUpDay THEN @BalanceUpDay ELSE @todate END
					
			INSERT INTO @tmpSum
			SELECT pg.punterid,
				SUM(betcount) betslip,
				SUM(CASE WHEN statusid = 112 THEN betcount ELSE 0 END) betswin,
				SUM(CASE WHEN statusid = 111 THEN betcount ELSE 0 END) betsdraw,
				SUM(CASE WHEN statusid = 113 THEN betcount ELSE 0 END) betslose,
				SUM(turnover) turnover,
				SUM(winlost) winlost,
				0 AS isRunning
			FROM ABPunterGroup pg WITH(NOLOCK)
				INNER JOIN ABSum_winloss_Old ab WITH(NOLOCK) ON pg.punterid = ab.punterid
			WHERE pg.adminID = @adminID 
				AND pg.punterid IN (SELECT ISNULL(t.punterid, ab.punterid) FROM @tmpPunter t)
				AND winlostdate BETWEEN @f_date AND @t_date
				AND bettype = ISNULL(@bettype,bettype)
				AND statusid NOT IN (101,102,103)
			GROUP BY pg.punterid
		END
	END	
		
	SELECT 0 as punterid, -- total
			'' code,
			'' color,
			SUM(betslip) betslip,
			SUM(betswin) betswin,
			SUM(betslose) betslose,
			SUM(betsdraw) betsdraw,
			CAST(SUM(betswin)*100.0/SUM(betslip) AS DECIMAL(6,2)) AS win_percent,
			SUM(turnover) turnover,
			SUM(winlost) totalPL, 
			CAST(SUM(winlost)*100/SUM(turnover) AS DECIMAL(10,2)) AS MP,
			0 isRunning
	FROM @tmpSum		
	UNION ALL
	SELECT p.punterid,	
			p.code,
			p.color,
			SUM(betslip) betslip,
			SUM(betswin) betswin,
			SUM(betslose) betslose,
			SUM(betsdraw) betsdraw,
			CAST(SUM(betswin)*100.0/SUM(betslip) AS DECIMAL(6,2)) AS win_percent,
			SUM(turnover) turnover,
			SUM(winlost) totalPL, 
			CAST(SUM(winlost)*100/SUM(turnover) AS DECIMAL(10,2))  AS MP,
			MAX(CASE WHEN isRunning = 1 THEN 1 ELSE 0 END) isRunning
	FROM @tmpSum t
		INNER JOIN ABPunterCode p WITH(NOLOCK) ON t.punterid = p.punterid
	GROUP BY p.punterid, p.code, p.color
	ORDER BY code ASC
	
	
	
	
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_RptSummary] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_RptSummary] TO [bodbAdminNet]




	