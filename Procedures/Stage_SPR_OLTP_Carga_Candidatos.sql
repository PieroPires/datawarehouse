-- select * from vagas_dw.TMP_CANDIDATOS
-- EXEC VAGAS_DW.SPR_OLTP_Carga_Candidatos -- CARGA FULL
USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Candidatos' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Candidatos
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Candidatos 
@DT_ATUALIZACAO_INICIO SMALLDATETIME = NULL,
@DT_ATUALIZACAO_FIM SMALLDATETIME = NULL

AS
SET NOCOUNT ON

--IF @DT_ATUALIZACAO_INICIO IS NULL
--SET @DT_ATUALIZACAO_INICIO = '19010101'

-- SSIS passa neste formato quando NULO
IF @DT_ATUALIZACAO_FIM < '19010101' 
SET @DT_ATUALIZACAO_FIM = '20700101'

--TRUNCATE TABLE VAGAS_DW.TMP_CANDIDATOS 
TRUNCATE TABLE VAGAS_DW.VAGAS_DW.TMP_CANDIDATOS 

CREATE TABLE #TMP_CANDIDATOS([Cod_Cand] [int] NOT NULL,[CodFormMax_cand] [smallint] NULL,
	[DtNasc_cand] [datetime] NULL,[Masc_cand] [bit] NOT NULL,[ValSalPret_Cand] [int] NULL,
	[NroFilhos_Cand] [smallint] NOT NULL,[DispViagens_Cand] [bit] NOT NULL,[DispMudEnd_Cand] [bit] NOT NULL,
	[dtcriacao_cand] [datetime] NULL,[UltDtAtual_cand] [datetime] NOT NULL,[Email_cand] [nvarchar](60) NULL,
	[FezAcessoIrrestrito_cand] [bit] NOT NULL,[DtUltSal_cand] [datetime] NULL,[UltSal_cand] [int] NULL,
	[CodCidade_cand] [int] NULL,[CodEstadoCivil_cand] [smallint] NULL,[EstadoReg_cand] [tinyint] NOT NULL,
	[Ficticio_cand] [bit] NOT NULL,[CPF_Cand] [nvarchar](11) NULL,LIBERACAO_CV_NOVO TINYINT,Email varchar(120), 
	[MalaDiretaSite_cand] [bit], [MalaDireta_cand] [bit]) 

IF @DT_ATUALIZACAO_INICIO IS NOT NULL -- TESTA SE É CARGA FULL
BEGIN 
	
	INSERT INTO #TMP_CANDIDATOS
	SELECT Cod_Cand,
		   CodFormMax_cand,
		   DtNasc_cand,
		   Masc_cand,
		   ValSalPret_Cand,
		   NroFilhos_Cand,
		   DispViagens_Cand,
		   DispMudEnd_Cand,
		   dtcriacao_cand,
		   UltDtAtual_cand,
		   Email_cand,
		   FezAcessoIrrestrito_cand,
		   DtUltSal_cand,
		   UltSal_cand,
		   CodCidade_cand,
		   CodEstadoCivil_cand,
		   EstadoReg_cand,
		   Ficticio_cand,
		   CPF_Cand,
		   liberacaocvnovo AS LIBERACAO_CV_NOVO,
		   Email_Cand,
		   MalaDiretaSite_cand,
		   MalaDireta_cand
	FROM [hrh-data].dbo.Candidatos A
	WHERE A.UltDtAtual_cand >= @DT_ATUALIZACAO_INICIO AND A.UltDtAtual_cand < @DT_ATUALIZACAO_FIM 
	--AND A.Cod_cand = ( SELECT MAX(Cod_cand) FROM [hrh-data]..candidatos
	--					WHERE CPF_cand = A.CPF_cand ) -- MAIOR CÓDIGO CANDIDATO
END
ELSE 
BEGIN
	
	-- CARGA FULL
	INSERT INTO #TMP_CANDIDATOS
	SELECT Cod_Cand,
		   CodFormMax_cand,
		   DtNasc_cand,
		   Masc_cand,
		   ValSalPret_Cand,
		   NroFilhos_Cand,
		   DispViagens_Cand,
		   DispMudEnd_Cand,
		   dtcriacao_cand,
		   UltDtAtual_cand,
		   Email_cand,
		   FezAcessoIrrestrito_cand,
		   DtUltSal_cand,
		   UltSal_cand,
		   CodCidade_cand,
		   CodEstadoCivil_cand,
		   EstadoReg_cand,
		   Ficticio_cand,
		   CPF_Cand,
		   liberacaocvnovo AS LIBERACAO_CV_NOVO,
		   Email_Cand,
		   MalaDiretaSite_cand,
		   MalaDireta_cand
	FROM [hrh-data].dbo.Candidatos A	

END

DELETE FROM #TMP_CANDIDATOS WHERE ISNULL(Ficticio_cand, 0) <> 0

CREATE CLUSTERED INDEX IDX_COD_CAND ON #TMP_CANDIDATOS (COD_CAND)
--CREATE TABLE #TMP_CANDIDATO_LOGIN (CodCand_logCand INT,Data_logCand DATETIME)

--INSERT INTO #TMP_CANDIDATO_LOGIN 
--SELECT CodCand_logCand,
--	MAX(Data_logCand) AS Data_logCand
--FROM [hrh-data].dbo.[Candidatos-Login] A
--WHERE EXISTS ( SELECT 1 FROM #TMP_CANDIDATOS
--				WHERE Cod_Cand = A.CodCand_logCand )
--GROUP BY CodCand_logCand

--INSERT INTO VAGAS_DW.TMP_CANDIDATOS 
INSERT INTO VAGAS_DW.VAGAS_DW.TMP_CANDIDATOS 
SELECT A.Cod_Cand, 
	  CONVERT(VARCHAR,ISNULL(ISNULL(ultCargoNormalizado_exp, UltCargo_exp),'Não Classificado'),100) AS ULTIMO_CARGO,
	P.Descr_formMax AS FORMACAO,
	CONVERT(VARCHAR(100),D.Descr_Hierarquia) AS NIVEL,
	CONVERT(VARCHAR(100),E.Descr_cidadeMER) AS CIDADE,
	CONVERT(VARCHAR(100),F.Descr_EstadoMER) AS UF,
	CONVERT(VARCHAR(100),G.Descr_Pais) AS PAIS,
	CASE WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) <= 0 OR DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) IS NULL THEN 'Não Classificado'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 1  AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 18 THEN 'Até 18 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 18 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 23 THEN 'De 18 a 22 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 23 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 28 THEN 'De 23 a 27 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 28 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 33 THEN 'De 28 a 32 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 33 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 38 THEN 'De 33 a 37 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 38 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 43 THEN 'De 38 a 42 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 43 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 48 THEN 'De 43 a 47 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 48 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 53 THEN 'De 48 a 52 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 53 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 58 THEN 'De 53 a 57 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 58 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 64 THEN 'De 58 a 63 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 64 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 70 THEN 'De 64 a 69 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 70 THEN '70 anos ou mais' 
			ELSE 'Não Classificado' END AS IDADE,
	CASE WHEN A.Masc_cand = 1 THEN 'MASCULINO' ELSE 'FEMININO' END AS SEXO,
	CONVERT(VARCHAR(100),H.Descr_Estado_Civil) AS ESTADO_CIVIL,
	CASE WHEN A.ValSalPret_Cand <= 0 OR A.ValSalPret_Cand IS NULL THEN 'Não Classificado'
			WHEN A.ValSalPret_Cand > 0 AND  A.ValSalPret_Cand <= 500 THEN 'Até R$ 500,00'
			WHEN A.ValSalPret_Cand > 500 AND  A.ValSalPret_Cand <= 800 THEN 'De R$ 501,00 à R$ 800,00'
			WHEN A.ValSalPret_Cand > 800 AND  A.ValSalPret_Cand <= 1000 THEN 'De R$ 801,00 à R$ 1.000,00'
			WHEN A.ValSalPret_Cand > 1000 AND  A.ValSalPret_Cand <= 1500 THEN 'De R$ 1001,00 à R$ 1.500,00'
			WHEN A.ValSalPret_Cand > 1500 AND  A.ValSalPret_Cand <= 2000 THEN 'De R$ 1501,00 à R$ 2.000,00'
			WHEN A.ValSalPret_Cand > 2000 AND  A.ValSalPret_Cand <= 3000 THEN 'De R$ 2001,00 à R$ 3.000,00'
			WHEN A.ValSalPret_Cand > 3000 AND  A.ValSalPret_Cand <= 4000 THEN 'De R$ 3001,00 à R$ 4.000,00'
			WHEN A.ValSalPret_Cand > 4000 AND  A.ValSalPret_Cand <= 5000 THEN 'De R$ 4001,00 à R$ 5.000,00'
			WHEN A.ValSalPret_Cand > 5000 AND  A.ValSalPret_Cand <= 8000 THEN 'De R$ 5001,00 à R$ 8.000,00'
			WHEN A.ValSalPret_Cand > 8000 AND  A.ValSalPret_Cand <= 10000 THEN 'De R$ 8001,00 à R$ 10.000,00'
			WHEN A.ValSalPret_Cand > 10000 AND  A.ValSalPret_Cand <= 12000 THEN 'De R$ 10001,00 à R$ 12.000,00'
			WHEN A.ValSalPret_Cand > 12000 AND  A.ValSalPret_Cand <= 16000 THEN 'De R$ 12001,00 à R$ 16.000,00'
			WHEN A.ValSalPret_Cand > 16000 AND  A.ValSalPret_Cand <= 20000 THEN 'De R$ 16001,00 à R$ 20.000,00'
			WHEN A.ValSalPret_Cand > 20000 AND  A.ValSalPret_Cand <= 25000 THEN 'De R$ 20001,00 à R$ 25.000,00'
			WHEN A.ValSalPret_Cand > 25000 AND  A.ValSalPret_Cand <= 30000 THEN 'De R$ 25001,00 à R$ 30.000,00'
			WHEN A.ValSalPret_Cand > 30000 THEN 'Acima de R$ 30.000,00'
			ELSE NULL END AS SALARIO_PRETENDIDO,
	CASE WHEN A.UltSal_cand <= 0 OR A.UltSal_cand IS NULL THEN 'Não Classificado'
			WHEN A.UltSal_cand > 0 AND  A.UltSal_cand <= 500 THEN 'Até R$ 500,00'
			WHEN A.UltSal_cand > 500 AND  A.UltSal_cand <= 800 THEN 'De R$ 501,00 à R$ 800,00'
			WHEN A.UltSal_cand > 800 AND  A.UltSal_cand <= 1000 THEN 'De R$ 801,00 à R$ 1.000,00'
			WHEN A.UltSal_cand > 1000 AND  A.UltSal_cand <= 1500 THEN 'De R$ 1001,00 à R$ 1.500,00'
			WHEN A.UltSal_cand > 1500 AND  A.UltSal_cand <= 2000 THEN 'De R$ 1501,00 à R$ 2.000,00'
			WHEN A.UltSal_cand > 2000 AND  A.UltSal_cand <= 3000 THEN 'De R$ 2001,00 à R$ 3.000,00'
			WHEN A.UltSal_cand > 3000 AND  A.UltSal_cand <= 4000 THEN 'De R$ 3001,00 à R$ 4.000,00'
			WHEN A.UltSal_cand > 4000 AND  A.UltSal_cand <= 5000 THEN 'De R$ 4001,00 à R$ 5.000,00'
			WHEN A.UltSal_cand > 5000 AND  A.UltSal_cand <= 8000 THEN 'De R$ 5001,00 à R$ 8.000,00'
			WHEN A.UltSal_cand > 8000 AND  A.UltSal_cand <= 10000 THEN 'De R$ 8001,00 à R$ 10.000,00'
			WHEN A.UltSal_cand > 10000 AND  A.UltSal_cand <= 12000 THEN 'De R$ 10001,00 à R$ 12.000,00'
			WHEN A.UltSal_cand > 12000 AND  A.UltSal_cand <= 16000 THEN 'De R$ 12001,00 à R$ 16.000,00'
			WHEN A.UltSal_cand > 16000 AND  A.UltSal_cand <= 20000 THEN 'De R$ 16001,00 à R$ 20.000,00'
			WHEN A.UltSal_cand > 20000 AND  A.UltSal_cand <= 25000 THEN 'De R$ 20001,00 à R$ 25.000,00'
			WHEN A.UltSal_cand > 25000 AND  A.UltSal_cand <= 30000 THEN 'De R$ 25001,00 à R$ 30.000,00'
			WHEN A.UltSal_cand > 30000 THEN 'Acima de R$ 30.000,00' 
			ELSE NULL END AS ULTIMO_SALARIO,
	CASE WHEN A.NroFilhos_Cand > 0 THEN 'SIM' ELSE 'NÃO' END AS POSSUI_FILHOS,
	CASE WHEN A.DispViagens_Cand > 0 THEN 'SIM' ELSE 'NÃO' END AS ACEITA_VIAJAR,
	CASE WHEN A.DispMudEnd_Cand > 0 THEN 'SIM' ELSE 'NÃO' END AS ACEITA_MUDAR_ENDERECO,
	--I.Descr_hierarquia AS NIVEL_1, 
	CONVERT(VARCHAR(100),D.Descr_setor) AS SEGMENTO_1, -- ALTERADO EM 15/04/2016 PARA QUE CONTEMPLE Á ULT. "OCUPAÇÃO" DA ÚLTIMA EXPERIÊNCIA
	--I2.Descr_hierarquia AS NIVEL_2, 
	'' AS SEGMENTO_2,
	CONVERT(VARCHAR(100),C.Instit_Form) AS ULTIMA_INSTITUICAO_ENSINO,
	dtcriacao_cand AS DATA_CADASTRO_SOURCE,
	CONVERT(SMALLDATETIME,CONVERT(VARCHAR,dtcriacao_cand,112)) AS DATA_CADASTRO,
	UltDtAtual_cand AS DATA_ULT_ATUALIZACAO_SOURCE,
	CONVERT(SMALLDATETIME,CONVERT(VARCHAR,UltDtAtual_cand,112)) AS DATA_ULT_ATUALIZACAO,
	NULL AS DATA_ULT_LOGIN_SOURCE,
	NULL AS DATA_ULT_LOGIN,
	CASE WHEN L.CodCand_necEsp IS NOT NULL THEN 'SIM' ELSE 'NÃO' END AS POSSUI_DEFIC,
	CASE WHEN A.Email_cand IS NULL OR A.Email_cand = '' OR CHARINDEX('@',A.Email_cand) = 0 THEN 'NÃO' ELSE 'SIM' END AS POSSUI_EMAIL,
	CASE WHEN FezAcessoIrrestrito_cand = 0 THEN
		 -- Existem casos em que o candidato não completa o CV via BCE (o campo FezAcessoIrrestrito_cand fica marcado como 0 porém ele não pertence à nenhum BCE)
		 CASE WHEN EXISTS ( SELECT 1 
							   FROM [hrh-data].dbo.[CandidatoxCliente]
							   WHERE CodCand_candcli = A.Cod_Cand )
			  THEN 'Exclusivo de Cliente - BCE'
			  WHEN EXISTS ( SELECT 1 
							FROM [hrh-data].dbo.EntradaHistorico
							WHERE CodCand_hist = A.Cod_Cand AND Tipo_Hist = 0 ) 
			  THEN 'Removido [BCE]'
			  ELSE 'Desistência via Navex' END
		ELSE CASE WHEN EstadoReg_cand = 1 THEN 'Curriculo - BCC' ELSE 'Cadastro - BCC ' END
		     END AS TIPO_CADASTRO,
	A.CodFormMax_cand, -- Campo será utilizado na carga do MAPA DE CARREIRAS
	A.DtUltSal_cand, -- Campo será utilizado na carga do MAPA DE CARREIRAS
	A.UltSal_cand,
	FezAcessoIrrestrito_cand,
	A.CPF_cand AS CPF,
	ISNULL(N.Nome_div,'VAGAS.com') AS Divisao_Origem,
	ISNULL(O.Ident_cli,'VAGAS.com') AS Cliente_Origem,
	M.Descr_fonteCandidatura AS Mecanismo_Origem,
	M.Descr_fonteCandidatura AS FONTE_CADASTRO,
	A.LIBERACAO_CV_NOVO,
	ISNULL(Q.regiao_estadoBR, '') AS REGIAO,
	CASE WHEN ISNULL(O.Ident_cli,'VAGAS.com') = 'VAGAS.com' THEN 0 ELSE 1 END AS ORIGEM_TRABALHE_CONOSCO ,
	CASE WHEN DATEDIFF(YEAR, A.DtNasc_Cand, CAST(GETDATE() AS DATE)) < 0 THEN NULL ELSE DATEDIFF(YEAR, A.DtNasc_Cand, CAST(GETDATE() AS DATE)) END AS IDADE_CAND ,
	NULL AS CAND_REMOVIDO,
	A.Email_Cand,
	CONVERT(VARCHAR(100),I.Descr_setor) AS AREA_INTERESSE_1, 
    CONVERT(VARCHAR(100),I2.Descr_setor) AS AREA_INTERESSE_2, 
    CONVERT(VARCHAR(100),I3.Descr_setor) AS AREA_INTERESSE_3, 
    CONVERT(VARCHAR(100),I4.Descr_setor) AS AREA_INTERESSE_4, 
    CONVERT(VARCHAR(100),I5.Descr_setor) AS AREA_INTERESSE_5,
	NULL AS HASH ,
	NULL AS GRUPO_ULTIMO_CARGO ,
	NULL AS MOTIVO_REMOCAO ,
	NULL AS DATA_REMOCAO ,
	NULL AS TEMPO_PERMANENCIA_ANOS ,
	NULL AS CV_REMOVIDO_RETORNOU ,
	NULL AS TEMPO_PERMANENCIA_MESES ,
	A.MalaDiretaSite_cand AS ACEITA_MAILING_VAGAS,
	A.MalaDireta_cand AS ACEITA_MAILING_PARCEIROS,
	S.MalaDireta_VeTPriv AS ACEITA_MAILING_ETALENT,
	T.AceitaSMS_smsCandDiv AS ACEITA_MAILING_SMS_VAGAS,
	E.Cod_CidadeMer AS COD_MUNICIPIO
FROM #TMP_CANDIDATOS A
OUTER APPLY ( SELECT TOP 1 * FROM [hrh-data].dbo.[Cand-Experiencia] 
			  WHERE CodCand_Exp = A.Cod_Cand 
			  ORDER BY Inic_Exp DESC ) B  
OUTER APPLY ( SELECT TOP 1 * FROM [hrh-data].dbo.[cand-formacao]
			  WHERE CodCand_Form = A.Cod_Cand
			  ORDER BY AnoConc_form DESC,cod_form DESC ) C
OUTER APPLY ( SELECT TOP 1 B1.*,C1.*
			  FROM [hrh-data].dbo.[Cand-ExpOcupacoes] A1 
			  INNER JOIN [hrh-data].dbo.Cad_hierarquias B1 ON B1.Cod_Hierarquia = A1.CodHierarquia_ExpOcup
			  INNER JOIN [hrh-data].dbo.Cad_setores C1 ON C1.Cod_setor = A1.CodSetor_ExpOcup
			  WHERE A1.CodCand_ExpOcup = A.Cod_Cand
			  ORDER BY AnoIni_ExpOcup DESC, ISNULL(AnoFim_ExpOcup,DATEPART(year,GETDATE())) DESC, Cod_hierarquia DESC ) D
LEFT OUTER JOIN [hrh-data].dbo.Meridian_Cad_cidades E ON E.Cod_CidadeMer = A.CodCidade_cand			  
LEFT OUTER JOIN [hrh-data].dbo.Meridian_Cad_estados F ON F.Cod_EstadoMer = E.CodUF_cidadeMer
LEFT OUTER JOIN [hrh-data].dbo.Cad_paises G ON G.Cod_pais = F.CodPais_estadoMer
LEFT OUTER JOIN [hrh-data].dbo.Cad_estado_civil H ON H.Cod_Estado_Civil = A.CodEstadoCivil_cand			 
OUTER APPLY ( SELECT TOP 1 * 
			  FROM  [hrh-data].dbo.CandidatoxCargos A1
			  INNER JOIN [hrh-data].dbo.Cad_setores B1 ON B1.Cod_setor = A1.CodSetor_cargo 
			  INNER JOIN [hrh-data].dbo.Cad_hierarquias C1 ON C1.Cod_hierarquia = A1.CodHierarquia_cargo 
			  WHERE A1.CodCand_Cargo = A.Cod_Cand 
			  ORDER BY Cod_cargo DESC) I
OUTER APPLY ( SELECT TOP 1 * 
			  FROM  [hrh-data].dbo.CandidatoxCargos A1
			  INNER JOIN [hrh-data].dbo.Cad_setores B1 ON B1.Cod_setor = A1.CodSetor_cargo 
			  INNER JOIN [hrh-data].dbo.Cad_hierarquias C1 ON C1.Cod_hierarquia = A1.CodHierarquia_cargo 
			  WHERE A1.CodCand_Cargo = A.Cod_Cand AND A1.Cod_Cargo <> I.Cod_Cargo
			  ORDER BY Cod_cargo ASC) I2
OUTER APPLY ( SELECT TOP 1 * 
			  FROM  [hrh-data].dbo.CandidatoxCargos A1
			  INNER JOIN [hrh-data].dbo.Cad_setores B1 ON B1.Cod_setor = A1.CodSetor_cargo 
			  INNER JOIN [hrh-data].dbo.Cad_hierarquias C1 ON C1.Cod_hierarquia = A1.CodHierarquia_cargo 
			  WHERE A1.CodCand_Cargo = A.Cod_Cand AND A1.Cod_Cargo <> I.Cod_Cargo AND A1.Cod_Cargo <> I2.Cod_Cargo
			  ORDER BY Cod_cargo ASC) I3
OUTER APPLY ( SELECT TOP 1 * 
			  FROM  [hrh-data].dbo.CandidatoxCargos A1
			  INNER JOIN [hrh-data].dbo.Cad_setores B1 ON B1.Cod_setor = A1.CodSetor_cargo 
			  INNER JOIN [hrh-data].dbo.Cad_hierarquias C1 ON C1.Cod_hierarquia = A1.CodHierarquia_cargo 
			  WHERE A1.CodCand_Cargo = A.Cod_Cand 
			  AND A1.Cod_Cargo <> I.Cod_Cargo AND A1.Cod_Cargo <> I2.Cod_Cargo AND A1.Cod_Cargo <> I3.Cod_Cargo
			  ORDER BY Cod_cargo ASC) I4
OUTER APPLY ( SELECT TOP 1 * 
			  FROM  [hrh-data].dbo.CandidatoxCargos A1
			  INNER JOIN [hrh-data].dbo.Cad_setores B1 ON B1.Cod_setor = A1.CodSetor_cargo 
			  INNER JOIN [hrh-data].dbo.Cad_hierarquias C1 ON C1.Cod_hierarquia = A1.CodHierarquia_cargo 
			  WHERE A1.CodCand_Cargo = A.Cod_Cand 
			  AND A1.Cod_Cargo <> I.Cod_Cargo AND A1.Cod_Cargo <> I2.Cod_Cargo 
			  AND A1.Cod_Cargo <> I3.Cod_Cargo AND A1.Cod_Cargo <> I4.Cod_Cargo
			  ORDER BY Cod_cargo ASC) I5
--OUTER APPLY ( SELECT TOP 1 * FROM [hrh-data].dbo.[Candidatos-Login]
--			  WHERE CodCand_LogCand = A.Cod_Cand
--			  ORDER BY Data_LogCand DESC ) J
--LEFT OUTER JOIN #TMP_CANDIDATO_LOGIN J ON J.CodCand_logCand = A.Cod_cand
OUTER APPLY ( SELECT TOP 1 * FROM [hrh-data].dbo.[Cand-NecEsp]
			  WHERE CodCand_necEsp = A.Cod_Cand ) L
LEFT OUTER JOIN [hrh-data].dbo.[Cand-Fonte] L1 ON L1.CodCand_fnt = A.Cod_Cand
LEFT OUTER JOIN [hrh-data].dbo.Cad_FonteCandidaturas M ON M.cod_fonteCandidatura = L1.Fonte_fnt
LEFT OUTER JOIN [hrh-data].dbo.Divisoes N ON N.Cod_Div = L1.TipoNav_fnt
LEFT OUTER JOIN [hrh-data].dbo.Clientes O ON O.Cod_Cli = N.CodCli_div
LEFT OUTER JOIN [hrh-data].dbo.Cad_formacaoMax P ON P.Cod_formMax = A.CodFormMax_cand
LEFT OUTER JOIN [hrh-data].[dbo].[Cad_estadosBR] AS Q ON F.Cod_EstadoMer = Q.Cod_estadoBR
--LEFT OUTER JOIN [hrh-data].[dbo].[Cand-REM] AS R ON A.Cod_Cand = R.CodCand_candREM
LEFT OUTER JOIN [hrh-data].[dbo].[VAGAS_eTalent_privacidade_cand] AS S ON S.CodCand_VeTPriv = A.COD_CAND
LEFT OUTER JOIN [hrh-data].[dbo].[SMS_CandidatoxDivisao] AS T ON T.CodCand_smsCandDiv = A.cod_cand and T.CodDiv_smsCandDiv = -1

-- LOG de Candidatos atualizados para avaliar a possibilidade de particionar o cubo
INSERT INTO VAGAS_DW.VAGAS_DW.LOG_ATUALIZACAO_CANDIDATOS
SELECT
	CAST(A.DATA_ULT_ATUALIZACAO_SOURCE AS DATE) AS DATA_ATUALIZACAO
	,DATEPART(YEAR, B.DATA_ULT_ATUALIZACAO_SOURCE) AS ANO_ATUALIZACAO_PREVIA
	,COUNT(1) AS QTDE
FROM VAGAS_DW.VAGAS_DW.TMP_CANDIDATOS  AS A
	LEFT JOIN VAGAS_DW.VAGAS_DW.CANDIDATOS AS B ON A.COD_CAND = B.COD_CAND
where B.DATA_ULT_ATUALIZACAO_SOURCE IS NOT NULL
GROUP BY
	CAST(A.DATA_ULT_ATUALIZACAO_SOURCE AS DATE)
	,DATEPART(YEAR, B.DATA_ULT_ATUALIZACAO_SOURCE)
GO