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
	[Ficticio_cand] [bit] NOT NULL,[CPF_Cand] [nvarchar](11) NULL,LIBERACAO_CV_NOVO TINYINT ) 

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
		   liberacaocvnovo AS LIBERACAO_CV_NOVO
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
		   liberacaocvnovo AS LIBERACAO_CV_NOVO
	FROM [hrh-data].dbo.Candidatos A
	

END

DELETE FROM #TMP_CANDIDATOS WHERE ISNULL(Ficticio_cand, 0) <> 0

CREATE CLUSTERED INDEX IDX_COD_CAND ON #TMP_CANDIDATOS (COD_CAND)
CREATE TABLE #TMP_CANDIDATO_LOGIN (CodCand_logCand INT,Data_logCand DATETIME)

INSERT INTO #TMP_CANDIDATO_LOGIN 
SELECT CodCand_logCand,
	MAX(Data_logCand) AS Data_logCand
FROM [hrh-data].dbo.[Candidatos-Login] A
WHERE EXISTS ( SELECT 1 FROM #TMP_CANDIDATOS
				WHERE Cod_Cand = A.CodCand_logCand )
GROUP BY CodCand_logCand

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
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 18 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 22 THEN 'De 18 a 21 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 22 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 26 THEN 'De 22 a 25 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 26 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 30 THEN 'De 26 a 29 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 30 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 36 THEN 'De 30 a 35 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 36 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 40 THEN 'De 36 a 39 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 40 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 46 THEN 'De 40 a 45 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 46 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 53 THEN 'De 46 a 52 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 53 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 60 THEN 'De 53 a 59 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 60 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) < 66 THEN 'De 60 a 65 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 66 AND DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) <= 70 THEN 'De 66 a 70 anos'
			WHEN DATEDIFF(YEAR,A.DtNasc_cand,GETDATE()) >= 71 THEN 'Acima de 70 anos' 
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
	ISNULL(J.Data_LogCand,'19000101') AS DATA_ULT_LOGIN_SOURCE,
	CONVERT(SMALLDATETIME,CONVERT(VARCHAR,ISNULL(J.Data_LogCand,'19000101'),112)) AS DATA_ULT_LOGIN,
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
			  ELSE 'Não Completo [via BCE]' END
		ELSE CASE WHEN EstadoReg_cand = 1 THEN 'Do VAGAS - BCC' ELSE 'Não Completo [via BCC]' END
		     END AS ACESSO_RESTRITO,
	A.CodFormMax_cand, -- Campo será utilizado na carga do MAPA DE CARREIRAS
	A.DtUltSal_cand, -- Campo será utilizado na carga do MAPA DE CARREIRAS
	A.UltSal_cand,
	FezAcessoIrrestrito_cand,
	A.CPF_cand AS CPF,
	ISNULL(N.Nome_div,'VAGAS.com') AS Divisao_Origem,
	ISNULL(O.Ident_cli,'VAGAS.com') AS Cliente_Origem,
	M.Descr_fonteCandidatura AS Mecanismo_Origem,
	CONVERT(VARCHAR(100),I.Descr_setor) AS AREA_INTERESSE_1,
	CONVERT(VARCHAR(100),I2.Descr_setor) AS AREA_INTERESSE_2,
	CONVERT(VARCHAR(100),I3.Descr_setor) AS AREA_INTERESSE_3,
	CONVERT(VARCHAR(100),I4.Descr_setor) AS AREA_INTERESSE_4,
	CONVERT(VARCHAR(100),I5.Descr_setor) AS AREA_INTERESSE_5,
	M.Descr_fonteCandidatura AS FONTE_CADASTRO,
	A.LIBERACAO_CV_NOVO
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
			  ORDER BY AnoIni_ExpOcup DESC ) D
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
LEFT OUTER JOIN #TMP_CANDIDATO_LOGIN J ON J.CodCand_logCand = A.Cod_cand
OUTER APPLY ( SELECT TOP 1 * FROM [hrh-data].dbo.[Cand-NecEsp]
			  WHERE CodCand_necEsp = A.Cod_Cand ) L
LEFT OUTER JOIN [hrh-data].dbo.[Cand-Fonte] L1 ON L1.CodCand_fnt = A.Cod_Cand
LEFT OUTER JOIN [hrh-data].dbo.Cad_FonteCandidaturas M ON M.cod_fonteCandidatura = L1.Fonte_fnt
LEFT OUTER JOIN [hrh-data].dbo.Divisoes N ON N.Cod_Div = L1.TipoNav_fnt
LEFT OUTER JOIN [hrh-data].dbo.Clientes O ON O.Cod_Cli = N.CodCli_div
LEFT OUTER JOIN [hrh-data].dbo.Cad_formacaoMax P ON P.Cod_formMax = A.CodFormMax_cand