-- select * from vagas_dw.TMP_VAGAS
-- EXEC VAGAS_DW.SPR_OLTP_Carga_VAGAS '19010101'
USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_VAGAS' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_VAGAS
GO


-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_VAGAS 
@DT_CARGA_INICIO DATETIME ,
@DT_CARGA_FIM DATETIME = NULL

AS
SET NOCOUNT ON

IF @DT_CARGA_INICIO IS NULL
SET @DT_CARGA_INICIO = '19010101'

-- SSIS passa neste formato quando NULO
IF @DT_CARGA_FIM < '19010101' OR @DT_CARGA_FIM IS NULL
SET @DT_CARGA_FIM = CONVERT(SMALLDATETIME,CONVERT(VARCHAR,GETDATE(),112))

TRUNCATE TABLE VAGAS_DW.TMP_VAGAS 

	-- sp_who2 'active'
  SELECT CodVaga_czMonitVaga,
		 1.00 * SUM(CountOfCandCompativel_czMonitVaga) AS QtdAlertaDisparado,
		 MIN(PercRetorno_czMonitVaga) as PercRetorno,
		 COUNT( distinct CONVERT(date,DataIni_czMonit) ) as DiasAlertado
   INTO #TMP_ALERTAS
   FROM  [hrh-data].dbo.CruzamentoMonit with(nolock)
   INNER JOIN [hrh-data].dbo.cruzamentomonitxVaga with(nolock) ON Cod_CzMonit = CodCzMonit_czMonitVaga
   WHERE CountOfCand_czMonitVaga >= 0    
   GROUP BY CodVaga_czMonitVaga;

-- DROP TABLE Tempdb.dbo.TMP_VAGAS
WITH SETOR -- Para as VAGAS selecionadas, listar pela ordem de cria��o, os setores de cada uma
AS (    
   SELECT ROW_NUMBER() OVER (PARTITION BY CodVaga_vagSet ORDER BY Cod_vagSet) ORDEM_SETOR, 
		  CodVaga_vagSet, 
		  Descr_setor 
   FROM [hrh-data].dbo.[Vagas-Setores] with (nolock) 
   INNER JOIN [hrh-data].dbo.Cad_setores on CodSetor_vagSet = Cod_setor    
   ) 

INSERT INTO VAGAS_DW.TMP_VAGAS
SELECT A.Cod_Vaga VAGAS_Cod_Vaga,
	B.Cod_cli AS COD_CLI,
	B.Ident_cli AS CLIENTE,
	REPLACE(A.Cargo_vaga, ';', '') CARGO,
	ISNULL(C.Descr_formMax, 'INDIFERENTE') ESCOLARIDADE,  
	ISNULL(D.Descr_Hierarquia, '') NIVEL,
	ISNULL(E.Descr_cidadeMer, '') CIDADE,    
    ISNULL(F.Descr_estadoMer, '') UF,
	CASE WHEN A.Sexo_Vaga = 1 THEN 'MASCULINO'
		 WHEN A.Sexo_Vaga = 0 THEN 'FEMININO'
		 ELSE 'INDIFERENTE' END AS PREF_SEXO,
	CASE ISNULL(tipoprocesso_vaga, 0) WHEN 1 THEN '' ELSE ISNULL(G1.Descr_setor, '') END AREA_01,
	CASE ISNULL(tipoprocesso_vaga, 0) WHEN 1 THEN '' ELSE ISNULL(G2.Descr_setor, '') END AREA_02,
	CASE ISNULL(tipoprocesso_vaga, 0) WHEN 1 THEN '' ELSE ISNULL(G3.Descr_setor, '') END AREA_03,
	CASE WHEN ISNULL(DescrReg_vaga, '') IN ('', 'INDEFINIDO', 'BRASIL') THEN 'SIM' ELSE 'N�O' END AS ACEITA_CAND_OUTRA_REGIAO,    
    CASE WHEN Validada_vaga = 1 THEN 'SIM' ELSE 'N�O' END AS VAGA_VALIDADA,
	A.DTCRIACAO_VAGA AS DATA_CADASTRAMENTO_SOURCE,
	CONVERT(DATETIME,CONVERT(VARCHAR,A.DTCRIACAO_VAGA,112)) AS DATA_CADASTRAMENTO,
	H.DATA_VALIDACAO AS DATA_VALIDACAO_SOURCE,
	CONVERT(DATETIME,CONVERT(VARCHAR,H.DATA_VALIDACAO,112)) AS DATA_VALIDACAO,
	A.DTINICIOWEB_VAGA AS DATA_PUBLICACAO_SOURCE,
	CONVERT(DATETIME,CONVERT(VARCHAR,A.DTINICIOWEB_VAGA,112)) AS DATA_PUBLICACAO,
	CASE ISNULL(aceitaCandOutroCargo_Vaga, 0) WHEN 1 THEN 'SIM' ELSE 'N�O' END AS ACEITA_CAND_OUTRO_CARGO,
    CASE ISNULL(aceitaCandOutroNivel_Vaga, 0) WHEN 1 THEN 'SIM' ELSE 'N�O' END AS ACEITA_CAND_OUTRO_NIVEL,
    CASE ISNULL(aceitaCandOutraArea_Vaga, 0) WHEN 1 THEN 'SIM' ELSE 'N�O' END AS ACEITA_CAND_OUTRA_AREA,
	CASE ISNULL(DispViagens_Vaga, 0) WHEN 1 THEN 'SIM' ELSE 'N�O' END AS DISPONIB_VIAGEM,
	dtExpiracaoWeb_Vaga AS DATA_EXPIRACAO_SOURCE,
	CONVERT(DATETIME,CONVERT(VARCHAR,dtExpiracaoWeb_Vaga,112)) AS DATA_EXPIRACAO,
	DataUltimaTriagem_Vaga AS DATA_ULT_TRIAGEM_SOURCE,
	CONVERT(DATETIME,CONVERT(VARCHAR,DataUltimaTriagem_Vaga,112)) AS DATA_ULT_TRIAGEM,
	CASE WHEN (codFicha1_vaga IS NULL AND codFicha2_vaga IS NULL AND codFicha3_vaga IS NULL AND codFicha4_vaga IS NULL)  THEN 'N�O'     
         ELSE 'SIM' END AS SOLICITA_PREENCHIMENTO_FICHA,
	--CASE ISNULL(VagaComExt_vaga, 0) WHEN 1 THEN 'SIM' ELSE 'N�O' END AS VAGAS_COMUNIDADE_EXTERNA, -- Indica que � uma VAGA veiculada em COMUNIDADE EXTERNA    
	--CASE CodNavEx_div WHEN 300 THEN 'SIM' ELSE 'N�O' END AS VAGAS_RecrutamentoInterno, -- Indica que � uma divis�o RI  
    CASE ISNULL(Deficiente_vaga, 0) WHEN 1 THEN 'SIM' ELSE 'N�O' END AS PCD, 
    CASE ISNULL(mostraLinkEmpWeb_vaga, 0) WHEN 1 THEN 'SIM' ELSE 'N�O' END AS ANUNCIO_IDENTIFICADO, 
	ISNULL(J.Descr_segmento,'N�O CLASSIFICADO') AS SEGMENTO,
	ISNULL(Descr_segmentoGrp,'N�O CLASSIFICADO') AS GRUPO_SEGMENTO,
	A.QTDEPOSICOES_VAGA AS QTD_POSICOES,
	ISNULL(DiasAlertado,0) AS QTD_DIAS_ALERTADO,
    ISNULL(QtdAlertaDisparado, 0) AS QTD_ALERTA_DISPARADO,
	ISNULL(PercRetorno, 0) AS PERC_RETORNO,
	PageViews_vaga AS QTD_PageViews,
	M.Descr_pais AS PAIS,
	A.UltDtAtual_vaga AS DATA_ATUALIZACAO_SOURCE,
	CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.UltDtAtual_vaga,112)) AS DATA_ATUALIZACAO,

	CASE WHEN A.VeiculacaoSuspensa_vaga = 1 THEN 'SIM' ELSE 'N�O' END AS VEICULACAO_SUSPENSA,
	CASE WHEN B.Bloqueado_cli = 1 THEN 'SIM' ELSE 'N�O' END AS CLIENTE_BLOQUEADO,
	CASE WHEN A.QtdeRespCand_vaga < A.QtdeMaxResp_vaga THEN 'N�O' 
		 ELSE CASE WHEN A.Tipo_vaga = 2 THEN 'N�O' ELSE 'SIM' END 
		  END AS ATINGIU_LIMITE_CANDIDATURAS, -- CASO A VAGA TENHA ATINGIDO O LIMITE DE CANDIDATURAS
	CASE WHEN O.AcessoCand_navEx = 0 THEN 'SIM' ELSE 'N�O' END AS NAV_EXC,
	CASE WHEN A.ColetaCur_vaga = 0 THEN 'N�O' ELSE 'SIM' END AS CAPTACAO_CONTINUA,
	CASE WHEN A.DivulgacaoVAGAScombr_vaga = 1 THEN 'SIM' ELSE 'N�O' END AS EXIBE_VAGAS_COM,
	CASE WHEN A.InvisivelEmLista_vaga = 1 THEN 'SIM' ELSE 'N�O' END AS INVISIVEL,

	CASE WHEN N.CodNavEx_div = 300 THEN 'RI' -- RECRUTAMENTO INTERNO
		 WHEN ISNULL(A.QtdeRespCand_vaga, 0) = 0 AND ISNULL(A.tipoprocesso_vaga, 0) <> 4 THEN 'GEST�O' -- VAGAS DE GEST�O S�O AQUELAS ONDE N�O H� CANDIDATURAS (20161227 - N�O CONSIDERAR VAGAS REDES)
		 WHEN ISNULL(A.tipoprocesso_vaga, 0) = 0 THEN 'RE'
		 WHEN ISNULL(A.tipoprocesso_vaga, 0) = 1 THEN 'PET'
		 WHEN ISNULL(A.tipoprocesso_vaga, 0) = 2 THEN 'PRC'
		 WHEN ISNULL(A.tipoprocesso_vaga, 0) = 4 THEN 'REDES'
		 ELSE 'N�O CLASSIFICADO' END AS TIPO_PROCESSO,
	CASE WHEN Teste_vaga = 0 THEN 'N�O' ELSE 'SIM' END AS FLAG_VAGA_TESTE,
	ISNULL(P.regiao_estadoBR, '') AS REGIAO

FROM [hrh-data].dbo.VAGAS A
INNER JOIN [hrh-data].dbo.Clientes B ON B.Cod_cli = A.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.Cad_formacaoMax C ON C.Cod_formMax = A.codFormacaoMin_Vaga
LEFT OUTER JOIN [hrh-data].dbo.Cad_hierarquias D ON D.Cod_Hierarquia = A.codHierarquiaMin_Vaga
LEFT OUTER JOIN [hrh-data].dbo.Meridian_Cad_Cidades E ON E.Cod_cidadeMer = A.CodCidade_vaga 
LEFT OUTER JOIN [hrh-data].dbo.Meridian_Cad_Estados F ON F.Cod_estadoMer = A.CodUF_vaga 
LEFT OUTER JOIN SETOR G1 ON G1.CodVaga_vagSet = A.Cod_vaga AND G1.ORDEM_SETOR = 1
LEFT OUTER JOIN SETOR G2 ON G2.CodVaga_vagSet = A.Cod_vaga AND G2.ORDEM_SETOR = 2
LEFT OUTER JOIN SETOR G3 ON G3.CodVaga_vagSet = A.Cod_vaga AND G3.ORDEM_SETOR = 3
OUTER APPLY ( SELECT MIN(DataVAlidacao_vagaval) DATA_VALIDACAO
			  FROM [hrh-data].dbo.[vagas-validacao]
			 WHERE codVaga_vagaVal = A.cod_vaga ) H
LEFT OUTER JOIN #TMP_ALERTAS I ON I.CodVaga_czMonitVaga = A.Cod_Vaga
LEFT OUTER JOIN [hrh-data].dbo.cad_segmentos J ON J.cod_segmento = B.CodSegmento_cli
LEFT OUTER JOIN [hrh-data].dbo.Cad_segmentos_grupos L ON L.Cod_segmentoGrp = J.CodGrupo_Segmento
LEFT OUTER JOIN [hrh-data].dbo.Cad_Paises M ON M.Cod_pais = F.CodPais_estadoMer
LEFT JOIN [hrh-data].dbo.Divisoes N ON N.Cod_div = A.CodDivVeic_vaga 
LEFT JOIN [hrh-data].dbo.Cad_NavEx O ON O.Cod_navEx = N.CodNavEx_div
LEFT OUTER JOIN [hrh-data].[dbo].[Cad_estadosBR] AS P ON F.Cod_estadoMer = P.Cod_estadoBR

WHERE ColetaCur_vaga = 0 -- N�o contar vagas de CAPTA��O
-- 23/03/2016 (CONFORME SUGEST�O DA BETH PASSAREMOS A CONTABILIZAR VAGAS DE TESTE. CRIEI UMA SEGMENTA��O COM O CAMPO "FLAG_TESTE")
--AND Teste_vaga = 0 -- -- nao eh uma vaga de teste (N�o considerar no C�lculo)
--AND Validada_vaga = 1 -- Tem que ser Validada (n�o interessa se a vaga foi validada)
AND VagaModelo_vaga = 0 -- Vaga n�o � modelo            
AND LEFT(Cargo_vaga,5) not in ('demo ', 'demo-') -- a vaga nao foi criada durante uma demonstracao  
AND A.UltDtAtual_vaga  >= @DT_CARGA_INICIO AND A.UltDtAtual_vaga < @DT_CARGA_FIM 
AND ISNULL(VagaComExt_vaga, 0) = 0 -- FILTRAR VAGAS DE COMUNID. EXTERNA [SUGEST�O BETH]

