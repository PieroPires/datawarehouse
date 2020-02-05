USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Candidatos_Setores' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Candidatos_Setores
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

-- =============================================
-- Alterações
-- 05/02/2020 - Diego Gatto - Ajustado para utilizar as tabelas TMP na base de dados stage e não vagas_dw
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Candidatos_Setores 
@DT_ATUALIZACAO_INICIO SMALLDATETIME ,
@DT_ATUALIZACAO_FIM SMALLDATETIME = NULL,
@PROC_AUTOMATICO BIT = 1 -- INDICA SE O PROCESSO ESTÁ SENDO REALIZADO VIA JOB DE CARGA AUTOMAT. OU MANUALMENTE 
						  -- CASO SEJA MANUAL IRÁ CARREGAR A TMP DE CANDIDATOS

AS
SET NOCOUNT ON

IF @DT_ATUALIZACAO_INICIO IS NULL
SET @DT_ATUALIZACAO_INICIO = '19010101'

-- SSIS passa neste formato quando NULO
IF @DT_ATUALIZACAO_FIM < '19010101' OR @DT_ATUALIZACAO_FIM IS NULL
SET @DT_ATUALIZACAO_FIM = '20700101'

TRUNCATE TABLE VAGAS_DW.TMP_CANDIDATOS_SETORES 

-- CASO SEJA O PROCESSO AUTOMATICO
IF @PROC_AUTOMATICO = 1
BEGIN
	INSERT INTO VAGAS_DW.TMP_CANDIDATOS_SETORES 
	SELECT A.CODCAND_CARGO AS COD_CAND, 
   		   B.DESCR_SETOR AS SETOR, 
		   C.DESCR_HIERARQUIA AS HIERARQUIA 
	 FROM [HRH-DATA].DBO.[CandidatoxCargos] A
	 INNER JOIN [HRH-DATA].DBO.[Cad_setores] B ON B.COD_SETOR = A.CODSETOR_CARGO
	 INNER JOIN [HRH-DATA].DBO.Cad_hierarquias C ON C.COD_HIERARQUIA = A.CODHIERARQUIA_CARGO
	 WHERE EXISTS ( SELECT * FROM VAGAS_DW.TMP_CANDIDATOS
					 WHERE COD_CAND = A.CODCAND_CARGO ) -- Processo deverá ser executado após a carga de candidatos
END
ELSE
BEGIN
	INSERT INTO VAGAS_DW.TMP_CANDIDATOS_SETORES 
	SELECT A.CODCAND_CARGO AS COD_CAND, 
   		   B.DESCR_SETOR AS SETOR, 
		   C.DESCR_HIERARQUIA AS HIERARQUIA 
	  FROM [HRH-DATA].DBO.[CandidatoxCargos] A
	 INNER JOIN [HRH-DATA].DBO.[Cad_setores] B ON B.COD_SETOR = A.CODSETOR_CARGO
	 INNER JOIN [HRH-DATA].DBO.Cad_hierarquias C ON C.COD_HIERARQUIA = A.CODHIERARQUIA_CARGO
	 INNER JOIN [HRH-DATA].DBO.Candidatos D ON D.Cod_Cand = A.CODCAND_CARGO
	 WHERE D.EstadoReg_cand = 1
	   AND ISNULL(D.Ficticio_cand, 0) = 0 
	   AND D.UltDtAtual_cand >= @DT_ATUALIZACAO_INICIO AND D.UltDtAtual_cand < @DT_ATUALIZACAO_FIM 
	   AND D.Cod_cand = ( SELECT MAX(Cod_cand) 
							FROM [hrh-data].DBO.candidatos
							WHERE CPF_cand = D.CPF_cand ) -- MAIOR CÓDIGO CANDIDATO
END 

