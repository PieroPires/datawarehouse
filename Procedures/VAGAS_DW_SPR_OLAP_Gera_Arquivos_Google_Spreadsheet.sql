USE VAGAS_DW
GO

-- EXEC VAGAS_DW.SPR_OLAP_Gera_Arquivos_Google_Spreadsheet 'https://docs.google.com/spreadsheets/d/1xxkkjon746BRH8Fk0zmQMzzoJQIkz8arE8leuvFx3QM/edit#gid=782526919','Detalhe_Tarefas'
-- EXEC VAGAS_DW.SPR_OLAP_Gera_Arquivos_Google_Spreadsheet 'https://docs.google.com/spreadsheets/d/1Y67J7F0o6mh474U1Un6wRwzWrvuNgk2rdU5M8IPXRoM/edit#gid=0','Pagina1'
IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Gera_Arquivos_Google_Spreadsheet' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Gera_Arquivos_Google_Spreadsheet
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 11/05/2016
-- Description: Procedure para geração dos arquivos .csv disponíveis no Google Drive
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Gera_Arquivos_Google_Spreadsheet 
@URL VARCHAR(200),
@ABA VARCHAR(100), -- SEM ACENTUAÇÃO
@PATH_OUT VARCHAR(50) = 'M:\\TMP\\'

AS
SET NOCOUNT ON

DECLARE @CMD VARCHAR(8000)

-- CHAMADA DO SCRIPT PYTHON QUE BUSCA OS ARQUIVOS DO GOOGLE SPREADSHEET E GERA EM FORMATO .CSV
SET @CMD = 'C:\Python27\python.exe M:\Projetos\Scripts_Python\LerPlanilhaGoogleDrive.py ' + 
			@URL + ' ' + @ABA + ' ' + @PATH_OUT

PRINT @CMD
EXEC MASTER.DBO.XP_CMDSHELL @CMD