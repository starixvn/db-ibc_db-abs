 ALTER PROCEDURE [dbo].[Acc_AB_CustomerSearch]		
	@username	VARCHAR(50)
AS
	/*
		Created: Johnson
		Date: 01Nov2011
		Task: Search member info
		DB: DB054.bodb_ABS
		
		Revisions:
		
		Paramters Explanation:					
	*/
SET NOCOUNT ON
	
	
	SELECT TOP 10 username
	FROM bodb02.dbo.custinfo WITH(NOLOCK)
	WHERE roleid = 1 
		AND username LIKE @username +'%' 		
		AND danger2 >= 1
		AND custid NOT IN (SELECT custid FROM ABCustomer WITH(NOLOCK))
	

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_CustomerSearch] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_CustomerSearch] TO [bodbAdminNet]
	