ALTER PROCEDURE [dbo].[Acc_AB_AdminSel]
AS
	/*
		Created: Johnson
		Date: 2012-11-28
		Task: Get info from ABS's admin
		DB: DB054.bodb_ABS
		
		Revisions:
		
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	SELECT
	FROM 
		(	
			SELECT custid 
			FROM f_AB_ListAdmin() 
		) r 
		INNER JOIN customer c WITH(NOLOCK) ON r.custid = c.custid
		
	 
	 -- test

GO
GRANT EXECUTE ON [dbo].[Acc_AB_AdminSel] TO [bodbRMSNet] 