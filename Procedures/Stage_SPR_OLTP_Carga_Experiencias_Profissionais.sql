USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_CARGA_EXPERIENCIAS_PROFISSIONAIS' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_CARGA_EXPERIENCIAS_PROFISSIONAIS
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_CARGA_EXPERIENCIAS_PROFISSIONAIS 
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

TRUNCATE TABLE VAGAS_DW.TMP_EXPERIENCIAS_PROFISSIONAIS
TRUNCATE TABLE VAGAS_DW.VAGAS_DW.TMP_EXPERIENCIAS_PROFISSIONAIS

-- CASO SEJA O PROCESSO AUTOMATICO
IF @PROC_AUTOMATICO = 1
BEGIN
	INSERT INTO VAGAS_DW.VAGAS_DW.TMP_EXPERIENCIAS_PROFISSIONAIS
	SELECT   A.CodCand_exp AS CANDIDATO_ID,
			 CONVERT(VARCHAR(120),A.Empresa_exp) AS EMPRESA,
			 CONVERT(VARCHAR(120),A.UltCargo_exp) AS ULTIMO_CARGO,
			 A.Inic_exp AS INICIO_EXPERIENCIA,
			 A.Fim_exp AS FIM_EXPERIENCIA,
			 A.CodSegmento_exp AS SEGMENTO_ID,
			 CONVERT(VARCHAR(100),B.Descr_Segmento) AS SEGMENTO,
			 A.Periodo_exp AS PERIODO,
			 A.Estimado_exp AS ESTIMADO,
			 A.CodPorte_exp AS PORTE_EMPRESA_ID,
			 CONVERT(VARCHAR(100),C.Descr_Porte) AS PORTE,
			 CONVERT(VARCHAR(8000),A.Descr_exp) AS DESCRICAO_EXPERIENCIA,
			 CONVERT(VARCHAR(120),A.NacionalidadeEmp_exp) AS NACIONALIDADE,
			 A.TipoEmp_exp AS TIPO_EMPRESA,
			 UltCargoNormalizado_exp
	  FROM [hrh-data].dbo.[Cand-Experiencia] A
	  LEFT OUTER JOIN [hrh-data].dbo.Cad_segmentos B ON B.Cod_Segmento = A.CodSegmento_exp
	  LEFT OUTER JOIN [hrh-data].dbo.Cad_portes C ON C.Cod_Porte = A.CodPorte_exp
	  WHERE EXISTS ( SELECT * FROM VAGAS_DW.TMP_CANDIDATOS
					 WHERE COD_CAND = A.CodCand_exp ) -- Processo deverá ser executado após a carga de candidatos

END
ELSE
BEGIN
	INSERT INTO VAGAS_DW.VAGAS_DW.TMP_EXPERIENCIAS_PROFISSIONAIS
	SELECT   A.CodCand_exp AS CANDIDATO_ID,
			 CONVERT(VARCHAR(120),A.Empresa_exp) AS EMPRESA,
			 CONVERT(VARCHAR(120),A.UltCargo_exp) AS ULTIMO_CARGO,
			 A.Inic_exp AS INICIO_EXPERIENCIA,
			 A.Fim_exp AS FIM_EXPERIENCIA,
			 A.CodSegmento_exp AS SEGMENTO_ID,
			 CONVERT(VARCHAR(100),B.Descr_Segmento) AS SEGMENTO,
			 A.Periodo_exp AS PERIODO,
			 A.Estimado_exp AS ESTIMADO,
			 A.CodPorte_exp AS PORTE_EMPRESA_ID,
			 CONVERT(VARCHAR(100),C.Descr_Porte) AS PORTE,
			 CONVERT(VARCHAR(8000),A.Descr_exp) AS DESCRICAO_EXPERIENCIA,
			 CONVERT(VARCHAR(120),A.NacionalidadeEmp_exp) AS NACIONALIDADE,
			 A.TipoEmp_exp AS TIPO_EMPRESA,
			 UltCargoNormalizado_exp
	  FROM [hrh-data].dbo.[Cand-Experiencia] A
	  LEFT OUTER JOIN [hrh-data].dbo.Cad_segmentos B ON B.Cod_Segmento = A.CodSegmento_exp
	  LEFT OUTER JOIN [hrh-data].dbo.Cad_portes C ON C.Cod_Porte = A.CodPorte_exp
	  INNER JOIN [hrh-data].dbo.[Candidatos] D ON D.Cod_Cand = A.CodCand_exp
	  WHERE D.EstadoReg_cand = 1
		AND ISNULL(D.Ficticio_cand, 0) = 0 
		--AND D.UltDtAtual_cand >= @DT_ATUALIZACAO_INICIO AND D.UltDtAtual_cand < @DT_ATUALIZACAO_FIM 
		--AND D.Cod_cand = ( SELECT MAX(Cod_cand) 
		--					FROM [hrh-data].DBO.candidatos
		--					WHERE CPF_cand = D.CPF_cand ) -- MAIOR CÓDIGO CANDIDATO

END
	  
	  
	  
	  
	 
  