USE [DCConfigHub]
GO

/** Object:  StoredProcedure [dcFeeds].[dcsp_QueryGenerator_Insert_Update_identity]    Script Date: 5/9/2023 5:17:57 PM **/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



 CREATE procedure  [dcFeeds].[dcsp_QueryGenerator_Insert_Update_identity]                               
(                                                          
   @feedname Varchar(MAX),
   @env varchar(max)                                                           
)  
/*
Test Execution
~~~~~
exec [dcFeeds].[dcsp_QueryGenerator_Insert_Update_identity] 'EWSReportingHoldingAll_NewLogic','NPROD'
exec [dcFeeds].[dcsp_QueryGenerator_Insert_Update_identity] 'EWSReportingHoldingConfiguration_NewLogic','NPROD'
exec [dcFeeds].[dcsp_QueryGenerator_Insert_Update_identity] 'EWSReportingHoldingDetail_NewLogic','NPROD'
exec [dcFeeds].[dcsp_QueryGenerator_Insert_Update_identity] 'EWSReportingHoldingGroup_NewLogic','NPROD'
exec [dcFeeds].[dcsp_QueryGenerator_Insert_Update_identity] 'EWSReportingHoldingSummary_NewLogic','NPROD'

*/

AS                              

SET nocount ON                  

if object_id('tempdb..#ScriptTbl') is not null
DROP TABLE #ScriptTbl
CREATE TABLE #ScriptTbl ( row int identity,query varchar(max) null)
                                                      
if object_id('tempdb..#ScriptTblupdate') is not null
DROP TABLE #ScriptTblupdate
CREATE TABLE #ScriptTblupdate ( row int identity,query varchar(max) null)

DECLARE @Condition  Varchar(MAX)                        
DECLARE @idcolumns varchar(100)
DECLARE @schema_name varchar(100)
DECLARE @table_name varchar(100)
DECLARE @dbname varchar(100)
DECLARE @UpdateStatment VARCHAR(MAX)
DECLARE @ColStatment VARCHAR(MAX)
DECLARE @COLUMNS  table (Row_number SmallINT , Column_Name VArchar(Max) )                              
DECLARE @CONDITIONS as varchar(MAX)                              
DECLARE @Total_Rows as SmallINT                              
DECLARE @Counter as SmallINT              
DECLARE @ComaCol as varchar(max) 
DECLARE @CONDITIONSUP VARCHAR(max)
DECLARE @id int
DECLARE @CONDITIONSIN varchar(max) = ''
DECLARE @wherecon varchar(100) = ''
DECLARE @tmpupdate table (query varchar(max))
SET @schema_name='dcfeeds' 
SET @dbname = 'DcConfigHub'            
   
INSERT INTO #ScriptTbl
SELECT '  BEGIN TRY' union all
SELECT    'BEGIN TRANSACTION' union all
SELECT 'DECLARE @IDENTITY_Col as INT' union all
SELECT 'DECLARE @IDENTITY_Col2 as INT' union all
SELECT 'DECLARE @id int' union all
SELECT ' DECLARE @env varchar(100) ='+''''+@env+''''


-- looking if the feed is present in the table
IF Exists( select * from [DcConfigHub].[dcFeeds].[dcFeedConfig] where feedname=@feedname)
begin

SET @schema_name='dcfeeds' 
SET @dbname = 'DcConfigHub'
SET @ComaCol=''                   
SET @UpdateStatment= ''
SET @ColStatment= ''
SET @Counter=1                              
SET @CONDITIONS='' 
SET @CONDITIONSUP=''
SET @Condition =''
SELECT @Table_name = 'dcFeedConfig' 
DELETE from @COLUMNS
SET @Total_Rows=''




--Generating update statements
INSERT INTO @COLUMNS                              
SELECT Row_number()Over (Order by ORDINAL_POSITION ) [Count], Column_Name 
FROM DcConfigHub.INformation_schema.columns 
WHERE Column_Name not in ('LastUpdateDate','LastUpdateUser','CreatedDate','CreatedUser')      
 AND Table_schema=@Schema_name AND table_name=@Table_name         


SELECT @Total_Rows= Count(1) 
FROM @COLUMNS                              

SELECT @Table_name= '['+@Table_name+']'                      

SELECT @Schema_name='['+@Schema_name+']'                      

While (@Counter<=@Total_Rows )                              
begin                               
--checking the counter                             

SELECT @ComaCol= @ComaCol+'['+Column_Name+'],'            
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                          

SELECT @CONDITIONS=@CONDITIONS+ ' + Case When fc.['+Column_Name+'] is null then ''Null'' Else '''''''' + Replace( Convert(varchar(Max),fc.['+Column_Name+']  ) ,'''''''',''''''''''''  ) +'''''''' end+'+''','''                                                     
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                              



SELECT @CONDITIONSUP=@CONDITIONSUP +Column_Name+' = '+''''+'+'+''''''''''+'+'+'ISNULL(CONVERT(VARCHAR(50) ,fc.['+Column_Name+']),''NULL'')'+'+'+'''' +''''''+ ','
 FROM @COLUMNS                              
WHERE [Row_number]=@Counter


SET @Counter=@Counter+1                              

End                              

  

SELECT @CONDITIONS= '''INSERT INTO '+@Schema_name+'.'+@Table_name+ '('+@ComaCol+'[lastUpdatedate],[lastupdatEUSER],[CReatedDate],[CreatedUser])' +' Values( '+'''' + '+'+@CONDITIONS+'+'+''''+ 'CURRENT_TIMESTAMP,SYSTEM_USER,CURRENT_TIMESTAMP,SYSTEM_USER'+''''                              

SELECT @CONDITIONS=@CONDITIONS+'+'+ ''')'''                                 

SELECT @CONDITIONS= 'INSERT INTO #ScriptTbl Select  distinct '+@CONDITIONS +'From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' fc With(NOLOCK) ' + '  Where fc.feedname=''' +@feedname+  ''''                         

                      
Exec(@CONDITIONS)

--Generating upadte statements

SET @UpdateStatment = @UpdateStatment + 'UPDATE ' +@Schema_name+'.'+  @Table_Name + ' '
SET @UpdateStatment = @UpdateStatment + 'SET' +' ' 

SELECT @UpdateStatment = 'SELECT distinct ' + ''''+ @UpdateStatment+@CONDITIONSUP+'[LastUpdateDate]=CURRENT_TIMESTAMP,[LastUpdateUser]=SYSTEM_USER,[CreatedDate]=CURRENT_TIMESTAMP,[CreatedUser]=SYSTEM_USER'+''''+' From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' fc With(NOLOCK) ' + '  Where fc.feedname=''' +@feedname+  '''' 

SET @wherecon =' where [feedname]='+''''+@feedname+'''' 


Insert into @tmpupdate
EXEC(@UpdateStatment)

Insert into #ScriptTblupdate
select CONCAT(query,@wherecon) from @tmpupdate

DELETE from @tmpupdate

--print 'dcFeedConfig' 

end 

IF EXISTS(select fac.[FeedApplicationId] from [DcConfigHub].[dcFeeds].[dcFeedApplicationConfig]
 fac left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fac.[FeedApplicationId] = flm.[FeedApplicationId] 
 where flm.feedname=@feedname)
BEGIN

SET @schema_name='dcfeeds' 
SET @dbname = 'DcConfigHub'
SET @ComaCol=''                   
SET @UpdateStatment= ''
SET @ColStatment= ''
SET @Counter=1                              
SET @CONDITIONS='' 
SET @CONDITIONSUP=''
SET @Condition =''
DELETE from @COLUMNS
SET @Total_Rows=''


SELECT @Table_name = 'dcFeedApplicationConfig' 

INSERT INTO #ScriptTbl 
SELECT 'SET IDENTITY_INSERT [dcFeeds].[dcFeedApplicationConfig] ON;'

--Generating update statements
INSERT INTO @COLUMNS                              
SELECT Row_number()Over (Order by ORDINAL_POSITION ) [Count], Column_Name 
FROM DcConfigHub.INformation_schema.columns 
WHERE Column_Name not in ('LastUpdateDate','LastUpdateUser','CreatedDate','CreatedUser','FeedApplicationId')      
 AND Table_schema=@Schema_name AND table_name=@Table_name         


SELECT @Total_Rows= Count(1) 
FROM @COLUMNS                              

SELECT @Table_name= '['+@Table_name+']'                      

SELECT @Schema_name='['+@Schema_name+']'                      

While (@Counter<=@Total_Rows )                              
begin                               
--checking the counter                             

SELECT @ComaCol= @ComaCol+'['+Column_Name+'],'            
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                          

SELECT @CONDITIONS=@CONDITIONS+ ' + Case When fac.['+Column_Name+'] is null then ''Null'' Else '''''''' + Replace( Convert(varchar(Max),fac.['+Column_Name+']  ) ,'''''''',''''''''''''  ) +'''''''' end+'+''','''                                                     
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                              


SELECT @CONDITIONSUP=@CONDITIONSUP +Column_Name+' = '+''''+'+'+''''''''''+'+'+'ISNULL(CONVERT(VARCHAR(50) ,'+'fac.['+Column_Name+']'+'),'+''''+'NULL'+''''+')'+'+'+'''' +''''''+ ','
 FROM @COLUMNS                              
WHERE [Row_number]=@Counter

SET @Counter=@Counter+1                              

End                              

INSERT INTO #ScriptTbl
SELECT 'SET @IDENTITY_Col=IDENT_CURRENT('+''''+'[dcFeeds].[dcFeedApplicationConfig]'+''''+');' union all
SELECT 'SET @id=@IDENTITY_Col' union all
SELECT 'if EXISTS(select 1 from [dcFeeds].[dcFeedApplicationConfig])
Begin 
set @id = @id +1
END' 

DECLARE @applitmp table (row int, appid varchar(100))
DECLARE @tmp_FeedApplicationName varchar(100)

insert into @applitmp  select Row_number()Over (Order by [FeedApplicationName] ) [Count],[FeedApplicationName] from [DcConfigHub].[dcFeeds].[dcFeedApplicationConfig] where [FeedApplicationId] in (select fac.[FeedApplicationId] from [DcConfigHub].[dcFeeds].[dcFeedApplicationConfig]
 fac left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fac.[FeedApplicationId] = flm.[FeedApplicationId] 
 where flm.feedname=@feedname)

set @Counter = 1

SELECT @Total_Rows= Count(1) 
FROM @applitmp 

While (@Counter<=@Total_Rows )                              
begin 
select @tmp_FeedApplicationName=[appid] from @applitmp where [row]=@Counter
INSERT INTO #ScriptTbl
SELECT 'IF NOT EXISTS(select 1 from [dcFeeds].[dcFeedApplicationConfig] where [FeedApplicationName]='+''''+@tmp_FeedApplicationName+''''+')
BEGIN'


SELECT @CONDITIONS= '''INSERT INTO '+@Schema_name+'.'+@Table_name+ '('+@ComaCol+'[lastUpdatedate],[lastupdatEUSER],[CReatedDate],[CreatedUser],[FeedApplicationId])' +' Values( '+'''' + '+'+@CONDITIONS+'+'+''''+ 'CURRENT_TIMESTAMP,SYSTEM_USER,CURRENT_TIMESTAMP,SYSTEM_USER,@id'+''''                              

SELECT @CONDITIONS=@CONDITIONS+'+'+ '''); SET @id=@id + 1'''                              

SELECT @CONDITIONS= 'INSERT INTO #ScriptTbl Select  distinct '+@CONDITIONS +'From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' fac With(NOLOCK) ' + ' left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fac.[FeedApplicationId] = flm.[FeedApplicationId] where flm.feedname=''' +@feedname+  ''''                         

                 
Exec(@CONDITIONS)
SET @Counter = @Counter + 1
INSERT INTO #ScriptTbl 
SELECT 'END'
END
--Generating upadte statements

SET @UpdateStatment = @UpdateStatment + 'UPDATE ' +@schema_name+'.'+  @Table_Name + ' '
SET @UpdateStatment = @UpdateStatment + 'SET' +' ' 

SELECT @UpdateStatment = 'INSERT INTO #ScriptTblupdate  SELECT distinct ' + ''''+ @UpdateStatment+@CONDITIONSUP+'[LastUpdateDate]=CURRENT_TIMESTAMP,[LastUpdateUser]=SYSTEM_USER,[CreatedDate]=CURRENT_TIMESTAMP,[CreatedUser]=SYSTEM_USER'+''''+' From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' fac With(NOLOCK) ' + 'left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fac.[FeedApplicationId] = flm.[FeedApplicationId] where flm.feedname=''' +@feedname+  ''''

EXEC(@UpdateStatment)
INSERT INTO #ScriptTbl 
SELECT 'SET IDENTITY_INSERT [dcFeeds].[dcFeedApplicationConfig] OFF;'

--print 'dcFeedApplicationConfig'
end 


IF EXISTS (
select flc.[FeedLocationId] from [DcConfigHub].[dcFeeds].[dcFeedLocationConfig] flc  
left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm 
on flc.[FeedLocationId] = flm.[SourceLocationId] where flm.feedname=@feedname
union all
select flc.[FeedLocationId]  from [DcConfigHub].[dcFeeds].[dcFeedLocationConfig] flc  
left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm 
on flc.[FeedLocationId] = flm.[TargetLocationId] where flm.feedname=@feedname) 
BEGIN

SET @schema_name='dcfeeds' 
SET @dbname = 'DcConfigHub'
SET @ComaCol=''                   
SET @UpdateStatment= ''
SET @ColStatment= ''
SET @Counter=1                              
SET @CONDITIONS='' 
SET @CONDITIONSUP=''
SET @Condition =''
DELETE from @COLUMNS
SET @Total_Rows=''



SELECT @Table_name = 'dcFeedLocationConfig' 


INSERT INTO #ScriptTbl 

SELECT 'SET @IDENTITY_Col=IDENT_CURRENT('+''''+'[dcFeeds].[dcFeedLocationConfig]'+''''+');' union all
SELECT 'SET @id=@IDENTITY_Col' union all
SELECT 'if EXISTS(select 1 from [dcFeeds].[dcFeedLocationConfig])
Begin 
set @id = @id +1
END' union all

SELECT 'SET IDENTITY_INSERT [dcFeeds].[dcFeedLocationConfig] ON;'

--Generating update statements
INSERT INTO @COLUMNS                              
SELECT Row_number()Over (Order by ORDINAL_POSITION ) [Count], Column_Name 
FROM DcConfigHub.INformation_schema.columns 
WHERE Column_Name not in ('LastUpdateDate','LastUpdateUser','CreatedDate','CreatedUser','FeedLocationId','Environment')      
 AND Table_schema=@Schema_name AND table_name=@Table_name         


SELECT @Total_Rows= Count(1) 
FROM @COLUMNS                              

SELECT @Table_name= '['+@Table_name+']'                      

SELECT @Schema_name='['+@Schema_name+']'                      

While (@Counter<=@Total_Rows )                              
begin                               
--checking the counter                             

SELECT @ComaCol= @ComaCol+'['+Column_Name+'],'            
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                          

SELECT @CONDITIONS=@CONDITIONS+ ' + Case When flc.['+Column_Name+'] is null then ''Null'' Else '''''''' + Replace( Convert(varchar(Max),flc.['+Column_Name+']  ) ,'''''''',''''''''''''  ) +'''''''' end+'+''','''                                                     
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                              


SELECT @CONDITIONSUP=@CONDITIONSUP +Column_Name+' = '+''''+'+'+''''''''''+'+'+'ISNULL(CONVERT(VARCHAR(50) ,'+'flc.['+Column_Name+']'+'),'+''''+'NULL'+''''+')'+'+'+'''' +''''''+ ','
 FROM @COLUMNS                              
WHERE [Row_number]=@Counter

SET @Counter=@Counter+1                              

End                              

DECLARE @azlinkedservices table (row int, azlinkedservice varchar(100))
DECLARE @CONDITIONSFLU varchar(max) = ''
DECLARE @Counterls int = 1
DECLARE @tmp_azlinkedservice varchar(100) = ''

insert into @azlinkedservices select Row_number()Over (Order by [AzLinkedServiceName] ) [Count],[AzLinkedServiceName] from [DcConfigHub].[dcFeeds].[dcFeedLocationConfig] where [FeedLocationId] in(

select flc.[FeedLocationId] from [DcConfigHub].[dcFeeds].[dcFeedLocationConfig] flc  
left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm 
on flc.[FeedLocationId] = flm.[SourceLocationId] where flm.feedname=@feedname
union all
select flc.[FeedLocationId]  from [DcConfigHub].[dcFeeds].[dcFeedLocationConfig] flc  
left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm 
on flc.[FeedLocationId] = flm.[TargetLocationId] where flm.feedname=@feedname)

 SELECT @Total_Rows= Count(1) 
FROM @azlinkedservices


INSERT INTO #ScriptTbl 
SELECT '
DECLARE @azlinkedservice varchar(100) = NULL;'



While (@Counterls<=@Total_Rows )                              
begin 

SELECT @tmp_azlinkedservice=[azlinkedservice] from @azlinkedservices where [row] =@Counterls 

INSERT INTO #ScriptTbl
SELECT 'IF NOT EXISTS(select 1 from [dcFeeds].[dcFeedLocationConfig] where [AzLinkedServiceName]='+''''+@tmp_azlinkedservice+''''+')
BEGIN'

SELECT @CONDITIONSFLU= '''INSERT INTO '+@Schema_name+'.'+@Table_name+ '('+@ComaCol+'[lastUpdatedate],[lastupdatEUSER],[CReatedDate],[CreatedUser],[FeedLocationId],[Environment])' +' Values( '+'''' + '+'+@CONDITIONS+'+'+''''+ 'CURRENT_TIMESTAMP,SYSTEM_USER,CURRENT_TIMESTAMP,SYSTEM_USER,@id,@env'+''''                              

SELECT @CONDITIONSFLU=@CONDITIONSFLU+'+'+ '''); SET @id=@id + 1'''                               

SELECT @CONDITIONSFLU= 'INSERT INTO #ScriptTbl  Select  distinct '+@CONDITIONSFLU +'From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' flc With(NOLOCK) ' + ' where flc.[AzLinkedServiceName]='+''''+@tmp_azlinkedservice+''''+'and flc.[FeedLocationId] in (select * from (
select flc.[FeedLocationId] from [DcConfigHub].[dcFeeds].[dcFeedLocationConfig] flc  
left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm 
on flc.[FeedLocationId] = flm.[SourceLocationId] where flm.feedname='+''''+@feedname+''''+'
union all
select flc.[FeedLocationId]  from [DcConfigHub].[dcFeeds].[dcFeedLocationConfig] flc  
left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm 
on flc.[FeedLocationId] = flm.[TargetLocationId] where flm.feedname='+''''+@feedname+''''+') t) '                           


                     
Exec(@CONDITIONSFLU)
INSERT INTO #ScriptTbl
SELECT 'END'
SET @CONDITIONSFLU = ''
SET @counterls = @counterls+1

end

--Generating upadte statements

SET @UpdateStatment = @UpdateStatment + 'UPDATE ' +@schema_name+'.'+  @Table_Name + ' '
SET @UpdateStatment = @UpdateStatment + 'SET' +' ' 

SELECT @UpdateStatment = 'INSERT INTO #ScriptTblupdate  SELECT distinct' + ''''+ @UpdateStatment+@CONDITIONSUP+'[LastUpdateDate]=CURRENT_TIMESTAMP,[LastUpdateUser]=SYSTEM_USER,[CreatedDate]=CURRENT_TIMESTAMP,[CreatedUser]=SYSTEM_USER'+''''+' From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' flc With(NOLOCK) ' + 'where flc.[FeedLocationId] in (select * from (
select flc.[FeedLocationId] from [DcConfigHub].[dcFeeds].[dcFeedLocationConfig] flc  
left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm 
on flc.[FeedLocationId] = flm.[SourceLocationId] where flm.feedname='+''''+@feedname+''''+'
union all
select flc.[FeedLocationId]  from [DcConfigHub].[dcFeeds].[dcFeedLocationConfig] flc  
left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm 
on flc.[FeedLocationId] = flm.[TargetLocationId] where flm.feedname='+''''+@feedname+''''+') t) '               


EXEC(@UpdateStatment)

INSERT INTO #ScriptTbl 
SELECT 'SET IDENTITY_INSERT [dcFeeds].[dcFeedLocationConfig] OFF;'

--print 'dcFeedLocationConfig'
end 

--Changed

IF EXISTS (select fplc.[ParameterLookupId] from [DcConfigHub].[dcFeeds].[dcFeedParameterLookupConfig] fplc  left join [DcConfigHub].[dcFeeds].[dcFeedParameterMappingConfig] fpmc on fplc.[ParameterLookupId] = fpmc.[ParameterLookupId] left join
[DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fpmc.[FeedToLocationMappingId]  = flm.[FeedToLocationMappingId] where flm.feedname=@feedname) 
begin

SET @schema_name='dcfeeds' 
SET @dbname = 'DcConfigHub'
SET @ComaCol=''                   
SET @UpdateStatment= ''
SET @ColStatment= ''
SET @Counter=1                              
SET @CONDITIONS='' 
SET @CONDITIONSUP=''
SET @Condition =''
DELETE from @COLUMNS
SET @Total_Rows=''


SELECT @Table_name = 'dcFeedParameterLookupConfig' 


INSERT INTO #ScriptTbl 

SELECT 'SET @IDENTITY_Col=IDENT_CURRENT('+''''+'[dcFeeds].[dcFeedParameterLookupConfig]'+''''+');' union all
SELECT 'SET @id=@IDENTITY_Col' union all
SELECT 'if EXISTS(select 1 from [dcFeeds].[dcFeedParameterLookupConfig])
Begin 
set @id = @id +1
END' union all

SELECT 'SET IDENTITY_INSERT [dcFeeds].[dcFeedParameterLookupConfig] ON;'

--Generating update statements
INSERT INTO @COLUMNS                              
SELECT Row_number()Over (Order by ORDINAL_POSITION ) [Count], Column_Name 
FROM DcConfigHub.INformation_schema.columns 
WHERE Column_Name not in ('LastUpdateDate','LastUpdateUser','CreatedDate','CreatedUser','ParameterLookupId')      
 AND Table_schema=@Schema_name AND table_name=@Table_name         


SELECT @Total_Rows= Count(1) 
FROM @COLUMNS                              

SELECT @Table_name= '['+@Table_name+']'                      

SELECT @Schema_name='['+@Schema_name+']'                      

While (@Counter<=@Total_Rows )                              
begin                               
--checking the counter                             

SELECT @ComaCol= @ComaCol+'['+Column_Name+'],'            
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                          

SELECT @CONDITIONS=@CONDITIONS+ ' + Case When fplc.['+Column_Name+'] is null then ''Null'' Else '''''''' + Replace( Convert(varchar(Max),fplc.['+Column_Name+']  ) ,'''''''',''''''''''''  ) +'''''''' end+'+''','''                                                     
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                              


SELECT @CONDITIONSUP=@CONDITIONSUP +Column_Name+' = '+''''+'+'+''''''''''+'+'+'ISNULL(CONVERT(VARCHAR(50) ,'+'fplc.['+Column_Name+']'+'),'+''''+'NULL'+''''+')'+'+'+'''' +''''''+ ','
 FROM @COLUMNS                              
WHERE [Row_number]=@Counter

SET @Counter=@Counter+1                              

End                              

 ---Added logic for duplicate avoid in parameterlookup

 DECLARE @parameterlookup table (row int, ParamterCode varchar(100))
DECLARE @CONDITIONSPLU varchar(max) = ''
SET @Counterls = 1
DECLARE @tmp_ParamterCode varchar(100) = ''

insert into @parameterlookup select Row_number()Over (Order by [ParamterCode] ) [Count],[ParamterCode] from [DcConfigHub].[dcFeeds].[dcFeedParameterLookupConfig]  where [ParameterLookupId] in(select fplc.[ParameterLookupId] from [DcConfigHub].[dcFeeds].[dcFeedParameterLookupConfig] fplc  left join [DcConfigHub].[dcFeeds].[dcFeedParameterMappingConfig] fpmc on fplc.[ParameterLookupId] = fpmc.[ParameterLookupId] left join
[DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fpmc.[FeedToLocationMappingId]  = flm.[FeedToLocationMappingId] where flm.[feedname]=@feedname) 

 SELECT @Total_Rows= Count(1) 
FROM @parameterlookup


INSERT INTO #ScriptTbl 
SELECT '
DECLARE @ParamterCode varchar(100) = NULL;'



While (@Counterls<=@Total_Rows )                              
begin 

SELECT @tmp_ParamterCode=[ParamterCode] from @parameterlookup where [row] =@Counterls

INSERT INTO #ScriptTbl 
SELECT 'IF NOT EXISTS(select 1 from [dcFeeds].[dcFeedParameterLookupConfig] where [ParamterCode]='+''''+@tmp_ParamterCode+''''+')
BEGIN'

SELECT @CONDITIONSPLU= '''INSERT INTO '+@Schema_name+'.'+@Table_name+ '('+@ComaCol+'[lastUpdatedate],[lastupdatEUSER],[CReatedDate],[CreatedUser],[ParameterLookupId])' +' Values( '+'''' + '+'+@CONDITIONS+'+'+''''+ 'CURRENT_TIMESTAMP,SYSTEM_USER,CURRENT_TIMESTAMP,SYSTEM_USER,@id'+''''                              

SELECT @CONDITIONSPLU=@CONDITIONSPLU+'+'+ '''); SET @id=@id + 1'''                                  

SELECT @CONDITIONSPLU= 'INSERT INTO #ScriptTbl  Select distinct '+@CONDITIONSPLU +'From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' fplc With(NOLOCK) ' + '  left join [DcConfigHub].[dcFeeds].[dcFeedParameterMappingConfig] fpmc on fplc.[ParameterLookupId] = fpmc.[ParameterLookupId] left join
[DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fpmc.[FeedToLocationMappingId]  = flm.[FeedToLocationMappingId] where fplc.[ParamterCode]='+''''+@tmp_ParamterCode+''''+'and flm.feedname=''' +@feedname+  ''''                    

                    
Exec(@CONDITIONSPLU)
INSERT INTO #ScriptTbl 
SELECT 'END'
SET @CONDITIONSPLU = ''
SET @Counterls = @Counterls + 1
END

--Generating upadte statements

SET @UpdateStatment = @UpdateStatment + 'UPDATE ' +@schema_name+'.'+  @Table_Name + ' '
SET @UpdateStatment = @UpdateStatment + 'SET' +' ' 

SELECT @UpdateStatment = 'INSERT INTO #ScriptTblupdate  SELECT distinct ' + ''''+ @UpdateStatment+@CONDITIONSUP+'[LastUpdateDate]=CURRENT_TIMESTAMP,[LastUpdateUser]=SYSTEM_USER,[CreatedDate]=CURRENT_TIMESTAMP,[CreatedUser]=SYSTEM_USER'+''''+' From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' fplc With(NOLOCK) ' + '  left join [DcConfigHub].[dcFeeds].[dcFeedParameterMappingConfig] fpmc on fplc.[ParameterLookupId] = fpmc.[ParameterLookupId] left join
[DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fpmc.[FeedToLocationMappingId]  = flm.[FeedToLocationMappingId] where flm.feedname=''' +@feedname+  ''''


EXEC(@UpdateStatment)

INSERT INTO #ScriptTbl 
SELECT 'SET IDENTITY_INSERT [dcFeeds].[dcFeedParameterLookupConfig] OFF;'

--print 'dcFeedParameterLookupConfig'
end 


----code change portion

IF EXISTS (select flmc.feedname from [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flmc  where flmc.feedname=@feedname) 
begin

SET @schema_name='dcfeeds' 
SET @dbname = 'DcConfigHub'
SET @ComaCol=''                   
SET @UpdateStatment= ''
SET @ColStatment= ''
SET @Counter=1                              
SET @CONDITIONS='' 
SET @CONDITIONSUP=''
SET @Condition =''
DELETE from @COLUMNS
SET @Total_Rows=''
DECLARE @CONDITIONsINS varchar(max) = ''



SELECT @Table_name = 'dcFeedToLocationMappingConfig' 

INSERT INTO #ScriptTbl 
SELECT 'SET @IDENTITY_Col=IDENT_CURRENT('+''''+'[dcFeeds].[dcFeedToLocationMappingConfig]'+''''+');' union all
SELECT 'SET @id=@IDENTITY_Col' union all
SELECT 'if EXISTS(select 1 from [dcFeeds].[dcFeedToLocationMappingConfig])
Begin 
set @id = @id +1
END' union all

SELECT 'SET IDENTITY_INSERT [dcFeeds].[dcFeedToLocationMappingConfig] ON;'


--Generating update statements
INSERT INTO @COLUMNS                              
SELECT Row_number()Over (Order by ORDINAL_POSITION ) [Count], Column_Name 
FROM DcConfigHub.INformation_schema.columns 
WHERE Column_Name not in ('LastUpdateDate','LastUpdateUser','CreatedDate','CreatedUser','FeedToLocationMappingId','SourceLocationId','TargetLocationId','FeedApplicationId')      
 AND Table_schema=@Schema_name AND table_name=@Table_name         


SELECT @Total_Rows= Count(1) 
FROM @COLUMNS                              

SELECT @Table_name= '['+@Table_name+']'                      

SELECT @Schema_name='['+@Schema_name+']'                      

While (@Counter<=@Total_Rows )                              
begin                               
--checking the counter                             

SELECT @ComaCol= @ComaCol+'['+Column_Name+'],'            
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                          

SELECT @CONDITIONS=@CONDITIONS+ ' + Case When flmc.['+Column_Name+'] is null then ''Null'' Else '''''''' + Replace( Convert(varchar(Max),flmc.['+Column_Name+']  ) ,'''''''',''''''''''''  ) +'''''''' end+'+''','''                                                     
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                              


SELECT @CONDITIONSUP=@CONDITIONSUP +Column_Name+' = '+''''+'+'+''''''''''+'+'+'ISNULL(CONVERT(VARCHAR(50) ,'+'flmc.['+Column_Name+']'+'),'+''''+'NULL'+''''+')'+'+'+'''' +''''''+ ','
 FROM @COLUMNS                              
WHERE [Row_number]=@Counter

SET @Counter=@Counter+1                              

End                              

--Change Begins
--Building the dynamic Azliniked Service





DECLARE @Inbound_SourceLocationId int
DECLARE @Inbound_TargetLocationId int



DECLARE @tmp_SourceLocationId varchar(100)
DECLARE @tmp_TargetLocationId varchar(100)
DECLARE @tmp_Locationid varchar(100) 

DECLARE @azlinkservice varchar(100)
DECLARE @FeedApplicationName varchar(100)
DECLARE @Counter2 int = 1
DECLARE @locationmappingid table (row int,confid int)
DECLARE @Total_Rowsid int
DECLARE @mapidold varchar(100)


declare @tmptable_FeedToLocationMappingId table (row int ,ftplmpd int ) 

Insert into @tmptable_FeedToLocationMappingId select Row_number()Over (Order by [FeedToLocationMappingId] ) [Count],[FeedToLocationMappingId] from [dcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] where [feedname] =@feedname

SELECT @Total_Rows= Count(1) 
FROM @tmptable_FeedToLocationMappingId

INSERT INTO #ScriptTbl 
SELECT '
DECLARE @Inbound_SourceLocationId varchar(100) = NULL;
DECLARE @Inbound_TargetLocationId varchar(100)= NULL;
DECLARE @Inbound_FeedApplicationId varchar(100)= NULL;' union all 
SELECT 'DECLARE @mapid table (row int identity,oldmapid int,newmapid int)' 

While (@Counter2<=@Total_Rows )                              
begin 

select @mapidold=[ftplmpd] from @tmptable_FeedToLocationMappingId where [row] = @Counter2
INSERT INTO #ScriptTbl 
SELECT 'insert into @mapid (oldmapid,newmapid) values('+@mapidold+',0)' 



SELECT @tmp_Locationid = [ftplmpd] from @tmptable_FeedToLocationMappingId where [row] =@Counter2 

SELECT @Inbound_SourceLocationId =[SourceLocationId],
    @Inbound_TargetLocationId = [TargetLocationId],@FeedApplicationName=[FeedApplicationId]
    from [dcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] 
    where [FeedToLocationMappingId]=@tmp_Locationid and feedname=@feedname


-- fetching the SourceLocationid
IF @Inbound_SourceLocationId IS NOT NULL
BEGIN

SELECT @azlinkservice=[AzLinkedServiceName] from [dcConfigHub].[dcFeeds].[dcFeedLocationConfig] where [FeedLocationId] = @Inbound_SourceLocationId
INSERT INTO #ScriptTbl 
SELECT 'SELECT @Inbound_SourceLocationId =[FeedLocationId] from [dcFeeds].[dcFeedLocationConfig] where [AzLinkedServiceName]='+''''+@azlinkservice+''''

END


IF @Inbound_TargetLocationId IS NOT NULL
BEGIN
-- Fetching the TargetLocationID
SELECT @azlinkservice=[AzLinkedServiceName] from [dcConfigHub].[dcFeeds].[dcFeedLocationConfig] where [FeedLocationId] = @Inbound_TargetLocationId
INSERT INTO #ScriptTbl 
SELECT 'SELECT @Inbound_TargetLocationId =[FeedLocationId] from [dcFeeds].[dcFeedLocationConfig] where [AzLinkedServiceName]='+''''+@azlinkservice+''''

END



IF @FeedApplicationName IS NOT NULL
BEGIN
SELECT distinct @FeedApplicationName=[FeedApplicationName] from [dcConfigHub].[dcFeeds].[dcFeedApplicationConfig] fac join [dcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] fmc on fac.[FeedApplicationId]=fmc.[FeedApplicationId] where [FeedName]=@feedname 
INSERT INTO #ScriptTbl 
SELECT 'SELECT distinct @Inbound_FeedApplicationId =[FeedApplicationId] from [dcFeeds].[dcFeedApplicationConfig] where [FeedApplicationName]='+''''+@FeedApplicationName+''''
END



INSERT INTO #ScriptTbl 
SELECT 'UPDATE @mapid set newmapid=@id where oldmapid='+@mapidold

SELECT @CONDITIONSINS= '''INSERT INTO '+@Schema_name+'.'+@Table_name+ '('+@ComaCol+'[lastUpdatedate],[lastupdatEUSER],[CreatedDate],[CreatedUser],[SourceLocationId],[TargetLocationId],[FeedToLocationMappingId],[FeedApplicationId])' +' Values( '+'''' + '+'+@CONDITIONS+'+'+''''+ 'CURRENT_TIMESTAMP,SYSTEM_USER,CURRENT_TIMESTAMP,SYSTEM_USER,@Inbound_SourceLocationId,@Inbound_TargetLocationId,@id,@Inbound_FeedApplicationId'+''''                              

SELECT @CONDITIONSINS=@CONDITIONSINS+'+'+ '''); SET @id=@id + 1'''                             

SELECT @CONDITIONSINS= 'INSERT INTO #ScriptTbl Select distinct '+@CONDITIONSINS +'From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' flmc With(NOLOCK) ' + '  Where flmc.feedname=''' +@feedname+  '''' +'AND flmc.FeedToLocationMappingId=''' +@tmp_Locationid+  ''''                         

                  
Exec(@CONDITIONSINS)

INSERT INTO #ScriptTbl 

SELECT 'SET @Inbound_SourceLocationId = null' union all 
SELECT 'SET @Inbound_TargetLocationId = null' 



SET @CONDITIONSINS = ''
SET @Counter2=@Counter2+1 


END




--Generating upadte statements

SET @UpdateStatment = @UpdateStatment + 'UPDATE ' +@schema_name+'.'+  @Table_Name + ' '
SET @UpdateStatment = @UpdateStatment + 'SET' +' ' 

SELECT @UpdateStatment = 'INSERT INTO #ScriptTblupdate  SELECT distinct ' + ''''+ @UpdateStatment+@CONDITIONSUP+'[LastUpdateDate]=CURRENT_TIMESTAMP,[LastUpdateUser]=SYSTEM_USER,[CreatedDate]=CURRENT_TIMESTAMP,[CreatedUser]=SYSTEM_USER'+''''+' From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' flmc With(NOLOCK) ' + '   where flmc.feedname=''' +@feedname+  ''''

EXEC(@UpdateStatment)

INSERT INTO #ScriptTbl 
SELECT 'SET IDENTITY_INSERT [dcFeeds].[dcFeedToLocationMappingConfig] OFF;'

INSERT INTO #ScriptTbl 
SELECT 'DECLARE @FeedToLocationMappingId varchar(max);' union all
SELECT ' DECLARE @Inbound_FeedToLocationMappingId varchar(100) = NULL;' union all

SELECT 'SELECT @FeedToLocationMappingId=FeedToLocationMappingId FROM [dcFeeds].[dcFeedToLocationMappingConfig] WHERE [FeedName] =''' +@feedname+  ''''

--print 'dcFeedToLocationMappingConfig'
end  

--- code change ends

-- Changed


IF EXISTS (select fdac.[FeedToLocationMappingId]  from [DcConfigHub].[dcFeeds].[dcFeedDataAlertConfig] fdac  left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fdac.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where flm.feedname=@feedname) 
begin

SET @schema_name='dcfeeds' 
SET @dbname = 'DcConfigHub'
SET @ComaCol=''                   
SET @UpdateStatment= ''
SET @ColStatment= ''
SET @Counter=1                              
SET @CONDITIONS='' 
SET @CONDITIONSUP=''
SET @Condition =''
DELETE from @COLUMNS
SET @Total_Rows=''


SELECT @Table_name = 'dcFeedDataAlertConfig' 

--Generating update statements
INSERT INTO @COLUMNS                              
SELECT Row_number()Over (Order by ORDINAL_POSITION ) [Count], Column_Name 
FROM DcConfigHub.INformation_schema.columns 
WHERE Column_Name not in ('LastUpdateDate','LastUpdateUser','CreatedDate','CreatedUser','FeedToLocationMappingId','AttachmentLocationId')      
 AND Table_schema=@Schema_name AND table_name=@Table_name         


SELECT @Total_Rows= Count(1) 
FROM @COLUMNS                              

SELECT @Table_name= '['+@Table_name+']'                      

SELECT @Schema_name='['+@Schema_name+']'                      

While (@Counter<=@Total_Rows )                              
begin                               
--checking the counter                             

SELECT @ComaCol= @ComaCol+'['+Column_Name+'],'            
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                          

SELECT @CONDITIONS=@CONDITIONS+ ' + Case When fdac.['+Column_Name+'] is null then ''Null'' Else '''''''' + Replace( Convert(varchar(Max),fdac.['+Column_Name+']  ) ,'''''''',''''''''''''  ) +'''''''' end+'+''','''                                                     
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                              


SELECT @CONDITIONSUP=@CONDITIONSUP +Column_Name+' = '+''''+'+'+''''''''''+'+'+'ISNULL(CONVERT(VARCHAR(50) ,'+'fdac.['+Column_Name+']'+'),'+''''+'NULL'+''''+')'+'+'+'''' +''''''+ ','
 FROM @COLUMNS                              
WHERE [Row_number]=@Counter

SET @Counter=@Counter+1                              

End                              

DECLARE @dcFeedDataAlertConfigids table(row int, ftlmapid int,alid varchar)
DECLARE @dcFeedDataAlertConfig table(row int, ftlmapid int)
DECLARE @attach varchar(100)

insert into @dcFeedDataAlertConfigids select Row_number()Over (Order by fdac.[FeedToLocationMappingId] ) [Count], fdac.[FeedToLocationMappingId] ,fdac.[AttachmentLocationId] from [DcConfigHub].[dcFeeds].[dcFeedDataAlertConfig] fdac  left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fdac.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where flm.feedname=@feedname

SET @counter = 1
DECLARE @azlink varchar(100)

SELECT @Total_Rows= Count(1) 
FROM @dcFeedDataAlertConfigids  

INSERT INTO #ScriptTbl 
SELECT'DECLARE @attachemntid varchar(100) = null' 

While (@Counter<=@Total_Rows )                              
begin 
select @mapidold=[ftlmapid] , @attach=[alid] from @dcFeedDataAlertConfigids where [row]=@Counter
select @azlink=[AzLinkedServiceName] from [dcFeeds].[dcFeedLocationConfig] where [FeedLocationId]=@attach
INSERT INTO #ScriptTbl 
SELECT 'select  @FeedToLocationMappingId=[newmapid] from @mapid where oldmapid='+@mapidold 
IF @attach is not null
BEGIN
INSERT INTO #ScriptTbl 
SELECT 'SELECT @attachemntid=[FeedLocationId] from [dcFeeds].[dcFeedLocationConfig] where [AzLinkedServiceName]='+''''+@azlink+''''
END    

SELECT @CONDITIONSIN= '''INSERT INTO '+@Schema_name+'.'+@Table_name+ '('+'[FeedToLocationMappingId],[AttachmentLocationId],'+@ComaCol+'[lastUpdatedate],[lastupdatEUSER],[CReatedDate],[CreatedUser])' +' Values(@FeedToLocationMappingId,@attachemntid,'+'''' + '+'+@CONDITIONS+'+'+''''+ 'CURRENT_TIMESTAMP,SYSTEM_USER,CURRENT_TIMESTAMP,SYSTEM_USER'+''''                              

SELECT @CONDITIONSIN=@CONDITIONSIN+'+'+ ''')'''                              

SELECT @CONDITIONSIN= 'INSERT INTO #ScriptTbl Select distinct '+@CONDITIONSIN +'From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' fdac With(NOLOCK) ' + '  left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fdac.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where fdac.[FeedToLocationMappingId]='+@mapidold+' and flm.feedname=''' +@feedname+  ''''                         

                      
Exec(@CONDITIONSIN)

INSERT INTO #ScriptTbl
SELECT 'SET @FeedToLocationMappingId = null ' union all
SELECT 'SET  @attachemntid = null'

Set @CONDITIONSIN = ''
SET @Counter=@Counter+1
END
--Generating upadte statements

SET @UpdateStatment = @UpdateStatment + 'UPDATE ' +@schema_name+'.'+  @Table_Name + ' '
SET @UpdateStatment = @UpdateStatment + 'SET' +' '    

SELECT @UpdateStatment = 'INSERT INTO #ScriptTblupdate SELECT distinct ' + ''''+ @UpdateStatment+@CONDITIONSUP+'[LastUpdateDate]=CURRENT_TIMESTAMP,[LastUpdateUser]=SYSTEM_USER,[CreatedDate]=CURRENT_TIMESTAMP,[CreatedUser]=SYSTEM_USER,[FeedToLocationMappingId]=@Inbound_FeedToLocationMappingId'+''''+' From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' fdac With(NOLOCK) ' + '   left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fdac.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where flm.feedname=''' +@feedname+  ''''

EXEC(@UpdateStatment)

--print 'dcFeedDataAlertConfig'

end 
  
INSERT INTO #ScriptTbl 
SELECT 'DECLARE @OutBound_FeedToLocationMappingId varchar(100)' 





IF EXISTS (select fdcmc.[FeedDataColumnMappingId]  from [DcConfigHub].[dcFeeds].[dcFeedDataColumnMappingConfig] fdcmc  left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fdcmc.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where flm.feedname=@feedname) 
begin

SET @schema_name='dcfeeds' 
SET @dbname = 'DcConfigHub'
SET @ComaCol=''                   
SET @UpdateStatment= ''
SET @ColStatment= ''
SET @Counter=1                              
SET @CONDITIONS='' 
SET @CONDITIONSUP=''
SET @Condition =''
DELETE from @COLUMNS
SET @Total_Rows=''



SELECT @Table_name = 'dcFeedDataColumnMappingConfig' 

INSERT INTO #ScriptTbl 

SELECT 'SET @IDENTITY_Col=IDENT_CURRENT('+''''+'[dcFeeds].[dcFeedDataColumnMappingConfig]'+''''+');' union all
SELECT 'SET @id=@IDENTITY_Col' union all
SELECT 'if EXISTS(select 1 from [dcFeeds].[dcFeedDataColumnMappingConfig])
Begin 
set @id = @id +1
END' union all

SELECT 'SET IDENTITY_INSERT [dcFeeds].[dcFeedDataColumnMappingConfig] ON;'

--Generating update statements
INSERT INTO @COLUMNS                              
SELECT Row_number()Over (Order by ORDINAL_POSITION ) [Count], Column_Name 
FROM DcConfigHub.INformation_schema.columns 
WHERE Column_Name not in ('LastUpdateDate','LastUpdateUser','CreatedDate','CreatedUser','FeedToLocationMappingId','FeedDataColumnMappingId')      
 AND Table_schema=@Schema_name AND table_name=@Table_name         


SELECT @Total_Rows= Count(1) 
FROM @COLUMNS                              

SELECT @Table_name= '['+@Table_name+']'                      

SELECT @Schema_name='['+@Schema_name+']'                      

While (@Counter<=@Total_Rows )                              
begin                               
--checking the counter                             

SELECT @ComaCol= @ComaCol+'['+Column_Name+'],'            
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                          

SELECT @CONDITIONS=@CONDITIONS+ ' + Case When fdcmc.['+Column_Name+'] is null then ''Null'' Else '''''''' + Replace( Convert(varchar(Max),fdcmc.['+Column_Name+']  ) ,'''''''',''''''''''''  ) +'''''''' end+'+''','''                                                     
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                              


SELECT @CONDITIONSUP=@CONDITIONSUP +Column_Name+' = '+''''+'+'+''''''''''+'+'+'ISNULL(CONVERT(VARCHAR(50) ,'+'fdcmc.['+Column_Name+']'+'),'+''''+'NULL'+''''+')'+'+'+'''' +''''''+ ','
 FROM @COLUMNS                              
WHERE [Row_number]=@Counter

SET @Counter=@Counter+1                              

End                              

 

 DECLARE @tmp_parametermappingtable1 table (row int ,mappingid varchar(100),fdcmid varchar(100))
 DECLARE @tmp_Locationid_id varchar(100) = null
 DECLARE @tmp_Locationid_fdcmid varchar(100) = null
 SET @CONDITIONSINS = ''
 SET @counter = 1
insert into @tmp_parametermappingtable1 select Row_number()Over (Order by [FeedToLocationMappingId] ) [Count],[FeedToLocationMappingId] ,[FeedDataColumnMappingId] from [DcConfigHub].[dcFeeds].[dcFeedDataColumnMappingConfig]  where [FeedDataColumnMappingId] in (select fdcmc.[FeedDataColumnMappingId]  from [DcConfigHub].[dcFeeds].[dcFeedDataColumnMappingConfig] fdcmc  left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fdcmc.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where flm.feedname=@feedname)
SELECT @Total_Rowsid= Count(1) 
FROM @tmp_parametermappingtable1

While (@counter<=@Total_Rowsid )                              
begin

select @tmp_Locationid_id=[mappingid] ,@tmp_Locationid_fdcmid =[fdcmid] from @tmp_parametermappingtable1 where [row]=@counter

INSERT INTO #ScriptTbl
SELECT 'SELECT @OutBound_FeedToLocationMappingId =[newmapid] from @mapid where oldmapid='+@tmp_Locationid_id

SELECT @CONDITIONSINS= '''INSERT INTO '+@Schema_name+'.'+@Table_name+ '( '+'[FeedToLocationMappingId],'+@ComaCol+'[lastUpdatedate],[lastupdatEUSER],[CReatedDate],[CreatedUser],[FeedDataColumnMappingId])' +' Values(@OutBound_FeedToLocationMappingId,'+'''' + '+'+@CONDITIONS+'+'+''''+ 'CURRENT_TIMESTAMP,SYSTEM_USER,CURRENT_TIMESTAMP,SYSTEM_USER,@id'+''''                              

SELECT @CONDITIONSINS=@CONDITIONSINS+'+'+ '''); SET @id=@id + 1'''                              

SELECT @CONDITIONSINS= 'INSERT INTO #ScriptTbl Select distinct '+@CONDITIONSINS +'From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' fdcmc With(NOLOCK) ' + ' left join [dcFeeds].[dcFeedToLocationMappingConfig] flm on fdcmc.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where fdcmc.[FeedDataColumnMappingId]='+''''+@tmp_Locationid_fdcmid+''''+' and flm.feedname='''+@feedname+''''                       

                      
Exec(@CONDITIONSINS)

INSERT INTO #ScriptTbl 
SELECT 'SET @OutBound_FeedToLocationMappingId = null'
SET @CONDITIONSINS = ''
SET @counter = @counter+1
END
--Generating upadte statements

SET @UpdateStatment = @UpdateStatment + 'UPDATE '+@schema_name+'.'+  @Table_Name + ' '
SET @UpdateStatment = @UpdateStatment + 'SET' +' ' 

SELECT @UpdateStatment = 'INSERT INTO #ScriptTblupdate SELECT  distinct ' + ''''+ @UpdateStatment+@CONDITIONSUP+'[LastUpdateDate]=CURRENT_TIMESTAMP,[LastUpdateUser]=SYSTEM_USER,[CreatedDate]=CURRENT_TIMESTAMP,[CreatedUser]=SYSTEM_USER,[FeedToLocationMappingId]=@OutBound_FeedToLocationMappingId,[TargetLocationId]=@Inbound_TargetLocationId,[SourceLocationId]=@Inbound_TargetLocationId'+''''+' From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' fdcmc With(NOLOCK) ' + ' left join [dcFeeds].[dcFeedToLocationMappingConfig] flm on fdcmc.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where flm.feedname=''' +@feedname+  ''''

EXEC(@UpdateStatment)
INSERT INTO #ScriptTbl
SELECT 'SET IDENTITY_INSERT [dcFeeds].[dcFeedDataColumnMappingConfig] OFF;'

--print 'dcFeedDataColumnMappingConfig'
end 


---------


IF EXISTS (select fdtc.[FeedToLocationMappingId]  from [DcConfigHub].[dcFeeds].[dcFeedDataTransformationConfig] fdtc  left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fdtc.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where flm.feedname=@feedname) 
BEGIN

SET @schema_name='dcfeeds' 
SET @dbname = 'DcConfigHub'
SET @ComaCol=''                   
SET @UpdateStatment= ''
SET @ColStatment= ''
SET @Counter=1                              
SET @CONDITIONS='' 
SET @CONDITIONSUP=''
SET @Condition =''
DELETE from @COLUMNS
SET @Total_Rows=''




SELECT @Table_name = 'dcFeedDataTransformationConfig' 

--Generating update statements
INSERT INTO @COLUMNS                              
SELECT Row_number()Over (Order by ORDINAL_POSITION ) [Count], Column_Name 
FROM DcConfigHub.INformation_schema.columns 
WHERE Column_Name not in ('LastUpdateDate','LastUpdateUser','CreatedDate','CreatedUser','FeedToLocationMappingId')      
 AND Table_schema=@Schema_name AND table_name=@Table_name         


SELECT @Total_Rows= Count(1) 
FROM @COLUMNS                              

SELECT @Table_name= '['+@Table_name+']'                      

SELECT @Schema_name='['+@Schema_name+']'                      

While (@Counter<=@Total_Rows )                              
begin                               
--checking the counter                             

SELECT @ComaCol= @ComaCol+'['+Column_Name+'],'            
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                          

SELECT @CONDITIONS=@CONDITIONS+ ' + Case When fdtc.['+Column_Name+'] is null then ''Null'' Else '''''''' + Replace( Convert(varchar(Max),fdtc.['+Column_Name+']  ) ,'''''''',''''''''''''  ) +'''''''' end+'+''','''                                                     
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                              


SELECT @CONDITIONSUP=@CONDITIONSUP +Column_Name+' = '+''''+'+'+''''''''''+'+'+'ISNULL(CONVERT(VARCHAR(50) ,'+'fdtc.['+Column_Name+']'+'),'+''''+'NULL'+''''+')'+'+'+'''' +''''''+ ','
 FROM @COLUMNS                              
WHERE [Row_number]=@Counter

SET @Counter=@Counter+1                              

End                              


 DECLARE @tmp_parametermappingtable_mid table (row int ,mappingid varchar(100),IsManualTransformationaReq varchar(100),TransformationSPName varchar(100),StageTableName varchar(100))
 DECLARE @tmp_Locationid_mid varchar(100) = null
  DECLARE @IsManualTransformationaReq varchar(100) = null
   DECLARE @TransformationSPName varchar(100) = null
    DECLARE @StageTableName varchar(100) = null
 SET @CONDITIONSINS = ''
 SET @counter = 1
insert into @tmp_parametermappingtable_mid select Row_number()Over (Order by fdtc.[FeedToLocationMappingId] ) [Count], fdtc.[FeedToLocationMappingId] ,fdtc.[IsManualTransformationaReq],fdtc.[TransformationSPName],fdtc.[StageTableName] from [DcConfigHub].[dcFeeds].[dcFeedDataTransformationConfig] fdtc  left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fdtc.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where flm.[feedname]=@feedname 

SELECT @Total_Rowsid= Count(1) 
FROM @tmp_parametermappingtable_mid



INSERT INTO #ScriptTbl 
SELECT ' SET @OutBound_FeedToLocationMappingId = null '
While (@counter<=@Total_Rowsid )                              
begin

select @tmp_Locationid_mid=[mappingid],@IsManualTransformationaReq=[IsManualTransformationaReq],@TransformationSPName=[TransformationSPName],@StageTableName=[StageTableName] from @tmp_parametermappingtable_mid where [row]=@counter

INSERT INTO #ScriptTbl
SELECT 'SELECT @OutBound_FeedToLocationMappingId =[newmapid] from @mapid where oldmapid='+@tmp_Locationid_mid


SELECT @CONDITIONSINS= '''INSERT INTO '+@Schema_name+'.'+@Table_name+ '([FeedToLocationMappingId],'+@ComaCol+'[lastUpdatedate],[lastupdatEUSER],[CReatedDate],[CreatedUser])' +' Values(@OutBound_FeedToLocationMappingId, '+'''' + '+'+@CONDITIONS+'+'+''''+ 'CURRENT_TIMESTAMP,SYSTEM_USER,CURRENT_TIMESTAMP,SYSTEM_USER'+''''                              


SELECT @CONDITIONSINS=@CONDITIONSINS+'+'+ ''')'''                              



SELECT @CONDITIONSINS= 'INSERT INTO #ScriptTbl Select  distinct '+@CONDITIONSINS +'From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' fdtc With(NOLOCK) ' + '  left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fdtc.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where fdtc.[FeedToLocationMappingId]='+@tmp_Locationid_mid+' and flm.feedname='''+@feedname+''''    



Exec(@CONDITIONSINS)

INSERT INTO #ScriptTbl
SELECT 'SET @OutBound_FeedToLocationMappingId = null'
SET @CONDITIONSINS = ''
SET @counter = @counter+1
END

--Generating upadte statements

SET @UpdateStatment = @UpdateStatment + 'UPDATE ' +@schema_name+'.'+  @Table_Name + ' '
SET @UpdateStatment = @UpdateStatment + 'SET' +' ' 

SELECT @UpdateStatment = 'INSERT INTO #ScriptTblupdate  SELECT distinct ' + ''''+ @UpdateStatment+@CONDITIONSUP+'[LastUpdateDate]=CURRENT_TIMESTAMP,[LastUpdateUser]=SYSTEM_USER,[CreatedDate]=CURRENT_TIMESTAMP,[CreatedUser]=SYSTEM_USER,[FeedToLocationMappingId]=@OutBound_FeedToLocationMappingId'+''''+' From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' fdtc With(NOLOCK) ' + '   left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fdtc.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where flm.feedname=''' +@feedname+  ''''

EXEC(@UpdateStatment)

--print 'dcFeedDataTransformationConfig'

end 




IF EXISTS (
select flpc.[FeedLocationId]  from [DcConfigHub].[dcFeeds].[dcFeedLocationParameterConfig] flpc  
left join [DcConfigHub].[dcFeeds].[dcFeedLocationConfig] flc  
on flpc.FeedLocationId = flc.FeedLocationId 
left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm 
on flc.[FeedLocationId] = flm.[SourceLocationId] where flm.feedname=@feedname
union all
select flpc.[FeedLocationId]  from [DcConfigHub].[dcFeeds].[dcFeedLocationParameterConfig] flpc  
left join [DcConfigHub].[dcFeeds].[dcFeedLocationConfig] flc  
on flpc.FeedLocationId = flc.FeedLocationId 
left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm 
on flc.[FeedLocationId] = flm.[TargetLocationId] where flm.feedname=@feedname
) 
BEGIN

SET @schema_name='dcfeeds' 
SET @dbname = 'DcConfigHub'
SET @ComaCol=''                   
SET @UpdateStatment= ''
SET @ColStatment= ''
SET @Counter=1                              
SET @CONDITIONS='' 
SET @CONDITIONSUP=''
SET @Condition =''
DELETE from @COLUMNS
SET @Total_Rows=''


SELECT @Table_name = 'dcFeedLocationParameterConfig' 

--Generating update statements
INSERT INTO @COLUMNS                              
SELECT Row_number()Over (Order by ORDINAL_POSITION ) [Count], Column_Name 
FROM DcConfigHub.INformation_schema.columns 
WHERE Column_Name not in ('LastUpdateDate','LastUpdateUser','CreatedDate','CreatedUser','FeedLocationId')      
 AND Table_schema=@Schema_name AND table_name=@Table_name         

INSERT INTO #ScriptTbl 

SELECT 'SET @id=IDENT_CURRENT('+''''+'[dcFeeds].[dcFeedLocationConfig]'+''''+')' union all
SELECT 'if EXISTS(select 1 from [dcFeeds].[dcFeedLocationConfig])
Begin 
set @id = @id +1
END' 

SELECT @Total_Rows= Count(1) 
FROM @COLUMNS                              

SELECT @Table_name= '['+@Table_name+']'                      

SELECT @Schema_name='['+@Schema_name+']'                      

While (@Counter<=@Total_Rows )                              
begin                               
--checking the counter                             

SELECT @ComaCol= @ComaCol+'['+Column_Name+'],'            
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                          

SELECT @CONDITIONS=@CONDITIONS+ ' + Case When flpc.['+Column_Name+'] is null then ''Null'' Else '''''''' + Replace( Convert(varchar(Max),flpc.['+Column_Name+']  ) ,'''''''',''''''''''''  ) +'''''''' end+'+''','''                                                     
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                              


SELECT @CONDITIONSUP=@CONDITIONSUP +Column_Name+' = '+''''+'+'+''''''''''+'+'+'ISNULL(CONVERT(VARCHAR(50) ,'+'flpc.['+Column_Name+']'+'),'+''''+'NULL'+''''+')'+'+'+'''' +''''''+ ','
 FROM @COLUMNS                              
WHERE [Row_number]=@Counter

SET @Counter=@Counter+1                              

End                              

--ADD New Logic
SET @Counter2 = 1
SET @CONDITIONSINS = ''
DECLARE @ParameterLookupName varchar(100) = null 
DECLARE @ParameterValue varchar(100) = null

DECLARE @parametermappingid table (row int,confid int, ParameterValue varchar(100),ParameterLookupName varchar(100))
insert into @parametermappingid select Row_number()Over (Order by [FeedLocationId]  ) [Count], [FeedLocationId] ,[ParameterValue] ,[ParameterLookupName] from [DcConfigHub].[dcFeeds].[dcFeedLocationParameterConfig]  where [FeedLocationId] in (
select flpc.[FeedLocationId]  from [DcConfigHub].[dcFeeds].[dcFeedLocationParameterConfig] flpc  
left join [DcConfigHub].[dcFeeds].[dcFeedLocationConfig] flc  
on flpc.FeedLocationId = flc.FeedLocationId 
left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm 
on flc.[FeedLocationId] = flm.[SourceLocationId] where flm.feedname=@feedname
union all
select flpc.[FeedLocationId]  from [DcConfigHub].[dcFeeds].[dcFeedLocationParameterConfig] flpc  
left join [DcConfigHub].[dcFeeds].[dcFeedLocationConfig] flc  
on flpc.FeedLocationId = flc.FeedLocationId 
left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm 
on flc.[FeedLocationId] = flm.[TargetLocationId] where flm.feedname=@feedname)


SELECT @Total_Rows= Count(1) 
FROM @parametermappingid

INSERT INTO #ScriptTbl 
SELECT '
DECLARE @Outbound_FeedLocationId varchar(100) = NULL;' 


While (@Counter2<=@Total_Rows )                              
begin 

select @tmp_Locationid=[confid] , @ParameterValue= [ParameterValue],@ParameterLookupName=[ParameterLookupName] from @parametermappingid where [row]=@Counter2


-- fetching the SourceLocationid
IF @tmp_Locationid IS NOT NULL
BEGIN

SELECT @azlinkservice=[AzLinkedServiceName] from [dcConfigHub].[dcFeeds].[dcFeedLocationConfig] where [FeedLocationId] = @tmp_Locationid
INSERT INTO #ScriptTbl 
SELECT 'SELECT @Outbound_FeedLocationId =[FeedLocationId] from [dcFeeds].[dcFeedLocationConfig] where [AzLinkedServiceName]='+''''+@azlinkservice+''''

END


--Added Duplicate content check
INSERT INTO #ScriptTbl
SELECT 'IF NOT EXISTS(select 1 from [dcFeeds].[dcFeedLocationParameterConfig]  where [ParameterLookupName]='+''''+@ParameterLookupName+''''+' AND [ParameterValue]='+''''+@ParameterValue+''''+' AND [FeedLocationId]=@Outbound_FeedLocationId)
BEGIN'

SELECT @CONDITIONSINS= '''INSERT INTO '+@Schema_name+'.'+@Table_name+ '([FeedLocationId],'+@ComaCol+'[lastUpdatedate],[lastupdatEUSER],[CReatedDate],[CreatedUser])' +' Values(@Outbound_FeedLocationId,'+'''' + '+'+@CONDITIONS+'+'+''''+ 'CURRENT_TIMESTAMP,SYSTEM_USER,CURRENT_TIMESTAMP,SYSTEM_USER'+''''                              

SELECT @CONDITIONSINS=@CONDITIONSINS+'+'+ ''')'''                              

SELECT @CONDITIONSINS= 'INSERT INTO #ScriptTbl Select distinct '+@CONDITIONSINS+'From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' flpc With(NOLOCK) ' + ' where flpc.[ParameterLookupName]='+''''+@ParameterLookupName+''''+' AND flpc.[ParameterValue]='+''''+@ParameterValue+''''+'AND [FeedLocationId] ='+@tmp_Locationid              

                 
Exec(@CONDITIONSINS)


INSERT INTO #ScriptTbl
SELECT 'END' union all 
SELECT 'SET @Outbound_FeedLocationId = null'
SET @CONDITIONSINS = ''
SET @Counter2=@Counter2+1
END

--Generating upadte statements

SET @UpdateStatment = @UpdateStatment + 'UPDATE ' +@schema_name+'.'+  @Table_Name + ' '
SET @UpdateStatment = @UpdateStatment + 'SET' +' ' 

SELECT @UpdateStatment = 'INSERT INTO #ScriptTblupdate SELECT distinct ' + ''''+ @UpdateStatment+@CONDITIONSUP+'[LastUpdateDate]=CURRENT_TIMESTAMP,[LastUpdateUser]=SYSTEM_USER,[CreatedDate]=CURRENT_TIMESTAMP,[CreatedUser]=SYSTEM_USER,[FeedLocationId]=@Inbound_SourceLocationId'+''''+' From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' flpc With(NOLOCK) ' + ' where flpc.[FeedLocationId] in (select * from (
select flpc.[FeedLocationId]  from [DcConfigHub].[dcFeeds].[dcFeedLocationParameterConfig] flpc  
left join [DcConfigHub].[dcFeeds].[dcFeedLocationConfig] flc  
on flpc.FeedLocationId = flc.FeedLocationId 
left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm 
on flc.[FeedLocationId] = flm.[SourceLocationId] where flm.feedname='+''''+@feedname+''''+' 
union all
select flpc.[FeedLocationId]  from [DcConfigHub].[dcFeeds].[dcFeedLocationParameterConfig] flpc  
left join [DcConfigHub].[dcFeeds].[dcFeedLocationConfig] flc  
on flpc.FeedLocationId = flc.FeedLocationId 
left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm 
on flc.[FeedLocationId] = flm.[TargetLocationId] where flm.feedname='+''''+@feedname+''''+' 
) t)'   

EXEC(@UpdateStatment)

--print 'dcFeedLocationParameterConfig'
end 



IF EXISTS (select fpmcp.[FeedToLocationMappingId]  from [DcConfigHub].[dcFeeds].[dcFeedParameterMappingConfig] fpmcp  left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fpmcp.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where flm.feedname=@feedname) 
BEGIN

SET @schema_name='dcfeeds' 
SET @dbname = 'DcConfigHub'
SET @ComaCol=''                   
SET @UpdateStatment= ''
SET @ColStatment= ''
SET @Counter=1                              
SET @CONDITIONS='' 
SET @CONDITIONSUP=''
SET @Condition =''
DELETE from @COLUMNS
SET @Total_Rows=''



SELECT @Table_name = 'dcFeedParameterMappingConfig' 

--Generating update statements
INSERT INTO @COLUMNS                              
SELECT Row_number()Over (Order by ORDINAL_POSITION ) [Count], Column_Name 
FROM DcConfigHub.INformation_schema.columns 
WHERE Column_Name not in ('LastUpdateDate','LastUpdateUser','CreatedDate','CreatedUser','FeedToLocationMappingId','ParameterLookupId')      
 AND Table_schema=@Schema_name AND table_name=@Table_name         




SELECT @Total_Rows= Count(1) 
FROM @COLUMNS                              

SELECT @Table_name= '['+@Table_name+']'                      

SELECT @Schema_name='['+@Schema_name+']'                      

While (@Counter<=@Total_Rows )                              
begin                               
--checking the counter                             

SELECT @ComaCol= @ComaCol+'['+Column_Name+'],'            
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                          

SELECT @CONDITIONS=@CONDITIONS+ ' + Case When fpmcp.['+Column_Name+'] is null then ''Null'' Else '''''''' + Replace( Convert(varchar(Max),fpmcp.['+Column_Name+']  ) ,'''''''',''''''''''''  ) +'''''''' end+'+''','''                                                     
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                              


SELECT @CONDITIONSUP=@CONDITIONSUP +Column_Name+' = '+''''+'+'+''''''''''+'+'+'ISNULL(CONVERT(VARCHAR(50) ,'+'fpmcp.['+Column_Name+']'+'),'+''''+'NULL'+''''+')'+'+'+'''' +''''''+ ','
 FROM @COLUMNS                              
WHERE [Row_number]=@Counter

SET @Counter=@Counter+1                              

End                              

DECLARE @Income_FeedToLocationMappingId varchar(100) = NULL
 DECLARE @Income_ParameterLookupId varchar(100) = NULL
 DECLARE @ParamterCode varchar(100) = null 
 DECLARE @description varchar(100) = null 
 DECLARE @ExecutionOrder varchar(100) = null 
 DECLARE @CONDITIONSPINS varchar(max) = ''
 DECLARE @tmp_parametermappingtable table (row int ,mappingid varchar(100),lookupid varchar(100))
 DECLARE @tmp_paralookupid varchar(100) = null 
 SET @counter2 = 1

insert into @tmp_parametermappingtable select  Row_number()Over (Order by [FeedToLocationMappingId] ) [Count], [FeedToLocationMappingId] ,[ParameterLookupId]
   from [DcConfigHub].[dcFeeds].[dcFeedParameterMappingConfig] where [FeedToLocationMappingId]  in 
(select distinct fpmcp.[FeedToLocationMappingId] 
from  [DcConfigHub].[dcFeeds].[dcFeedParameterMappingConfig] fpmcp  
left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm 
on fpmcp.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] 
where flm.feedname=@feedname) 


 SELECT @Total_Rows= Count(1) 
FROM @tmp_parametermappingtable

INSERT INTO #ScriptTbl 
SELECT '

DECLARE @Income_FeedToLocationMappingId varchar(100)= NULL;
DECLARE @Income_ParameterLookupId varchar(100)= NULL;' 


While (@Counter2<=@Total_Rows )                              
begin 

SELECT @tmp_Locationid = [mappingid],@tmp_paralookupid=[lookupid] from @tmp_parametermappingtable where [row]=@Counter2 ;

SELECT @ParamterCode=[ParamterCode] from [dcFeeds].[dcFeedParameterLookupConfig] where [ParameterLookupId]=@tmp_paralookupid;

INSERT INTO #ScriptTbl
SELECT 'SELECT distinct @Income_FeedToLocationMappingId=[newmapid] from @mapid where oldmapid='+@tmp_Locationid union all
select 'SELECT @Income_ParameterLookupId=[ParameterLookupId] from [dcFeeds].[dcFeedParameterLookupConfig] where [ParamterCode]='+''''+@ParamterCode+''''





--INSERT INTO #ScriptTbl 
--


SELECT @CONDITIONSPINS= '''INSERT INTO '+@Schema_name+'.'+@Table_name+ '([FeedToLocationMappingId],[ParameterLookupId],'+@ComaCol+'[lastUpdatedate],[lastupdatEUSER],[CReatedDate],[CreatedUser])' +' Values( @Income_FeedToLocationMappingId,@Income_ParameterLookupId,'+'''' + '+'+@CONDITIONS+'+'+''''+ 'CURRENT_TIMESTAMP,SYSTEM_USER,CURRENT_TIMESTAMP,SYSTEM_USER'+''''                              

SELECT @CONDITIONSPINS=@CONDITIONSPINS+'+'+ ''')'''                              

SELECT @CONDITIONSPINS= 'INSERT INTO #ScriptTbl Select distinct '+@CONDITIONSPINS +'From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' fpmcp With(NOLOCK) ' + ' left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fpmcp.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where fpmcp.[FeedToLocationMappingId]='+''''+@tmp_Locationid+''''+' and fpmcp.ParameterLookupId ='+''''+@tmp_paralookupid+''''+'and flm.feedname='''+@feedname+''''                         

                      
                     
Exec(@CONDITIONSPINS)

INSERT INTO #ScriptTbl
SELECT 'SET @Income_FeedToLocationMappingId = null' union all 
SELECT 'SET @Income_ParameterLookupId= null'

set @CONDITIONSPINS = ''
set @Counter2=@Counter2 + 1
end
    



--Generating upadte statements

SET @UpdateStatment = @UpdateStatment + 'UPDATE ' +@schema_name+'.'+  @Table_Name + ' '
SET @UpdateStatment = @UpdateStatment + 'SET' +' ' 

SELECT @UpdateStatment = 'INSERT INTO #ScriptTblupdate SELECT distinct ' + ''''+ @UpdateStatment+@CONDITIONSUP+'[LastUpdateDate]=CURRENT_TIMESTAMP,[LastUpdateUser]=SYSTEM_USER,[CreatedDate]=CURRENT_TIMESTAMP,[CreatedUser]=SYSTEM_USER,[FeedToLocationMappingId]=@Inbound_FeedToLocationMappingId'+''''+' From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' fpmcp With(NOLOCK) ' + '  left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on fpmcp.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where flm.feedname=''' +@feedname+  ''''

EXEC(@UpdateStatment)

--print 'dcFeedParameterMappingConfig'


end 



IF EXISTS (select sfdc.[FeedToLocationMappingId]  from [DcConfigHub].[dcFeeds].[dcStgFeedDynamicConfiguration] sfdc  left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on sfdc.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where flm.feedname=@feedname) 
BEGIN

SET @schema_name='dcfeeds' 
SET @dbname = 'DcConfigHub'
SET @ComaCol=''                   
SET @UpdateStatment= ''
SET @ColStatment= ''
SET @Counter=1                              
SET @CONDITIONS='' 
SET @CONDITIONSUP=''
SET @Condition =''
DELETE from @COLUMNS
SET @Total_Rows=''




SELECT @Table_name = 'dcStgFeedDynamicConfiguration' 

--Generating update statements
INSERT INTO @COLUMNS                              
SELECT Row_number()Over (Order by ORDINAL_POSITION ) [Count], Column_Name 
FROM DcConfigHub.INformation_schema.columns 
WHERE Column_Name not in ('LastUpdateDate','LastUpdateUser','CreatedDate','CreatedUser','FeedToLocationMappingId')      
 AND Table_schema=@Schema_name AND table_name=@Table_name         


SELECT @Total_Rows= Count(1) 
FROM @COLUMNS                              

SELECT @Table_name= '['+@Table_name+']'                      

SELECT @Schema_name='['+@Schema_name+']'                      

While (@Counter<=@Total_Rows )                              
begin                               
--checking the counter                             

SELECT @ComaCol= @ComaCol+'['+Column_Name+'],'            
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                          

SELECT @CONDITIONS=@CONDITIONS+ ' + Case When sfdc.['+Column_Name+'] is null then ''Null'' Else '''''''' + Replace( Convert(varchar(Max),sfdc.['+Column_Name+']  ) ,'''''''','''''''''''' ) +'''''''' end+'+''','''                                                     
FROM @COLUMNS                              
WHERE [Row_number]=@Counter                              


SELECT @CONDITIONSUP=@CONDITIONSUP +Column_Name+' = '+''''+'+'+''''''''''+'+'+'ISNULL(CONVERT(VARCHAR(50) ,'+'sfdc.['+Column_Name+']'+'),'+''''+'NULL'+''''+')'+'+'+'''' +''''''+ ','
 FROM @COLUMNS                              
WHERE [Row_number]=@Counter

SET @Counter=@Counter+1                              

End                              


DECLARE @tmp_parametermappingtable_dc table (row int ,mappingid varchar(100))
 DECLARE @tmp_Locationid_dc varchar(100) = null
 SET @CONDITIONSINS = ''
 SET @counter = 1
insert into @tmp_parametermappingtable_dc select Row_number()Over (Order by sfdc.[FeedToLocationMappingId] ) [Count], sfdc.[FeedToLocationMappingId]  from [DcConfigHub].[dcFeeds].[dcStgFeedDynamicConfiguration] sfdc  left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on sfdc.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where flm.feedname=@feedname

SELECT @Total_Rowsid= Count(1) 
FROM @tmp_parametermappingtable_dc

INSERT INTO #ScriptTbl 
SELECT ' SET @OutBound_FeedToLocationMappingId = null '
While (@counter<=@Total_Rowsid )                              
begin

select @tmp_Locationid_dc=[mappingid] from @tmp_parametermappingtable_dc where [row]=@counter

INSERT INTO #ScriptTbl
SELECT 'SELECT @Inbound_FeedToLocationMappingId =[newmapid] from @mapid where oldmapid='+@tmp_Locationid_dc

   

SELECT @CONDITIONSINS= '''INSERT INTO '+@Schema_name+'.'+@Table_name+ '([FeedToLocationMappingId],'+@ComaCol+'[lastUpdatedate],[lastupdatEUSER],[CReatedDate],[CreatedUser])' +' Values( @Inbound_FeedToLocationMappingId,'+'''' + '+'+@CONDITIONS+'+'+''''+ 'CURRENT_TIMESTAMP,SYSTEM_USER,CURRENT_TIMESTAMP,SYSTEM_USER'+''''                              

SELECT @CONDITIONSINS=@CONDITIONSINS+'+'+ ''')'''                              

SELECT @CONDITIONSINS= 'INSERT INTO #ScriptTbl Select distinct '+@CONDITIONSINS +'From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' sfdc With(NOLOCK) ' + ' left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on sfdc.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where sfdc.[FeedToLocationMappingId]='+@tmp_Locationid_dc+' and flm.feedname='''+@feedname+''''                      

                      
Exec(@CONDITIONSINS)

INSERT INTO #ScriptTbl
SELECT 'SET @Inbound_FeedToLocationMappingId = null'
SET @CONDITIONSINS = ''
SET @counter = @counter +1
end
--Generating upadte statements

SET @UpdateStatment = @UpdateStatment + 'UPDATE ' +@schema_name+'.'+  @Table_Name + ' '
SET @UpdateStatment = @UpdateStatment + 'SET' +' ' 

SELECT @UpdateStatment = 'INSERT INTO #ScriptTblupdate  SELECT distinct ' + ''''+ @UpdateStatment+@CONDITIONSUP+'[LastUpdateDate]=CURRENT_TIMESTAMP,[LastUpdateUser]=SYSTEM_USER,[CreatedDate]=CURRENT_TIMESTAMP,[CreatedUser]=SYSTEM_USER,[FeedToLocationMappingId]=@Inbound_FeedToLocationMappingId'+''''+' From  ' +@dbname+'.'+@Schema_name+'.'+@Table_name+' sfdc With(NOLOCK) ' + '   left join [DcConfigHub].[dcFeeds].[dcFeedToLocationMappingConfig] flm on sfdc.[FeedToLocationMappingId] = flm.[FeedToLocationMappingId] where flm.feedname=''' +@feedname+  ''''

EXEC(@UpdateStatment)

--print 'dcStgFeedDynamicConfiguration'

end 

INSERT INTO #ScriptTbl 
SELECT     'COMMIT TRANSACTION
 END TRY

  BEGIN CATCH
   ROLLBACK TRANSACTION;
   SET IDENTITY_INSERT [dcFeeds].[dcFeedApplicationConfig] OFF;
SET IDENTITY_INSERT [dcFeeds].[dcFeedLocationConfig] OFF;
SET IDENTITY_INSERT [dcFeeds].[dcFeedParameterLookupConfig] OFF;
SET IDENTITY_INSERT [dcFeeds].[dcFeedToLocationMappingConfig] OFF;
   THROW
   END CATCH'
DECLARE @update table (row int identity, query varchar(max))
SET @Counter = 1
SELECT @Total_Rows= Count(1) 
FROM #ScriptTblupdate

while(@Counter<=@Total_Rows)
BEGIN
insert into @update
select replace(query,'''NULL''','NULL') from #ScriptTblupdate where [row]= @Counter 
SET @Counter = @Counter + 1
END

   select QUERY from #ScriptTbl order by [row] ASC
  -- select * from @update  order by [row] ASC 

GO