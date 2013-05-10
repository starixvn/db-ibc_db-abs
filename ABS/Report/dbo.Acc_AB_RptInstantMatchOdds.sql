ALTER PROCEDURE [dbo].[Acc_AB_RptInstantMatchOdds]
	@matchid VARCHAR(8000) = ''
AS
	/*
		Created: Johnson
		Date: 11Nov2011
		Task: get info of match to update report instant betslist 
		DB: DB054.bodb_ABS	
		
		Revisions:
		
		Parameters Explanation:
	*/  
SET NOCOUNT ON
		
	SELECT matchid, bettype, odds as eod, hdp as ehd
	FROM ABMatch_Remark WITH(NOLOCK)
	WHERE matchid IN (SELECT val FROM f_AB_strSplit(@matchid,','))
	
GO
GRANT EXECUTE ON [dbo].[Acc_AB_RptInstantMatchOdds] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_RptInstantMatchOdds] TO [vnteam]