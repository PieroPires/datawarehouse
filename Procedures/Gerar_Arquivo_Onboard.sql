declare  @SQL nvarchar(1000), 
         @ArqExporta Varchar(100),
         @NomeProcedure varchar(100)

set @ArqExporta = 'Z:\Scripts\TMP\Tail\Export\TailTarget_'  + convert(char(8), getdate(), 112) + '.csv'
set @SQL =  'bcp "select * from Export.TailTarget.Exportacao" queryout "' + @ArqExporta 
            + '" -S ' + 'SRV-SQLMIRROR05' + ' -T -c -C ACP'
--select @SQL
exec master..xp_cmdshell @SQL

/*
declare  @SQL nvarchar(1000), 
         @ArqExporta Varchar(100),
         @NomeProcedure varchar(100)

set @ArqExporta = 'c:\Export\TailTarget\TailTarget_'  + convert(char(8), getdate(), 112) + '.txt'
set @SQL =  'bcp "select * from Export.TailTarget.Exportacao" queryout "' + @ArqExporta 
            + '" -S ' + 'SRV-SQLMIRROR02' + ' -T -c -C ACP'
--select @SQL
exec master..xp_cmdshell @SQL
*/

DECLARE @CMD VARCHAR(8000)

-- MAPEAMENTO
SET @CMD = 'net use t: \\srv-fs02.vagas-prod.net\site\inetpub\vagassftp\Tailtarget /user:vagas-prod\usr_sqlmirror01 "P@ssword01"'
EXEC MASTER.DBO.XP_CMDSHELL @CMD

-- COPIAR

DECLARE @CMD VARCHAR(8000)

SET @CMD = 'xcopy Z:\Scripts\TMP\Tail\Export\*.csv t: /d'
EXEC MASTER.DBO.XP_CMDSHELL @CMD

DECLARE @CMD VARCHAR(8000)

-- DESMAPEAR
SET @CMD = 'net use t: /delete /y'
EXEC MASTER.DBO.XP_CMDSHELL @CMD