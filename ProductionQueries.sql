
declare @environment nvarchar(100) = (Select case when @@SERVERNAME = 'solver-au-southeast-production' then 'AU'
											when @@servername = 'solver-production-north-eu' then 'EU'
											when @@servername = 'solver-ca-central-production' then 'CA'
											when @@servername = 'solver-uae-north-production' then 'AE'
											when @@servername = 'solver-production' then 'US' end as Environment
									) 
select @environment


declare @sql nvarchar(max) 
	,@sql1 nvarchar(max)
	,@sql2 nvarchar(max)

SET @sql = ''
SET @sql1 = ''
SET @sql2 = ''


SELECT @sql = 'merge d_Dim2 t' +char(13)+
			'USING ('

SELECT @sql1 =  @sql1 + 
    'SELECT ''' + CAST(t.Id AS NVARCHAR(50)) + ''' AS Code, ' +
           '''' + replace(t.name,'''','''''') + ''' AS Description, ' +
           '''' + CAST(t.customerid AS NVARCHAR(50)) + ''' AS CustomerID, ' +
           '''' + @environment + ''' AS Environment, ' +
		   --'''' + l.CrmId + ''' AS CRMId, ' +
           '''' + ISNULL(replace(c.name,'''',''''''), '') + ''' AS CustomerName ' + CHAR(13) + 'UNION ALL' + CHAR(13)
FROM Tenants t
LEFT OUTER JOIN Customers c ON CAST(c.Id AS NVARCHAR(36)) = CAST(t.CustomerId AS NVARCHAR(36))
LEFT OUTER JOIN InstalledLicenses l ON l.CustomerId = t.CustomerId 
where T.name not in ('Template_Marketplace')

IF LEN(@sql1) >= 10
    SET @sql1 = LEFT(@sql1, LEN(@sql1) - 10)  -- remove last "UNION ALL"


SET @sql2 = @sql +@sql1 + ') s'+char(13)+
	'on t.Code = s.Code and t.UDF002 = s.Environment' +char(13)+
	'when matched then update set t.Description = s.Description, t.UDF007 = s.CustomerName , t.updatedOn = getutcdate()'+Char(13)+
	'when NOT MATCHED by target then insert (Code,Description,Alias,UDF007,UDF002,UDF008,CreatedOn,UpdatedOn)'+Char(13)+
	'VALUES (s.Code,s.Description,s.CustomerId,s.CustomerName,s.Environment,getutcdate(),getutcdate(),getutcdate())'+char(13)+
	'WHEN NOT MATCHED BY source AND t.UDF002 = '''+@environment+''' then update set t.UDF006 = ''Yes'', t.UDF009 = getutcdate(), t.updatedOn = getutcdate()'+char(13)+
	'output $action, inserted.Code, deleted.Description as orgDesc, inserted.Description, deleted.udf002, inserted.udf002, deleted.udf006, inserted.UDF006 ,deleted.udf007, inserted.UDF007, deleted.UDF008, inserted.UDF008, inserted.UDF009 ;'+Char(13)
	
select cast(@sql2 as ntext)