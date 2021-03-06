USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Agenda_Google_Calendar' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Agenda_Google_Calendar
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 05/08/2016
-- Description: Procedure para carga das tabelas tempor?rias (BD Stage) para alimenta??o do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Agenda_Google_Calendar 
@ID_AGENDA VARCHAR(300), -- IDENTIFICA??O ?NICA DA AGENDA (VER NAS CONFIGURA??ES DA AGENDA)
@QUANTIDADE_REGISTROS INT = 300, -- QUANTIDADE M?XIMA DE REGISTROS QUE SER?O EXIBIDOS A PARTIR DA DATA CONSIDERADA
@DIAS SMALLINT = 0 -- DIAS (PRA CIMA OU PRA BAIXO) A SEREM CONSIDERADOS COMO IN?CIO 
-- (EX: CASO QUEIRA CARREGAR OS 50 PR?XIMOS EVENTOS A PARTIR DA DATA ATUAL BASTA PASSAR O @QUANTIDADE_REGISTROS = 50 E O @DIAS = 0.
--		CASO QUEIRA CARREGAR OS 50 PR?XIMOS A PARTIR DE 30 DIAS ATR?S BASTA PASSAR @DIAS = -30 )

AS
SET NOCOUNT ON

DECLARE @CMD VARCHAR(8000),
	    @MSG VARCHAR(1000)

CREATE TABLE #TMP_LOG_ERRO (ID_LOG_ERRO SMALLINT IDENTITY PRIMARY KEY,
							ERRO VARCHAR(8000) )	

-- Importar dados do Google Calendar diretamente para o BD 
SET @CMD = 'Z:\Scripts\Python3\python Z:\Scripts\Scripts_Python\Google_Calendar\Importacao_Google_Calendar.py ' + 
			' "' + @ID_AGENDA + '" "' + CONVERT(VARCHAR,@QUANTIDADE_REGISTROS) + '" "' + CONVERT(VARCHAR,@DIAS ) + '"'
	
INSERT INTO #TMP_LOG_ERRO (ERRO)
EXEC MASTER.DBO.XP_CMDSHELL @CMD
PRINT @CMD
		
-- Tratar erros ocorridos na rotina do Python	
IF EXISTS ( SELECT * FROM #TMP_LOG_ERRO WHERE CHARINDEX('ERROR_MESSAGE',ERRO) > 0 ) 
BEGIN 
	SET @MSG = 'ERRO ocorrido na importa??o dos dados da Agenda ID :' + @ID_AGENDA
	SELECT * FROM #TMP_LOG_ERRO 
	RAISERROR(@MSG , 16, 1) 
END

DROP TABLE #TMP_LOG_ERRO
