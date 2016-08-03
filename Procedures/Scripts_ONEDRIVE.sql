USE [VAGAS_DW]
GO

/****** Object:  StoredProcedure [ONEDRIVE].[SPR_Download_Arquivo_OneDrive]    Script Date: 11/01/2016 18:10:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [ONEDRIVE].[SPR_Download_Arquivo_OneDrive] 
@PathOneDrive VARCHAR(100),
@PathIN VARCHAR(100) = 'M:\Projetos\Onedrive_PowerShell_Scripts\IN'

AS
SET NOCOUNT ON

-- Tabela LOG
CREATE TABLE #RESULT (ID_RESULT SMALLINT IDENTITY PRIMARY KEY, OUTPUT VARCHAR(MAX))

DECLARE @Id_OnedriveFile SMALLINT, @CMD VARCHAR(8000),@Access_Token VARCHAR(8000) = ''

-- Pegar último token gerado
SELECT TOP 1 @Access_Token = Access_Token FROM ONEDRIVE.Onedrive_Token ORDER BY Data_Solicitacao DESC

SET @CMD = 'powershell.exe -version 3.0 M:\Projetos\Onedrive_PowerShell_Scripts\OneDrive_Download_File.ps1 -access_token "' + @Access_Token + '"' +
		' -pathOneDrive \"' + @PathOneDrive + '\" -pathIN "' + @PathIN + '"'

-- Download
--PRINT @CMD
INSERT INTO #RESULT
EXEC MASTER.DBO.XP_CMDSHELL @CMD

--SELECT * FROM #RESULT

TRUNCATE TABLE #RESULT


GO

/****** Object:  StoredProcedure [ONEDRIVE].[SPR_GerarToken_OneDrive]    Script Date: 11/01/2016 18:10:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [ONEDRIVE].[SPR_GerarToken_OneDrive]
AS
SET NOCOUNT ON 

-- Tabela LOG
CREATE TABLE #RESULT (ID_RESULT SMALLINT IDENTITY PRIMARY KEY, OUTPUT VARCHAR(MAX))

DECLARE @Refresh_Token VARCHAR(8000) = '',@Access_Token VARCHAR(8000) = '',@CMD VARCHAR(8000)	   

SELECT TOP 1 @Refresh_Token = Refresh_Token
FROM ONEDRIVE.Onedrive_Token
ORDER BY Data_Solicitacao DESC

SET @Refresh_Token = REPLACE(@Refresh_Token ,'$','`$')
SET @CMD = 'powershell.exe -version 3.0 M:\Projetos\Onedrive_PowerShell_Scripts\OneDrive_Token.ps1 -refresh_token "' + @Refresh_Token + '" '

-- Control token (access and refresh)
INSERT INTO #RESULT
EXEC MASTER.DBO.XP_CMDSHELL @CMD

DELETE FROM #RESULT WHERE OUTPUT IS NULL

DECLARE @ID_RESULT SMALLINT,@OUTPUT VARCHAR(8000),@FLAG_REFRESH_TOKEN BIT = 0
SET @Refresh_Token = ''

SELECT TOP 1 @ID_RESULT = ID_RESULT,@OUTPUT = OUTPUT
FROM #RESULT
ORDER BY ID_RESULT ASC

WHILE @@ROWCOUNT > 0
BEGIN

	IF CHARINDEX('refresh_token=',@OUTPUT) > 0
		SET @FLAG_REFRESH_TOKEN = 1

	IF @FLAG_REFRESH_TOKEN = 0
		SET @Access_Token = @Access_Token + @OUTPUT
	ELSE
		SET @Refresh_Token = @Refresh_Token + @OUTPUT
	
	SELECT TOP 1 @ID_RESULT = ID_RESULT,@OUTPUT = OUTPUT
	FROM #RESULT
	WHERE ID_RESULT > @ID_RESULT
	ORDER BY ID_RESULT ASC

END	

-- $ é uma palavra chave no powershell e precisamos trata-la antes de passar para o .ps1
SET @Refresh_Token = REPLACE(REPLACE(@Refresh_Token ,'$','`$'),'refresh_token=','')
SET @Access_Token = REPLACE(REPLACE(@Access_Token ,'$','`$'),'access_token=','')

--SET @Nome_Arquivo = 'TESTE_LUIZ.XLSX'
--SET @Path = 'D:\Teste_EXCEL_OneDrive.xlsx'

-- Novo Refresh Token
INSERT INTO ONEDRIVE.Onedrive_Token (Refresh_Token,Access_Token) VALUES (@Refresh_Token,@Access_Token)

GO

/****** Object:  StoredProcedure [ONEDRIVE].[SPR_Limpar_Diretorio_IN_OUT]    Script Date: 11/01/2016 18:10:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [ONEDRIVE].[SPR_Limpar_Diretorio_IN_OUT] @Diretorio_IN_OUT VARCHAR(255) = 'M:\Projetos\Onedrive_PowerShell_Scripts'
AS
SET NOCOUNT ON

DECLARE @CMD VARCHAR(8000)

SET @CMD = 'DEL ' + @Diretorio_IN_OUT + '\IN\*.xlsx /F /Q' -- limpar arquivos .xlsx 
EXEC master.DBO.XP_CMDSHELL @CMD

SET @CMD = 'DEL ' + @Diretorio_IN_OUT + '\IN\*.xlsx /AH /Q' -- limpar arquivos .xlsx ocultos
EXEC master.DBO.XP_CMDSHELL @CMD

SET @CMD = 'DEL ' + @Diretorio_IN_OUT + '\OUT\*.xlsx /F /Q' -- limpar arquivos .xlsx 
EXEC master.DBO.XP_CMDSHELL @CMD

SET @CMD = 'DEL ' + @Diretorio_IN_OUT + '\OUT\*.xlsx /AH /Q' -- limpar arquivos .xlsx ocultos
EXEC master.DBO.XP_CMDSHELL @CMD

GO

/****** Object:  StoredProcedure [ONEDRIVE].[SPR_RefreshExcel]    Script Date: 11/01/2016 18:10:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- DROP PROCEDURE ONEDRIVE.SPR_RefreshExcel
CREATE PROCEDURE [ONEDRIVE].[SPR_RefreshExcel] @DiretorioArquivos_IN_OUT VARCHAR(255)
AS
SET NOCOUNT ON

DECLARE @CMD VARCHAR(8000)

SET @CMD = 'M:\Projetos\Onedrive_PowerShell_Scripts\PSTools\psexec \\ts7 -u vagastec\sqldesenv -p H6ggtr%%$lk65 "C:\OneDrive_TMP\Excel_Refresh_App.exe" ' 
			+ @DiretorioArquivos_IN_OUT + ' -NoExit -accepteula' 

PRINT @CMD
EXEC MASTER.DBO.XP_CMDSHELL @CMD
GO

/****** Object:  StoredProcedure [ONEDRIVE].[SPR_Upload_Arquivo_OneDrive]    Script Date: 11/01/2016 18:10:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [ONEDRIVE].[SPR_Upload_Arquivo_OneDrive] 
@PathOneDrive VARCHAR(100),
@PathOUT VARCHAR(100) = 'M:\Projetos\Onedrive_PowerShell_Scripts\OUT'
AS

-- Tabela LOG
CREATE TABLE #RESULT (ID_RESULT SMALLINT IDENTITY PRIMARY KEY, OUTPUT VARCHAR(MAX))

DECLARE @Id_OnedriveFile SMALLINT, @Path VARCHAR(255),@Nome_Arquivo VARCHAR(255),@CMD VARCHAR(8000),@Access_Token VARCHAR(8000) = '',@ID_ARQUIVO SMALLINT

-- Pegar último token de acesso (válido por 1 hora)
SELECT TOP 1 @Access_Token = Access_Token FROM ONEDRIVE.Onedrive_Token ORDER BY Data_Solicitacao DESC

-- DROP TABLE #ARQUIVOS 
CREATE TABLE #ARQUIVOS (ID_ARQUIVO SMALLINT IDENTITY , NOME_ARQUIVO VARCHAR(255))

SET @CMD = 'DIR ' + @PathOUT + '\*.xlsx /B' 

INSERT INTO #ARQUIVOS 
EXEC master.DBO.XP_CMDSHELL @CMD

DELETE FROM #ARQUIVOS WHERE NOME_ARQUIVO IS NULL

SELECT TOP 1 @ID_ARQUIVO = ID_ARQUIVO,@NOME_ARQUIVO = NOME_ARQUIVO FROM #ARQUIVOS ORDER BY 1 

-- LOOP PARA UPLOAD DE CADA UM DOS ARQUIVOS
WHILE @@ROWCOUNT > 0
BEGIN
	
	SET @CMD = 'powershell.exe -version 3.0 M:\Projetos\Onedrive_PowerShell_Scripts\OneDrive_Upload_File.ps1 -access_token "' + @Access_Token + '"' +
			' -pathOUT \"' + @PathOUT + '\' + @NOME_ARQUIVO +  '\" -nome_arquivo \"' + @NOME_ARQUIVO + '\" -pathOneDrive \"' + @PathOneDrive + '\"'

	
	-- Upload the file
	INSERT INTO #RESULT
	EXEC MASTER.DBO.XP_CMDSHELL @CMD

	PRINT @CMD
	SELECT * FROM #RESULT

	TRUNCATE TABLE #RESULT

	SELECT TOP 1 @ID_ARQUIVO = ID_ARQUIVO,@NOME_ARQUIVO = NOME_ARQUIVO 
	FROM #ARQUIVOS 
	WHERE ID_ARQUIVO > @ID_ARQUIVO
	ORDER BY 1 


END	


GO

