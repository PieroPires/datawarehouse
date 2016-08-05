-- select * from vagas_dw.TMP_VAGAS
-- EXEC VAGAS_DW.SPR_OLTP_Carga_Agenda '19010101'
USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Agenda' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Agenda
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 09/08/2016
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Agenda 

@ID_AGENDA VARCHAR(50),
@RESUMO VARCHAR(250),
@DATA_INICIO VARCHAR(12),
@DATA_FIM VARCHAR(12),
@NOME_AGENDA VARCHAR(150)

AS
SET NOCOUNT ON

DECLARE @DATA_INICIO_CONVERTIDA SMALLDATETIME,
		@DATA_FIM_CONVERTIDA SMALLDATETIME

SELECT @DATA_INICIO_CONVERTIDA = CONVERT(SMALLDATETIME,LEFT(@DATA_INICIO,8) + ' ' + SUBSTRING(@DATA_INICIO,9,2) + ':' + RIGHT(@DATA_INICIO,2) + ':00'),
	   @DATA_FIM_CONVERTIDA = CONVERT(SMALLDATETIME,LEFT(@DATA_FIM,8) + ' ' + SUBSTRING(@DATA_FIM,9,2) + ':' + RIGHT(@DATA_FIM,2) + ':00')

-- Limpar dados existentes da Agenda 
DELETE FROM VAGAS_DW.TMP_AGENDA WHERE ID_AGENDA = @ID_AGENDA
DELETE FROM VAGAS_DW.TMP_AGENDA_PARTICIPANTES WHERE ID_AGENDA = @ID_AGENDA 
	
INSERT INTO VAGAS_DW.TMP_AGENDA (ID_AGENDA,RESUMO,DATA_INICIO,DATA_FIM,NOME_AGENDA)  
VALUES (@ID_AGENDA,@RESUMO,@DATA_INICIO_CONVERTIDA ,@DATA_FIM_CONVERTIDA ,@NOME_AGENDA)
