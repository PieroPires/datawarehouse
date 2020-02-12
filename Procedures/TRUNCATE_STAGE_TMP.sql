DECLARE @DeleteTableStatement NVARCHAR(MAX)
DECLARE Cur CURSOR READ_ONLY
FOR
        SELECT  'TRUNCATE TABLE [' + TABLE_CATALOG + '].[' + TABLE_SCHEMA + '].[' + TABLE_NAME + ']'
        FROM    [INFORMATION_SCHEMA].[TABLES]
        WHERE   TABLE_SCHEMA = 'VAGAS_DW'
                AND TABLE_TYPE = 'BASE TABLE'
				AND TABLE_CATALOG = 'Stage'

OPEN Cur
FETCH NEXT FROM Cur INTO @DeleteTableStatement
WHILE @@FETCH_STATUS = 0
      BEGIN
            PRINT 'Executing ' + @DeleteTableStatement
            EXECUTE sp_executesql @DeleteTableStatement
            FETCH NEXT FROM Cur INTO @DeleteTableStatement
      END
CLOSE Cur
DEALLOCATE Cur