USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_CARGA_FORMACOES_ACADEMICAS' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_CARGA_FORMACOES_ACADEMICAS
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_CARGA_FORMACOES_ACADEMICAS 
@DT_ATUALIZACAO_INICIO SMALLDATETIME ,
@DT_ATUALIZACAO_FIM SMALLDATETIME = NULL,
@PROC_AUTOMATICO BIT = 1 -- INDICA SE O PROCESSO ESTÁ SENDO REALIZADO VIA JOB DE CARGA AUTOMAT. OU MANUALMENTE 
						  -- CASO SEJA MANUAL IRÁ CARREGAR A TMP DE CANDIDATOS

AS
SET NOCOUNT ON

IF @DT_ATUALIZACAO_INICIO IS NULL
SET @DT_ATUALIZACAO_INICIO = '19010101'

-- SSIS passa neste formato quando NULO
IF @DT_ATUALIZACAO_FIM < '19010101' 
SET @DT_ATUALIZACAO_FIM = '20700101'

TRUNCATE TABLE VAGAS_DW.TMP_FORMACOES_ACADEMICAS

-- CASO SEJA O PROCESSO AUTOMATICO
IF @PROC_AUTOMATICO = 1
BEGIN
	INSERT INTO VAGAS_DW.TMP_FORMACOES_ACADEMICAS
	SELECT CANDIDATO_ID,NIVEL_ID,CURSO,INSTITUICAO,CONCLUIDA,DATA_DE_CONCLUSAO,GRADUACAO_ID,POS_GRADUACAO_ID,PAIS_ID,
			UF_ID,DURACAO_DE_CURSO_ID,STATUS,ANO_DE_CONCLUSAO, COALESCE(B.Descr_cursoGrad, D.Descr_cursoPGrad) AS CLASSIFICACAO_CURSO
	FROM [vagas-data].dbo.formacoes_academicas A
		LEFT JOIN [hrh-data].dbo.Cad_cursos_graduacao as b on a.graduacao_id = b.Cod_cursoGrad
		LEFT JOIN [hrh-data].dbo.Cad_cursos_posGraduacao  as d on a.pos_graduacao_id = d.Cod_cursoPGrad
	WHERE EXISTS ( SELECT * FROM VAGAS_DW.TMP_CANDIDATOS
						WHERE COD_CAND = A.CANDIDATO_ID ) -- Processo deverá ser executado após a carga de candidatos
	
	
END
ELSE
BEGIN
	INSERT INTO VAGAS_DW.TMP_FORMACOES_ACADEMICAS
	SELECT CANDIDATO_ID,NIVEL_ID,CURSO,INSTITUICAO,CONCLUIDA,DATA_DE_CONCLUSAO,GRADUACAO_ID,POS_GRADUACAO_ID,PAIS_ID,
			UF_ID,DURACAO_DE_CURSO_ID,STATUS,ANO_DE_CONCLUSAO, COALESCE(C.Descr_cursoGrad, E.Descr_cursoPGrad) AS CLASSIFICACAO_CURSO
	FROM [vagas-data].dbo.formacoes_academicas A
		INNER JOIN [hrh-data].dbo.[Candidatos] B ON B.Cod_Cand = A.CANDIDATO_ID
		LEFT JOIN [hrh-data].dbo.Cad_cursos_graduacao as c on a.graduacao_id = c.Cod_cursoGrad
		LEFT JOIN [hrh-data].dbo.Cad_cursos_posGraduacao  as e on a.pos_graduacao_id = e.Cod_cursoPGrad
	WHERE B.EstadoReg_cand = 1
		AND ISNULL(B.Ficticio_cand, 0) = 0 
		AND B.UltDtAtual_cand >= @DT_ATUALIZACAO_INICIO AND B.UltDtAtual_cand < @DT_ATUALIZACAO_FIM 
		AND B.Cod_cand = ( SELECT MAX(Cod_cand) 
						FROM [hrh-data].DBO.candidatos
						WHERE CPF_cand = B.CPF_cand ) -- MAIOR CÓDIGO CANDIDATO	

END
	  
	  
	  
	  
	 
  