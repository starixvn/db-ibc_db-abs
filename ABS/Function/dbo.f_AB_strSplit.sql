CREATE FUNCTION  [dbo].[f_AB_strSplit] ( @string nvarchar( MAX), @splitter CHAR( 1) )  
RETURNS @res TABLE ( id INT PRIMARY KEY, rank INT, val nvarchar( MAX) )  
AS  
BEGIN  
     IF SUBSTRING ( @string, len ( @string), 1)<>@splitter  
          SET @string= @string+@splitter  
     DECLARE @start INT, @word nvarchar(MAX), @charindex INT, @i INT  
     SET @i=1  
     SET @start=1  
     SET @charindex= CHARINDEX( @splitter, @string, @start)  
     WHILE (@charindex <> 0)BEGIN  
          SET @word= SUBSTRING( @string, @start, @charindex - @start)  
          SET @start= @charindex +1  
          SET @charindex= CHARINDEX( @splitter, @string, @start)  
          INSERT INTO @res  VALUES ( @start, @i, @word)  
          SET @i=@i+1  
     END  
     RETURN  
END   