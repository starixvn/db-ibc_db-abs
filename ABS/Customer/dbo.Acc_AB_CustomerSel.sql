 ALTER PROCEDURE [dbo].[Acc_AB_CustomerSel]
  @punterid	INT
 AS 
	/*
		Create: Johnson
		Date: 2011-11-01
		DB: DB054.bodb_ABS
		Task: Get list members under punter code
		
		Revisions:
		
		Parameters Explanation:
			
	*/
	
SET NOCOUNT ON		
				
		SELECT 
			ci.custid,
			ci.username	
		FROM ABCustomer c WITH(NOLOCK)
		INNER JOIN bodb02.dbo.custinfo ci WITH(NOLOCK) ON c.custid = ci.custid
		WHERE punterid = @punterid
		
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_CustomerSel] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_CustomerSel] TO [bodbAdminNet]
GO
