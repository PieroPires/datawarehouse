-- select * from vagas_dw.TMP_VAGAS
-- EXEC VAGAS_DW.SPR_OLTP_Carga_Agenda_Participantes '19010101'
USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Agenda_Participantes' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Agenda_Participantes
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 09/08/2016
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Agenda_Participantes 

@ID_AGENDA VARCHAR(50),
@NOME_PARTICIPANTE VARCHAR(250),
@EMAIL VARCHAR(150),
@RESPOSTA VARCHAR(100),
@FLAG_RECURSO BIT

AS
SET NOCOUNT ON

-- Limpar dados existentes dos participantes da agenda
DELETE FROM VAGAS_DW.TMP_AGENDA_PARTICIPANTES WHERE ID_AGENDA = @ID_AGENDA AND EMAIL = @EMAIL
	
INSERT INTO VAGAS_DW.TMP_AGENDA_PARTICIPANTES (NOME_PARTICIPANTE,EMAIL,RESPOSTA,FLAG_RECURSO,ID_AGENDA)  
VALUES (@NOME_PARTICIPANTE,@EMAIL,@RESPOSTA ,@FLAG_RECURSO,@ID_AGENDA)


