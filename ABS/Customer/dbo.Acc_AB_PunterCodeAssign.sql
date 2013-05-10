 ALTER PROCEDURE [dbo].[Acc_AB_PunterCodeAssign]
	@punterid	INT
AS
	/*
		Created: Johnson
		Date: 20120307
		Task: Assign punter to admin have permission automatic after adding new punter code
		DB: DBABS/bodb_ABS
		
		Revisions:
			- 20130121@Johnson: change linked server DB03 to DBPOLICY
	*/
SET NOCOUNT ON 

	DECLARE @tmpUser TABLE (adminID INT)
	
	DECLARE @funcid INT
	
	SELECT @funcid = funcid FROM DBPOLICY.BODB02.dbo.Acc_FunctionInfo WITH(NOLOCK) WHERE FuncName = '[ABSAdminUserControl]'
	 
	-- get admin user have host permission on [ABSCustomerManegement] function
	INSERT INTO @tmpUser
	SELECT custid
	FROM DBPOLICY.BODB02.dbo.Acc_MemberPolicy_1 WITH(NOLOCK)
	WHERE funcid = @funcid AND policy = 3
	
	INSERT INTO ABPunterGroup(adminID,punterid)
	SELECT adminID, @punterid
	FROM @tmpUser t
	WHERE NOT EXISTS(SELECT 1 FROM ABPunterGroup WITH(NOLOCK) WHERE punterid = @punterid AND adminID = t.adminID)
	
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_PunterCodeAssign] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_PunterCodeAssign] TO [bodbAdminNet]