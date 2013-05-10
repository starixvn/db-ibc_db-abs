ALTER PROCEDURE [dbo].[Acc_AB_PunterCodeSel] 
	@showDisabledPunter BIT = 0
AS
	/*
		Created: Johnson
		Date: 31Oct2011
		Task: Get punter's codes list
		DB: DBABS/bodb_ABS
		
		Revisions:
			- 20120308@Johnson: get total ABS admins assigned to punter code
			- 20121203@Johnson: hide some ABS's users not use
			- 20121227@Johnson: check for show/hide disabled punters
			- 20130121@Johnson: change linked server DB03 to DBPOLICY
		Parameters Explanation:
			-@showDisabledPunter : = 1 : show disabled punters
									= 0: hide disbled punters	
		
	*/
SET NOCOUNT ON	
	
	DECLARE @tmpABS TABLE (adminID INT)
	DECLARE	@groupid INT, @enabled BIT

	SELECT @groupid = groupid FROM DBPOLICY.bodb02.dbo.Acc_GroupInfo_1 WITH(NOLOCK) WHERE GroupName = 'ABS'
		
	INSERT INTO @tmpABS (adminID)
	SELECT custid
	FROM DBPOLICY.bodb02.dbo.accCustomer_1 WITH(NOLOCK)
	WHERE groupID = @groupid
		AND custid NOT IN (SELECT custid FROM f_AB_HiddenUsers())
	
	IF @showDisabledPunter = 0 
		SELECT @enabled = 1 	

	SELECT 
		p.punterid,	
		p.code,
		p.currency,
		p.color,
		p.fb_ah,
		p.fb_ou,
		p.fb_1x2,
		p.enabled,			
		p.totalMember,
		CASE WHEN p.totalMember = 1 THEN ci.username ELSE '' END username,
		ISNULL(pg.totalAdmin,0) totalAdmin
	FROM(
		SELECT p.punterid,	
			p.code,
			p.currency,
			p.color,
			p.fb_1 as fb_ah,
			p.fb_3 as fb_ou,
			p.fb_5 as fb_1x2,
			p.enabled,			
			COUNT(c.custid) as totalMember				
		FROM ABPunterCode p WITH(NOLOCK)
			LEFT JOIN ABCustomer c WITH(NOLOCK) ON c.punterid = p.punterid	
		WHERE p.enabled = isnull(@enabled,p.enabled)
		GROUP BY p.punterid ,p.code ,p.currency ,p.color ,p.fb_1 ,p.fb_3 ,p.fb_5 ,p.enabled
		)p
	LEFT JOIN (
		SELECT punterid, count(1) as totalAdmin
		FROM ABPunterGroup WITH(NOLOCK)
		WHERE adminID IN (SELECT adminid FROM @tmpABS)
		GROUP BY punterid
		) pg ON p.punterid = pg.punterid 
	LEFT JOIN ABCustomer c WITH(NOLOCK) ON p.punterid = c.PunterID
	LEFT JOIN bodb02.dbo.custInfo ci WITH(NOLOCK) ON c.CustID = ci.custid
	GROUP BY p.punterid, p.code, p.currency, p.color, p.fb_ah, p.fb_ou, p.fb_1x2, p.enabled,p.totalMember,
		CASE WHEN p.totalMember = 1 THEN ci.username ELSE '' END, pg.totalAdmin
	ORDER BY p.enabled DESC, code ASC 
	
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_AB_PunterCodeSel] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_AB_PunterCodeSel] TO [bodbAdminNet]
