 ALTER PROCEDURE [dbo].[Acc_AB_AdminByPunterCodeSel]
	@punterid		INT
AS
	/*
		Created: Johnson
		Date: 20120-03-08
		Task: get list admin assigned to punter code
		DB: DBABS/bodb_ABS
		Revisions:
			- 20121203@Johnson: hide some ABS's users not use
			- 20130121@Johnson: change linked server DB03 to DBPOLICY
		Parameters Explanation:
			
	*/
SET NOCOUNT ON

	DECLARE @tmpABS TABLE (adminID INT, username NVARCHAR(50), closed BIT, isSuper BIT)
	DECLARE	@groupid INT, @funcid INT

	SELECT @groupid = groupid FROM DBPOLICY.BODB02.dbo.Acc_GroupInfo_1 WITH(NOLOCK) WHERE GroupName = 'ABS'
	SELECT @funcid  = funcid  FROM DBPOLICY.BODB02.dbo.Acc_FunctionInfo WITH(NOLOCK) WHERE FuncName = '[ABSAdminUserControl]'
	
	INSERT INTO @tmpABS (adminID, username, closed, isSuper)
	SELECT ci.custid, ci.username, ci.closed, CASE WHEN mp.policy = 3 THEN 1 ELSE 0 END 
	FROM DBPOLICY.BODB02.dbo.accCustomer_1 ac WITH(NOLOCK)
		LEFT JOIN DBPOLICY.BODB02.dbo.Acc_MemberPolicy_1 mp WITH(NOLOCK) ON ac.custid = mp.custid AND mp.funcid = @funcid 
		INNER JOIN bodb02.dbo.custinfo ci WITH(NOLOCK) ON ac.custid = ci.custid
	WHERE ac.groupID = @groupid
		AND ac.custid NOT IN (SELECT custid FROM f_AB_HiddenUsers())
		
		
	SELECT t.adminID, t.username, t.isSuper, CASE WHEN pg.adminID IS NOT NULL THEN 1 ELSE 0 END isChecked
	FROM @tmpABS t
		LEFT JOIN ABPunterGroup pg WITH(NOLOCK) ON pg.adminid = t.adminid AND pg.punterid = @punterid
	
	
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_AdminByPunterCodeSel] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_AdminByPunterCodeSel] TO [bodbAdminNet]