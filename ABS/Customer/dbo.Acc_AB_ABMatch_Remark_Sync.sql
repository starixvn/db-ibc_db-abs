 ALTER PROCEDURE [dbo].[Acc_AB_ABMatch_Remark_Sync]
	@punterid	INT,
	@custid		INT =0,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
 AS
	/*
		Created: Johnson
		Date: 2012-12-28
		Task: Synchronize ABMatch_Remark after add new customer/enable punter
		DB: DB054.bobdb_ABS
		
		Revisions:
		
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	DECLARE @tmpMatch TABLE(matchid int, bettype int)
	DECLARE @tmpBettrans TABLE (transid bigint)
	
	IF @custid <> 0
	BEGIN
		;WITH B AS(
			SELECT DISTINCT matchid, bettype
			FROM ABTransaction WITH(NOLOCK)
			WHERE custid = @custid
		)
		
		INSERT INTO @tmpMatch (matchid, bettype)
		SELECT b.matchid, b.bettype 
		FROM B 
			LEFT JOIN ABMatch_Remark m WITH(NOLOCK) ON b.matchid = m.matchid AND b.bettype = m.bettype
		WHERE m.transid IS NULL
		
		IF @@ROWCOUNT = 0 RETURN		
	END
	ELSE 
	BEGIN
		;WITH B AS(
			SELECT DISTINCT matchid, bettype
			FROM ABTransaction WITH(NOLOCK)				
			WHERE punterid = @punterid
		)
		
		INSERT INTO @tmpMatch (matchid, bettype)
		SELECT b.matchid, b.bettype 
		FROM B
			LEFT JOIN ABMatch_Remark m WITH(NOLOCK) ON b.matchid = m.matchid AND b.bettype = m.bettype
		WHERE m.transid IS NULL
		
		IF @@ROWCOUNT = 0 RETURN
	END
		
	INSERT INTO @tmpBettrans (transid)
	SELECT min(transid)
	FROM bodb02.dbo.bettrans b WITH(NOLOCK)
		INNER JOIN @tmpMatch t ON b.matchid = t.matchid AND b.bettype = t.bettype
	GROUP BY b.matchid, b.bettype
	
	INSERT INTO ABMatch_Remark ([matchid]
       ,[bettype]
       ,[hdp]
       ,[odds]
       ,[transid]
       ,[betteam])
    SELECT b.matchid
       ,b.bettype
       ,CASE WHEN b.bettype IN (1,7) THEN CASE WHEN b.betteam = 'h' THEN b.hdp2 - b.hdp1 ELSE b.hdp1 - b.hdp2 END
			WHEN b.bettype IN (5,15) THEN NULL 
			ELSE b.hdp1 END
       ,b.odds
       ,b.transid
       ,b.betteam
    FROM @tmpBettrans t
		INNER JOIN bodb02.dbo.bettrans b WITH(NOLOCK) ON t.transid = b.transid
		LEFT JOIN ABMatch_Remark m WITH(NOLOCK) ON b.matchid = m.matchid AND b.bettype = m.bettype
	WHERE m.transid IS NULL
	
GO
GRANT EXECUTE ON [dbo].[Acc_AB_ABMatch_Remark_Sync] TO [bodbAdminNet]
