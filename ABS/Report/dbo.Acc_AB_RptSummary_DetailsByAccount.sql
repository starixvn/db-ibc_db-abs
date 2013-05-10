ALTER PROCEDURE [dbo].[Acc_AB_RptSummary_DetailsByAccount]
	@punterid		INT,
	@fromdate		DATETIME,
	@todate			DATETIME,	
	@MoveBetsDay	DATETIME,
	@BalanceUpDay	DATETIME,
	@bettype		INT
	WITH RECOMPILE
AS
	/*
		Created: Johnson
		Date: 09Nov2011
		Task: Get report summary by account
		DB: DB054.bodb_ABS
		
		Revisions:
			- 20120702@Johnson: filter by bettype
			- 20120912@Johnson: get data from ABSum_Winloss_Old before balance up date			
		Parameters Explanation:
			- @bettype : 0: all bettype
						 1: hdp
						 7: 1st hdp
						 ...
	*/
SET NOCOUNT ON
	
	DECLARE @tmpSum TABLE(leagueid INT, betslip INT, betswin INT, betslose INT, betsdraw INT , turnover MONEY, winlost MONEY, isRunning BIT)
	DECLARE @f_date DATETIME,
			@t_date DATETIME
				
	SELECT @bettype = NULLIF(@bettype,0)
	
	IF @todate > @MoveBetsDay
	BEGIN
		SELECT @f_date = CASE WHEN @fromdate > @MoveBetsDay THEN @fromdate ELSE @MoveBetsDay END,
				@t_date = @todate
				
		INSERT INTO @tmpSum
		SELECT
			m.leagueid,
			COUNT(1) AS betslip,
			SUM(CASE WHEN statusid = 112 THEN 1 ELSE 0 END) betswin,
			SUM(CASE WHEN statusid = 113 THEN 1 ELSE 0 END) betslose,
			SUM(CASE WHEN statusid = 111 THEN 1 ELSE 0 END) betsdraw,
			SUM(stake) turnover,
			SUM(CASE WHEN statusid NOT IN (0,1) THEN winlost - actual_stake ELSE 0 END) winlost,
			MAX(CASE WHEN statusid IN (0,1) THEN 1 ELSE 0 END) isRunning
		FROM ABTransaction ab WITH(NOLOCK)
			INNER JOIN bodb02.dbo.bettrans b WITH(NOLOCK) ON ab.transid = b.transid
			INNER JOIN bodb02.dbo.match m WITH(NOLOCK) ON b.matchid = m.matchid
		WHERE ab.punterid = @punterid
			AND b.winlostdate BETWEEN @fromdate AND @todate
			AND b.statusid NOT IN (101,102,103)
			AND ab.bettype = ISNULL(@bettype,ab.bettype)
		GROUP BY m.leagueid
	END
	
	IF @fromdate <= @MoveBetsDay
	BEGIN
		IF @todate > @BalanceUpDay
		BEGIN
			SELECT @f_date = CASE WHEN @fromdate < @BalanceUpday THEN DATEADD(dd,1,@BalanceUpday) ELSE @fromdate END,
					@t_date = CASE WHEN @todate > @MoveBetsDay THEN @MoveBetsDay ELSE @todate END
					
			INSERT INTO @tmpSum
			SELECT 
				leagueid,
				SUM(betcount) AS betslip,
				SUM(CASE WHEN statusid = 112 THEN betcount ELSE 0 END) betswin,
				SUM(CASE WHEN statusid = 113 THEN betcount ELSE 0 END) betslose,
				SUM(CASE WHEN statusid = 111 THEN betcount ELSE 0 END) betsdraw,
				SUM(turnover) turnover,
				SUM(winlost) winlost,
				0 isRunning
			FROM ABSum_winloss WITH(NOLOCK)
			WHERE punterid = @punterid
				AND winlostdate BETWEEN @fromdate AND @todate
				AND bettype = ISNULL(@bettype,bettype)
				AND statusid NOT IN (101,102,103)
			GROUP BY leagueid
		END
		IF @fromdate <=@BalanceUpDay
		BEGIN
			SELECT @f_date = @fromdate,
					@t_date = CASE WHEN @todate > @BalanceUpDay THEN @BalanceUpDay ELSE @todate END
			
			INSERT INTO @tmpSum
			SELECT 
				leagueid,
				SUM(betcount) AS betslip,
				SUM(CASE WHEN statusid = 112 THEN betcount ELSE 0 END) betswin,
				SUM(CASE WHEN statusid = 113 THEN betcount ELSE 0 END) betslose,
				SUM(CASE WHEN statusid = 111 THEN betcount ELSE 0 END) betsdraw,
				SUM(turnover) turnover,
				SUM(winlost) winlost,
				0 isRunning
			FROM ABSum_winloss_Old WITH(NOLOCK)
			WHERE punterid = @punterid
				AND winlostdate BETWEEN @fromdate AND @todate
				AND bettype = ISNULL(@bettype,bettype)
				AND statusid NOT IN (101,102,103)
			GROUP BY leagueid		
		END
	END
		
	SELECT leagueid,
		SUM(betslip) betslip,
		SUM(betswin) betswin,
		SUM(betslose) betslose,
		SUM(betsdraw) betsdraw,
		CAST(SUM(betswin)*100.0/SUM(betslip) AS DECIMAL(6,2)) AS win_percent,
		SUM(turnover) turnover,
		SUM(winlost) totalPL,
		CAST(SUM(winlost)*100/SUM(turnover) AS DECIMAL(10,2)) AS MP,
		MAX(CASE WHEN isRunning = 1 THEN 1 ELSE 0 END) isRunning
	FROM @tmpSum
	GROUP BY leagueid
	UNION ALL
	SELECT 0 as leagueid, -- total
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
	
	

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_RptSummary_DetailsByAccount] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_RptSummary_DetailsByAccount] TO [bodbAdminNet]
	
	
	 