ALTER PROCEDURE [dbo].[Acc_AB_ResultMatchSel]
	@winlostdate	DATETIME,
	@movebetsday	DATETIME,
	@leagueid		INT = 0 --All league 
AS
	/*
		Created: Johnson	
		Date: 22Nov2011
		Task: Get match info
		DB: DB054.bodb_ABS
		
		Revisions:
			- 20121119@Johnson: Get data from ABMatch_remark_BK if winlostdate <= movebetsday
		Paramters Explanation:
	*/
SET NOCOUNT ON
	
	IF @winlostdate > @movebetsday
		SELECT DISTINCT
			hthomescore,htawayscore, isnull(rm.calculate,0) IsCalculated, isnull(rm.multiple,0) IsMultiCaled,
			isnull(rm.refund,0) IsRefund, isnull(rm.calrefund,0) IsCalRefund,
			m.leagueid , 
			m.matchid, 
			m.homeid,
			m.awayid,
			m.matchcode,
			m.kickofftime,
			m.finalhomescore,
			m.finalawayscore,
			m.betstatus,
			case	when m.betstatus like 'Refund FT%' then 'Refund FT'
					when m.betstatus like 'Refund HT%' then 'Refund HT'
					when m.betstatus like 'Refund%' then 'Refund'
					else m.eventstatus
			end as eventstatus,  
			'' as Foddsstatus,
			m.sporttype,
			isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
			m.eventdate,
			m.goalrecord,
			case rm.ConfirmHT when 0 then '' else (select username from bodb02.dbo.custinfo (nolock) where custid = rm.ConfirmHT ) end suspenderHT, 
			case rm.ConfirmFT when 0 then '' else (select username from bodb02.dbo.custinfo (nolock) where custid = rm.ConfirmFT ) end suspenderFT,
			ISNULL(rm.IsHTCal,0) as IsHTCal,
			ISNULL(rm.calculate,0) as calculate,
			ISNULL(rm.isPending,0) as isPending,
			CASE WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END IsKeyscore
		FROM ABMatch_Remark ab WITH(NOLOCK) 
			INNER JOIN bodb02.dbo.match m WITH(NOLOCK) ON ab.matchid = m.matchid
			LEFT OUTER JOIN bodb02.dbo.match_remark rm WITH(NOLOCK) ON m.matchid = rm.matchid
		WHERE CONVERT(VARCHAR(10),m.kickofftime,120) = @winlostdate
			AND m.leagueid = CASE WHEN @leagueid = 0 THEN m.leagueid ELSE @leagueid END
	ELSE
		SELECT DISTINCT
			hthomescore,htawayscore, isnull(rm.calculate,0) IsCalculated, isnull(rm.multiple,0) IsMultiCaled,
			isnull(rm.refund,0) IsRefund, isnull(rm.calrefund,0) IsCalRefund,
			m.leagueid , 
			m.matchid, 
			m.homeid,
			m.awayid,
			m.matchcode,
			m.kickofftime,
			m.finalhomescore,
			m.finalawayscore,
			m.betstatus,
			case	when m.betstatus like 'Refund FT%' then 'Refund FT'
					when m.betstatus like 'Refund HT%' then 'Refund HT'
					when m.betstatus like 'Refund%' then 'Refund'
					else m.eventstatus
			end as eventstatus,  
			'' as Foddsstatus,
			m.sporttype,
			isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
			m.eventdate,
			m.goalrecord,
			case rm.ConfirmHT when 0 then '' else (select username from bodb02.dbo.custinfo (nolock) where custid = rm.ConfirmHT ) end suspenderHT, 
			case rm.ConfirmFT when 0 then '' else (select username from bodb02.dbo.custinfo (nolock) where custid = rm.ConfirmFT ) end suspenderFT,
			ISNULL(rm.IsHTCal,0) as IsHTCal,
			ISNULL(rm.calculate,0) as calculate,
			ISNULL(rm.isPending,0) as isPending,
			CASE WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END IsKeyscore
		FROM ABMatch_Remark_BK ab WITH(NOLOCK)
			INNER JOIN bodb02.dbo.match14 m WITH(NOLOCK) ON ab.matchid = m.matchid
			LEFT OUTER JOIN bodb02.dbo.match_remark rm WITH(NOLOCK) ON m.matchid = rm.matchid
		WHERE CONVERT(VARCHAR(10),m.kickofftime,120) = @winlostdate
			AND m.leagueid = CASE WHEN @leagueid = 0 THEN m.leagueid ELSE @leagueid END


GO
GRANT EXECUTE ON [dbo].[Acc_AB_ResultMatchSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_ResultMatchSel] TO [vnteam]

