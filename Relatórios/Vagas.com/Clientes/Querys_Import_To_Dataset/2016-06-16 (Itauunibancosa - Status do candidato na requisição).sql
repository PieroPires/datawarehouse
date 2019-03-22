-- =============================================
-- Author:      FIAMA
-- Create date: 2016-06-15
-- Description: 
-- =============================================

---------------------------------------------------------------------
-- 2.  Itauunibancosa Status do candidato na requisição - PeopleSoft:
---------------------------------------------------------------------

DECLARE	  @Cod_cand			INT			--= 2379721			-- (26 row(s) affected) 00:00:02
		, @CPF_cand			VARCHAR(11) --= '09561354713'	-- (2 row(s) affected) 00:00:02
		, @Cod_ItauReq		VARCHAR(15) --= 521271			-- (11705 row(s) affected) 00:00:35
		, @CodReq_vagas		INT			--= 238218			-- (11705 row(s) affected) 00:00:34	
		, @Cod_vaga			INT			--= 1290035			-- (11705 row(s) affected) 00:00:36




/* INÍCIO VARIÁVEL @Cod_cand */
IF	@Cod_cand IS NOT NULL
BEGIN



	-- Query:
	SELECT	  A.Cod_ItauReq					AS [Requisição Itaú]
			, A2.Cod_rvw					AS [Requisição VAGAS]
			, C.CodVaga_candVaga			AS [Código da vaga]
			, A.Requisitante_Nome_ItauReq	AS [Nome do Requisitante]
			, D.Nome_func					AS [Nicho]
			, E.[Status_Vaga]				AS [Status da Vaga]
			, parc01.Nome_ItauParc			AS [1ªParceira]
			, parc02.Nome_ItauParc			AS [2ªParceira]
			, parc03.Nome_ItauParc			AS [3ªParceira]
			, parc04.Nome_ItauParc			AS [4ªParceira]
			, parc05.Nome_ItauParc			AS [5ªParceira]
			, parc06.Nome_ItauParc			AS [6ªParceira]
			, C.Cod_cand					AS [Código do candidato]
			, C.Nome_cand					AS [Nome]
			, C.CPF_cand					AS [CPF]
			, C.CEP_cand					AS [CEP]
			, G.[Status_Global_Candidato]	AS [Status Global Candidato]
			, G.[Cliente_Status_Global]		AS [Comentário Status Global]
			, H.Nome_fase					AS [Fase]
			, ISNULL( FORMAT(CONVERT(DATETIME, A.CtrlDt_ItauReq), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')		AS [Data Importação Requisição]
			, CASE WHEN A.CtrlDt_ItauReq IS NULL THEN 0 ELSE 1 END AS [Val_DataImportReq]
			, ISNULL( FORMAT(CONVERT(DATETIME, A2.Data_rvw), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')			AS [Data Abertura Requisição (VAGAS)]
			, CASE WHEN A2.Data_rvw IS NULL THEN 0 ELSE 1 END AS [Val_AbertReqVAGAS]
			, ISNULL( FORMAT(CONVERT(DATETIME, F.DtCriacao_vaga), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')		AS [Data criação Vaga]
			, CASE WHEN F.dtCriacao_vaga IS NULL THEN 0 ELSE 1 END AS [Val_DataCriacaoVaga]
			, ISNULL( FORMAT(CONVERT(DATETIME, E.[Data_Status_Vaga]),'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO') AS [Data Status Vaga]
			, CASE WHEN E.[Data_Status_Vaga] IS NULL THEN 0 ELSE 1 END AS [Val_DataStatusVaga]
			, ISNULL( FORMAT(CONVERT(DATETIME, C.[FonteData_candVaga]), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')	AS [Data Candidatura]
			, CASE WHEN C.FonteData_candVaga IS NULL THEN 0 ELSE 1 END AS [Val_FonteData]
			, ISNULL( FORMAT(CONVERT(DATETIME, L.Data_respCab), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')			AS [Data resposta ficha complementar]
			, CASE WHEN L.Data_respCab IS NULL THEN 0 ELSE 1 END AS [Val_DatarespCab]
			, ISNULL( FORMAT(CONVERT(DATETIME, I.DtEntrada_faseCand), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')		AS [Data Movimentação Fase]
			, CASE WHEN I.DtEntrada_faseCand IS NULL THEN 0 ELSE 1 END AS [Val_DataMovimentFase]
			, ISNULL( FORMAT(CONVERT(DATETIME, J.CtrlIntDt_ItauPret), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')	AS [Data Exportação Pretendente]
			, CASE WHEN J.CtrlIntDt_ItauPret IS NULL THEN 0 ELSE 1 END AS [Val_DataExportPretendent]
			, ISNULL( FORMAT(CONVERT(DATETIME,K.CtrlIntDt_ItauPretReq), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')	AS [Data Exportação Pretendente Requisição] 
			, CASE WHEN K.CtrlIntDt_ItauPretReq IS NULL THEN 0 ELSE 1 END AS [Val_DataExportPretendentReq]
	FROM	[hrh-data].[dbo].[ITAUUNIBANCO_Requisicao]  AS A WITH(NOLOCK)		INNER JOIN [hrh-data].[dbo].[ZZZ_Cliente52932-Ficha312337-Resp] AS A1 WITH(NOLOCK) ON A1.CodPerg_resp = 1956915 
																AND A1.TxtLim_resp = A.Cod_ItauReq
			LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Workflow] AS A2 WITH(NOLOCK) ON A2.CodRespCabFic_rvw = A1.CodCab_resp
			LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Controle]	AS A3 WITH(NOLOCK) ON A3.Cod_rvc = A2.CodRVC_rvw
			LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Gestores]	AS A4 WITH(NOLOCK) ON A4.Cod_rv = A3.CodRV_rvc

																OUTER APPLY ( SELECT A.*, B.Cod_Cand, B.Nome_Cand, B.CPF_cand, B.CEP_cand FROM [hrh-data].[dbo].[CandidatoxVagas] AS A	WITH(NOLOCK)																         INNER JOIN [hrh-data].[dbo].[Candidatos] AS B WITH(NOLOCK) ON A.CodCand_CandVaga = B.Cod_cand
																			  WHERE	A2.CodVaga_rvw = A.CodVaga_candVaga ) AS C

																OUTER APPLY ( SELECT A1.* FROM [hrh-data].[dbo].[Funcionarios] AS A1 WITH(NOLOCK)
																			  WHERE A2.CodFuncResp_rvw = A1.Cod_func ) AS D 
			LEFT OUTER JOIN [hrh-data].[dbo].[Vagas] AS F WITH(NOLOCK) ON A2.CodVaga_rvw = F.Cod_vaga
																OUTER APPLY ( SELECT TOP 1 	A1.TxtOpcResp_resp AS [Status_Vaga] , A2.Data_resp AS [Data_Status_Vaga]
																			  FROM [hrh-data].[dbo].[ZZZ_Cliente52932-Ficha312343-Resp] AS A1 WITH(NOLOCK)
																					INNER JOIN [hrh-data].[dbo].[ZZZ_Cliente52932-Ficha312343-Resp] AS A2 WITH(NOLOCK)
																					ON  A1.CodCab_resp = A2.CodCab_resp
																					AND A1.IdxSubFicha_resp = A2.IdxSubFicha_resp
																					AND A1.CodVaga_resp = A2.CodVaga_resp
																					AND A1.CodCand_resp = A2.CodCand_resp
																			  WHERE	A1.CodVaga_resp = F.Cod_vaga 
																					AND A1.CodSubPerg_resp = 1956971
																					AND A2.CodSubPerg_resp = 1956972	
																			  ORDER BY A1.IdxSubFicha_resp DESC) AS E
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc01 WITH(NOLOCK) ON F.CodSubdivCompart_vaga = Parc01.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc02 WITH(NOLOCK) ON F.CodSubdivCompart2_vaga = Parc02.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc03 WITH(NOLOCK) ON F.CodSubdivCompart3_vaga = Parc03.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc04 WITH(NOLOCK) ON F.CodSubdivCompart4_vaga = Parc04.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc05 WITH(NOLOCK) ON F.CodSubdivCompart5_vaga = Parc05.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc06 WITH(NOLOCK) ON F.CodSubdivCompart6_vaga = Parc06.CodSubDivisaoVAGAS_ItauParc														
															OUTER APPLY ( SELECT A2.Descr_stGCand AS [Status_Global_Candidato]
																				, A1.TxtStatus_candCli AS [Cliente_Status_Global]
																		  FROM	[hrh-data].[dbo].[CandidatoxCliente] AS A1 WITH(NOLOCK)
																		  LEFT OUTER JOIN [hrh-data].[dbo].[Cad_stGlobalCand] AS A2 WITH(NOLOCK) ON A2.CodCli_stGCand = A1.CodCliente_candCli																	  AND A1.CodStatus_candCli = A2.Cod_stGCand 
																		  WHERE C.CodCli_candVaga = A1.CodCliente_candCli  
																				AND C.codcand_candvaga = A1.CodCand_candCli ) AS G
				LEFT OUTER JOIN [hrh-data].[dbo].[Cad_fases] AS H WITH(NOLOCK) ON C.CodFase_candVaga = H.Cod_fase
															OUTER APPLY ( SELECT * FROM [hrh-data].[dbo].[HistoricoFasesCand] AS A1 WITH(NOLOCK)
																		  WHERE A1.CodCand_faseCand = C.CodCand_candVaga 
																				AND A1.CodVaga_faseCand = C.CodVaga_CandVaga 
																				AND A1.CodFase_faseCand = H.Cod_fase ) AS I
				LEFT OUTER JOIN [hrh-data].[dbo].[ITAUUNIBANCO_Pretendente] AS J WITH(NOLOCK) ON C.CPF_Cand = J.CPF_ItauPret
				LEFT OUTER JOIN [hrh-data].[dbo].[ITAUUNIBANCO_PretendenteRequisicao] AS K WITH(NOLOCK) ON J.CPF_ItauPret = K.CPFPret_ItauPretReq AND K.CodReq_ItauPretReq = A.Cod_ItauReq
				LEFT OUTER JOIN [hrh-data].[dbo].[ZZZ_Cliente52932-Fichas-RespCab] AS L WITH(NOLOCK) ON C.Cod_cand = L.CodCand_respCab 
				AND L.CodFicha_respCab = 315166 AND L.MaisRecente_respCab = 1
	WHERE	CAST(A.CtrlDt_ItauReq AS DATE) > '20141218' -- Requisição válida ( não é teste )	
			AND C.Cod_cand = @Cod_cand

END
/* FIM VARIÁVEL @Cod_cand */




/* INÍCIO VARIÁVEL @CPF_cand */
IF	@CPF_cand IS NOT NULL
BEGIN


	-- Query:
	SELECT	  A.Cod_ItauReq					AS [Requisição Itaú]
			, A2.Cod_rvw					AS [Requisição VAGAS]
			, C.CodVaga_candVaga			AS [Código da vaga]
			, A.Requisitante_Nome_ItauReq	AS [Nome do Requisitante]
			, D.Nome_func					AS [Nicho]
			, E.[Status_Vaga]				AS [Status da Vaga]
			, parc01.Nome_ItauParc			AS [1ªParceira]
			, parc02.Nome_ItauParc			AS [2ªParceira]
			, parc03.Nome_ItauParc			AS [3ªParceira]
			, parc04.Nome_ItauParc			AS [4ªParceira]
			, parc05.Nome_ItauParc			AS [5ªParceira]
			, parc06.Nome_ItauParc			AS [6ªParceira]
			, C.Cod_cand					AS [Código do candidato]
			, C.Nome_cand					AS [Nome]
			, C.CPF_cand					AS [CPF]
			, C.CEP_cand					AS [CEP]
			, G.[Status_Global_Candidato]	AS [Status Global Candidato]
			, G.[Cliente_Status_Global]		AS [Comentário Status Global]
			, H.Nome_fase					AS [Fase]
			, ISNULL( FORMAT(CONVERT(DATETIME, A.CtrlDt_ItauReq), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')		AS [Data Importação Requisição]
			, CASE WHEN A.CtrlDt_ItauReq IS NULL THEN 0 ELSE 1 END AS [Val_DataImportReq]
			, ISNULL( FORMAT(CONVERT(DATETIME, A2.Data_rvw), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')			AS [Data Abertura Requisição (VAGAS)]
			, CASE WHEN A2.Data_rvw IS NULL THEN 0 ELSE 1 END AS [Val_AbertReqVAGAS]
			, ISNULL( FORMAT(CONVERT(DATETIME, F.DtCriacao_vaga), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')		AS [Data criação Vaga]
			, CASE WHEN F.dtCriacao_vaga IS NULL THEN 0 ELSE 1 END AS [Val_DataCriacaoVaga]
			, ISNULL( FORMAT(CONVERT(DATETIME, E.[Data_Status_Vaga]),'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO') AS [Data Status Vaga]
			, CASE WHEN E.[Data_Status_Vaga] IS NULL THEN 0 ELSE 1 END AS [Val_DataStatusVaga]
			, ISNULL( FORMAT(CONVERT(DATETIME, C.[FonteData_candVaga]), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')	AS [Data Candidatura]
			, CASE WHEN C.FonteData_candVaga IS NULL THEN 0 ELSE 1 END AS [Val_FonteData]
			, ISNULL( FORMAT(CONVERT(DATETIME, L.Data_respCab), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')			AS [Data resposta ficha complementar]
			, CASE WHEN L.Data_respCab IS NULL THEN 0 ELSE 1 END AS [Val_DatarespCab]
			, ISNULL( FORMAT(CONVERT(DATETIME, DtEntrada_faseCand), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')		AS [Data Movimentação Fase]
			, CASE WHEN I.DtEntrada_faseCand IS NULL THEN 0 ELSE 1 END AS [Val_DataMovimentFase]
			, ISNULL( FORMAT(CONVERT(DATETIME, J.CtrlIntDt_ItauPret), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')	AS [Data Exportação Pretendente]
			, CASE WHEN J.CtrlIntDt_ItauPret IS NULL THEN 0 ELSE 1 END AS [Val_DataExportPretendent]
			, ISNULL( FORMAT(CONVERT(DATETIME,K.CtrlIntDt_ItauPretReq), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')	AS [Data Exportação Pretendente Requisição] 
			, CASE WHEN K.CtrlIntDt_ItauPretReq IS NULL THEN 0 ELSE 1 END AS [Val_DataExportPretendentReq]
	FROM	[hrh-data].[dbo].[ITAUUNIBANCO_Requisicao] AS A WITH(NOLOCK)		INNER JOIN [hrh-data].[dbo].[ZZZ_Cliente52932-Ficha312337-Resp] AS A1 WITH(NOLOCK) ON A1.CodPerg_resp = 1956915 
																AND A1.TxtLim_resp = A.Cod_ItauReq
			LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Workflow] AS A2 WITH(NOLOCK) ON A2.CodRespCabFic_rvw = A1.CodCab_resp
			LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Controle]	AS A3 WITH(NOLOCK) ON A3.Cod_rvc = A2.CodRVC_rvw
			LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Gestores]	AS A4 WITH(NOLOCK) ON A4.Cod_rv = A3.CodRV_rvc

																OUTER APPLY ( SELECT A.*, B.Cod_Cand, B.Nome_Cand, B.CPF_cand, B.CEP_cand FROM [hrh-data].[dbo].[CandidatoxVagas] AS A	WITH(NOLOCK)																         INNER JOIN [hrh-data].[dbo].[Candidatos] AS B WITH(NOLOCK) ON A.CodCand_CandVaga = B.Cod_cand
																			  WHERE	A2.CodVaga_rvw = A.CodVaga_candVaga ) AS C

																OUTER APPLY ( SELECT A1.* FROM [hrh-data].[dbo].[Funcionarios] AS A1 WITH(NOLOCK)
																			  WHERE A2.CodFuncResp_rvw = A1.Cod_func ) AS D 
			LEFT OUTER JOIN [hrh-data].[dbo].[Vagas] AS F WITH(NOLOCK) ON A2.CodVaga_rvw = F.Cod_vaga
																OUTER APPLY ( SELECT TOP 1 	A1.TxtOpcResp_resp AS [Status_Vaga] , A2.Data_resp AS [Data_Status_Vaga]
																			  FROM [hrh-data].[dbo].[ZZZ_Cliente52932-Ficha312343-Resp] AS A1 WITH(NOLOCK)
																					INNER JOIN [hrh-data].[dbo].[ZZZ_Cliente52932-Ficha312343-Resp] AS A2 WITH(NOLOCK) 
																					ON  A1.CodCab_resp = A2.CodCab_resp
																					AND A1.IdxSubFicha_resp = A2.IdxSubFicha_resp
																					AND A1.CodVaga_resp = A2.CodVaga_resp
																					AND A1.CodCand_resp = A2.CodCand_resp
																			  WHERE	A1.CodVaga_resp = F.Cod_vaga 
																					AND A1.CodSubPerg_resp = 1956971
																					AND A2.CodSubPerg_resp = 1956972	
																			  ORDER BY A1.IdxSubFicha_resp DESC) AS E
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc01 WITH(NOLOCK) ON F.CodSubdivCompart_vaga = Parc01.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc02 WITH(NOLOCK) ON F.CodSubdivCompart2_vaga = Parc02.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc03 WITH(NOLOCK) ON F.CodSubdivCompart3_vaga = Parc03.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc04 WITH(NOLOCK) ON F.CodSubdivCompart4_vaga = Parc04.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc05 WITH(NOLOCK) ON F.CodSubdivCompart5_vaga = Parc05.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc06 WITH(NOLOCK) ON F.CodSubdivCompart6_vaga = Parc06.CodSubDivisaoVAGAS_ItauParc														
															OUTER APPLY ( SELECT A2.Descr_stGCand AS [Status_Global_Candidato]
																				, A1.TxtStatus_candCli AS [Cliente_Status_Global]
																		  FROM	[hrh-data].[dbo].[CandidatoxCliente] AS A1 WITH(NOLOCK)
																		  LEFT OUTER JOIN [hrh-data].[dbo].[Cad_stGlobalCand] AS A2 WITH(NOLOCK) ON A2.CodCli_stGCand = A1.CodCliente_candCli																	  AND A1.CodStatus_candCli = A2.Cod_stGCand 
																		  WHERE C.CodCli_candVaga = A1.CodCliente_candCli  
																				AND C.codcand_candvaga = A1.CodCand_candCli ) AS G
				LEFT OUTER JOIN [hrh-data].[dbo].[Cad_fases] AS H WITH(NOLOCK) ON C.CodFase_candVaga = H.Cod_fase
															OUTER APPLY ( SELECT * FROM [hrh-data].[dbo].[HistoricoFasesCand] AS A1 WITH(NOLOCK) 
																		  WHERE A1.CodCand_faseCand = C.CodCand_candVaga 
																				AND A1.CodVaga_faseCand = C.CodVaga_CandVaga 
																				AND A1.CodFase_faseCand = H.Cod_fase ) AS I
				LEFT OUTER JOIN [hrh-data].[dbo].[ITAUUNIBANCO_Pretendente] AS J WITH(NOLOCK) ON C.CPF_Cand = J.CPF_ItauPret
				LEFT OUTER JOIN [hrh-data].[dbo].[ITAUUNIBANCO_PretendenteRequisicao] AS K WITH(NOLOCK) ON J.CPF_ItauPret = K.CPFPret_ItauPretReq AND K.CodReq_ItauPretReq = A.Cod_ItauReq
				LEFT OUTER JOIN [hrh-data].[dbo].[ZZZ_Cliente52932-Fichas-RespCab] AS L WITH(NOLOCK) ON C.Cod_cand = L.CodCand_respCab 
				AND L.CodFicha_respCab = 315166 AND L.MaisRecente_respCab = 1
	WHERE	CAST(A.CtrlDt_ItauReq AS DATE) > '20141218' -- Requisição válida ( não é teste )	
			AND C.CPF_cand = @CPF_cand

END
/* FIM VARIÁVEL @CPF_cand */




/* INÍCIO VARIÁVEL @Cod_ItauReq */
IF	@Cod_ItauReq IS NOT NULL
BEGIN

	-- Query:
	SELECT	  A.Cod_ItauReq					AS [Requisição Itaú]
			, A2.Cod_rvw					AS [Requisição VAGAS]
			, C.CodVaga_candVaga			AS [Código da vaga]
			, A.Requisitante_Nome_ItauReq	AS [Nome do Requisitante]
			, D.Nome_func					AS [Nicho]
			, E.[Status_Vaga]				AS [Status da Vaga]
			, parc01.Nome_ItauParc			AS [1ªParceira]
			, parc02.Nome_ItauParc			AS [2ªParceira]
			, parc03.Nome_ItauParc			AS [3ªParceira]
			, parc04.Nome_ItauParc			AS [4ªParceira]
			, parc05.Nome_ItauParc			AS [5ªParceira]
			, parc06.Nome_ItauParc			AS [6ªParceira]
			, C.Cod_cand					AS [Código do candidato]
			, C.Nome_cand					AS [Nome]
			, C.CPF_cand					AS [CPF]
			, C.CEP_cand					AS [CEP]
			, G.[Status_Global_Candidato]	AS [Status Global Candidato]
			, G.[Cliente_Status_Global]		AS [Comentário Status Global]
			, H.Nome_fase					AS [Fase]
			, ISNULL( FORMAT(CONVERT(DATETIME, A.CtrlDt_ItauReq), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')		AS [Data Importação Requisição]
			, CASE WHEN A.CtrlDt_ItauReq IS NULL THEN 0 ELSE 1 END AS [Val_DataImportReq]
			, ISNULL( FORMAT(CONVERT(DATETIME, A2.Data_rvw), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')			AS [Data Abertura Requisição (VAGAS)]
			, CASE WHEN A2.Data_rvw IS NULL THEN 0 ELSE 1 END AS [Val_AbertReqVAGAS]
			, ISNULL( FORMAT(CONVERT(DATETIME, F.DtCriacao_vaga), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')		AS [Data criação Vaga]
			, CASE WHEN F.dtCriacao_vaga IS NULL THEN 0 ELSE 1 END AS [Val_DataCriacaoVaga]
			, ISNULL( FORMAT(CONVERT(DATETIME, E.[Data_Status_Vaga]),'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO') AS [Data Status Vaga]
			, CASE WHEN E.[Data_Status_Vaga] IS NULL THEN 0 ELSE 1 END AS [Val_DataStatusVaga]
			, ISNULL( FORMAT(CONVERT(DATETIME, C.[FonteData_candVaga]), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')	AS [Data Candidatura]
			, CASE WHEN C.FonteData_candVaga IS NULL THEN 0 ELSE 1 END AS [Val_FonteData]
			, ISNULL( FORMAT(CONVERT(DATETIME, L.Data_respCab), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')			AS [Data resposta ficha complementar]
			, CASE WHEN L.Data_respCab IS NULL THEN 0 ELSE 1 END AS [Val_DatarespCab]
			, ISNULL( FORMAT(CONVERT(DATETIME, DtEntrada_faseCand), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')		AS [Data Movimentação Fase]
			, CASE WHEN I.DtEntrada_faseCand IS NULL THEN 0 ELSE 1 END AS [Val_DataMovimentFase]
			, ISNULL( FORMAT(CONVERT(DATETIME, J.CtrlIntDt_ItauPret), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')	AS [Data Exportação Pretendente]
			, CASE WHEN J.CtrlIntDt_ItauPret IS NULL THEN 0 ELSE 1 END AS [Val_DataExportPretendent]
			, ISNULL( FORMAT(CONVERT(DATETIME,K.CtrlIntDt_ItauPretReq), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')	AS [Data Exportação Pretendente Requisição] 
			, CASE WHEN K.CtrlIntDt_ItauPretReq IS NULL THEN 0 ELSE 1 END AS [Val_DataExportPretendentReq]
	FROM	[hrh-data].[dbo].[ITAUUNIBANCO_Requisicao] AS A	WITH(NOLOCK)	INNER JOIN [hrh-data].[dbo].[ZZZ_Cliente52932-Ficha312337-Resp] AS A1 WITH(NOLOCK) ON A1.CodPerg_resp = 1956915 
																AND A1.TxtLim_resp = A.Cod_ItauReq
			LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Workflow] AS A2 WITH(NOLOCK) ON A2.CodRespCabFic_rvw = A1.CodCab_resp
			LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Controle]	AS A3 WITH(NOLOCK) ON A3.Cod_rvc = A2.CodRVC_rvw
			LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Gestores]	AS A4 WITH(NOLOCK) ON A4.Cod_rv = A3.CodRV_rvc

																OUTER APPLY ( SELECT A.*, B.Cod_Cand, B.Nome_Cand, B.CPF_cand, B.CEP_cand FROM [hrh-data].[dbo].[CandidatoxVagas] AS A WITH(NOLOCK)																	         INNER JOIN [hrh-data].[dbo].[Candidatos] AS B WITH(NOLOCK) ON A.CodCand_CandVaga = B.Cod_cand
																			  WHERE	A2.CodVaga_rvw = A.CodVaga_candVaga ) AS C

																OUTER APPLY ( SELECT A1.* FROM [hrh-data].[dbo].[Funcionarios] AS A1 WITH(NOLOCK)
																			  WHERE A2.CodFuncResp_rvw = A1.Cod_func ) AS D 
			LEFT OUTER JOIN [hrh-data].[dbo].[Vagas] AS F WITH(NOLOCK) ON A2.CodVaga_rvw = F.Cod_vaga
																OUTER APPLY ( SELECT TOP 1 	A1.TxtOpcResp_resp AS [Status_Vaga] , A2.Data_resp AS [Data_Status_Vaga]
																			  FROM [hrh-data].[dbo].[ZZZ_Cliente52932-Ficha312343-Resp] AS A1 WITH(NOLOCK)
																					INNER JOIN [hrh-data].[dbo].[ZZZ_Cliente52932-Ficha312343-Resp] AS A2 WITH(NOLOCK)
																					ON  A1.CodCab_resp = A2.CodCab_resp
																					AND A1.IdxSubFicha_resp = A2.IdxSubFicha_resp
																					AND A1.CodVaga_resp = A2.CodVaga_resp
																					AND A1.CodCand_resp = A2.CodCand_resp
																			  WHERE	A1.CodVaga_resp = F.Cod_vaga 
																					AND A1.CodSubPerg_resp = 1956971
																					AND A2.CodSubPerg_resp = 1956972	
																			  ORDER BY A1.IdxSubFicha_resp DESC) AS E
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc01 WITH(NOLOCK) ON F.CodSubdivCompart_vaga = Parc01.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc02 WITH(NOLOCK) ON F.CodSubdivCompart2_vaga = Parc02.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc03 WITH(NOLOCK) ON F.CodSubdivCompart3_vaga = Parc03.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc04 WITH(NOLOCK) ON F.CodSubdivCompart4_vaga = Parc04.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc05 WITH(NOLOCK) ON F.CodSubdivCompart5_vaga = Parc05.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc06 WITH(NOLOCK) ON F.CodSubdivCompart6_vaga = Parc06.CodSubDivisaoVAGAS_ItauParc														
															OUTER APPLY ( SELECT A2.Descr_stGCand AS [Status_Global_Candidato]
																				, A1.TxtStatus_candCli AS [Cliente_Status_Global]
																		  FROM	[hrh-data].[dbo].[CandidatoxCliente] AS A1 WITH(NOLOCK)
																		  LEFT OUTER JOIN [hrh-data].[dbo].[Cad_stGlobalCand] AS A2 WITH(NOLOCK) ON A2.CodCli_stGCand = A1.CodCliente_candCli																	  AND A1.CodStatus_candCli = A2.Cod_stGCand 
																		  WHERE C.CodCli_candVaga = A1.CodCliente_candCli  
																				AND C.codcand_candvaga = A1.CodCand_candCli ) AS G
				LEFT OUTER JOIN [hrh-data].[dbo].[Cad_fases] AS H WITH(NOLOCK) ON C.CodFase_candVaga = H.Cod_fase
															OUTER APPLY ( SELECT * FROM [hrh-data].[dbo].[HistoricoFasesCand] AS A1 WITH(NOLOCK)
																		  WHERE A1.CodCand_faseCand = C.CodCand_candVaga 
																				AND A1.CodVaga_faseCand = C.CodVaga_CandVaga 
																				AND A1.CodFase_faseCand = H.Cod_fase ) AS I
				LEFT OUTER JOIN [hrh-data].[dbo].[ITAUUNIBANCO_Pretendente] AS J WITH(NOLOCK) ON C.CPF_Cand = J.CPF_ItauPret
				LEFT OUTER JOIN [hrh-data].[dbo].[ITAUUNIBANCO_PretendenteRequisicao] AS K WITH(NOLOCK) ON J.CPF_ItauPret = K.CPFPret_ItauPretReq AND K.CodReq_ItauPretReq = A.Cod_ItauReq
				LEFT OUTER JOIN [hrh-data].[dbo].[ZZZ_Cliente52932-Fichas-RespCab] AS L WITH(NOLOCK) ON C.Cod_cand = L.CodCand_respCab 
				AND L.CodFicha_respCab = 315166 AND L.MaisRecente_respCab = 1
	WHERE	CAST(A.CtrlDt_ItauReq AS DATE) > '20141218' -- Requisição válida ( não é teste )	
			AND A.Cod_ItauReq = @Cod_ItauReq

END
/* FIM VARIÁVEL @Cod_ItauReq */




/* INÍCIO VARIÁVEL @CodReq_vagas */
IF	@CodReq_vagas IS NOT NULL
BEGIN


	-- Query:
	SELECT	  A.Cod_ItauReq					AS [Requisição Itaú]
			, A2.Cod_rvw					AS [Requisição VAGAS]
			, C.CodVaga_candVaga			AS [Código da vaga]
			, A.Requisitante_Nome_ItauReq	AS [Nome do Requisitante]
			, D.Nome_func					AS [Nicho]
			, E.[Status_Vaga]				AS [Status da Vaga]
			, parc01.Nome_ItauParc			AS [1ªParceira]
			, parc02.Nome_ItauParc			AS [2ªParceira]
			, parc03.Nome_ItauParc			AS [3ªParceira]
			, parc04.Nome_ItauParc			AS [4ªParceira]
			, parc05.Nome_ItauParc			AS [5ªParceira]
			, parc06.Nome_ItauParc			AS [6ªParceira]
			, C.Cod_cand					AS [Código do candidato]
			, C.Nome_cand					AS [Nome]
			, C.CPF_cand					AS [CPF]
			, C.CEP_cand					AS [CEP]
			, G.[Status_Global_Candidato]	AS [Status Global Candidato]
			, G.[Cliente_Status_Global]		AS [Comentário Status Global]
			, H.Nome_fase					AS [Fase]
			, ISNULL( FORMAT(CONVERT(DATETIME, A.CtrlDt_ItauReq), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')		AS [Data Importação Requisição]
			, CASE WHEN A.CtrlDt_ItauReq IS NULL THEN 0 ELSE 1 END AS [Val_DataImportReq]
			, ISNULL( FORMAT(CONVERT(DATETIME, A2.Data_rvw), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')			AS [Data Abertura Requisição (VAGAS)]
			, CASE WHEN A2.Data_rvw IS NULL THEN 0 ELSE 1 END AS [Val_AbertReqVAGAS]
			, ISNULL( FORMAT(CONVERT(DATETIME, F.DtCriacao_vaga), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')		AS [Data criação Vaga]
			, CASE WHEN F.dtCriacao_vaga IS NULL THEN 0 ELSE 1 END AS [Val_DataCriacaoVaga]
			, ISNULL( FORMAT(CONVERT(DATETIME, E.[Data_Status_Vaga]),'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO') AS [Data Status Vaga]
			, CASE WHEN E.[Data_Status_Vaga] IS NULL THEN 0 ELSE 1 END AS [Val_DataStatusVaga]
			, ISNULL( FORMAT(CONVERT(DATETIME, C.[FonteData_candVaga]), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')	AS [Data Candidatura]
			, CASE WHEN C.FonteData_candVaga IS NULL THEN 0 ELSE 1 END AS [Val_FonteData]
			, ISNULL( FORMAT(CONVERT(DATETIME, L.Data_respCab), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')			AS [Data resposta ficha complementar]
			, CASE WHEN L.Data_respCab IS NULL THEN 0 ELSE 1 END AS [Val_DatarespCab]
			, ISNULL( FORMAT(CONVERT(DATETIME, DtEntrada_faseCand), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')		AS [Data Movimentação Fase]
			, CASE WHEN I.DtEntrada_faseCand IS NULL THEN 0 ELSE 1 END AS [Val_DataMovimentFase]
			, ISNULL( FORMAT(CONVERT(DATETIME, J.CtrlIntDt_ItauPret), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')	AS [Data Exportação Pretendente]
			, CASE WHEN J.CtrlIntDt_ItauPret IS NULL THEN 0 ELSE 1 END AS [Val_DataExportPretendent]
			, ISNULL( FORMAT(CONVERT(DATETIME,K.CtrlIntDt_ItauPretReq), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')	AS [Data Exportação Pretendente Requisição] 
			, CASE WHEN K.CtrlIntDt_ItauPretReq IS NULL THEN 0 ELSE 1 END AS [Val_DataExportPretendentReq]
	FROM	[hrh-data].[dbo].[ITAUUNIBANCO_Requisicao] AS A WITH(NOLOCK)		INNER JOIN [hrh-data].[dbo].[ZZZ_Cliente52932-Ficha312337-Resp] AS A1 WITH(NOLOCK) ON A1.CodPerg_resp = 1956915 
																AND A1.TxtLim_resp = A.Cod_ItauReq
			LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Workflow] AS A2 WITH(NOLOCK) ON A2.CodRespCabFic_rvw = A1.CodCab_resp
			LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Controle]	AS A3 WITH(NOLOCK) ON A3.Cod_rvc = A2.CodRVC_rvw
			LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Gestores]	AS A4 WITH(NOLOCK) ON A4.Cod_rv = A3.CodRV_rvc

																OUTER APPLY ( SELECT A.*, B.Cod_Cand, B.Nome_Cand, B.CPF_cand, B.CEP_cand FROM [hrh-data].[dbo].[CandidatoxVagas] AS A WITH(NOLOCK)																	         INNER JOIN [hrh-data].[dbo].[Candidatos] AS B WITH(NOLOCK) ON A.CodCand_CandVaga = B.Cod_cand
																			  WHERE	A2.CodVaga_rvw = A.CodVaga_candVaga ) AS C

																OUTER APPLY ( SELECT A1.* FROM [hrh-data].[dbo].[Funcionarios] AS A1 WITH(NOLOCK)
																			  WHERE A2.CodFuncResp_rvw = A1.Cod_func ) AS D 
			LEFT OUTER JOIN [hrh-data].[dbo].[Vagas] AS F WITH(NOLOCK) ON A2.CodVaga_rvw = F.Cod_vaga
																OUTER APPLY ( SELECT TOP 1 	A1.TxtOpcResp_resp AS [Status_Vaga] , A2.Data_resp AS [Data_Status_Vaga]
																			  FROM [hrh-data].[dbo].[ZZZ_Cliente52932-Ficha312343-Resp] AS A1 WITH(NOLOCK)
																					INNER JOIN [hrh-data].[dbo].[ZZZ_Cliente52932-Ficha312343-Resp] AS A2 WITH(NOLOCK) 
																					ON  A1.CodCab_resp = A2.CodCab_resp
																					AND A1.IdxSubFicha_resp = A2.IdxSubFicha_resp
																					AND A1.CodVaga_resp = A2.CodVaga_resp
																					AND A1.CodCand_resp = A2.CodCand_resp
																			  WHERE	A1.CodVaga_resp = F.Cod_vaga 
																					AND A1.CodSubPerg_resp = 1956971
																					AND A2.CodSubPerg_resp = 1956972	
																			  ORDER BY A1.IdxSubFicha_resp DESC) AS E
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc01 WITH(NOLOCK) ON F.CodSubdivCompart_vaga = Parc01.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc02 WITH(NOLOCK) ON F.CodSubdivCompart2_vaga = Parc02.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc03 WITH(NOLOCK) ON F.CodSubdivCompart3_vaga = Parc03.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc04 WITH(NOLOCK) ON F.CodSubdivCompart4_vaga = Parc04.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc05 WITH(NOLOCK) ON F.CodSubdivCompart5_vaga = Parc05.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc06 WITH(NOLOCK) ON F.CodSubdivCompart6_vaga = Parc06.CodSubDivisaoVAGAS_ItauParc														
															OUTER APPLY ( SELECT A2.Descr_stGCand AS [Status_Global_Candidato]
																				, A1.TxtStatus_candCli AS [Cliente_Status_Global]
																		  FROM	[hrh-data].[dbo].[CandidatoxCliente] AS A1 WITH(NOLOCK) 
																		  LEFT OUTER JOIN [hrh-data].[dbo].[Cad_stGlobalCand] AS A2 WITH(NOLOCK) ON A2.CodCli_stGCand = A1.CodCliente_candCli																	  AND A1.CodStatus_candCli = A2.Cod_stGCand 
																		  WHERE C.CodCli_candVaga = A1.CodCliente_candCli  
																				AND C.codcand_candvaga = A1.CodCand_candCli ) AS G
				LEFT OUTER JOIN [hrh-data].[dbo].[Cad_fases] AS H WITH(NOLOCK) ON C.CodFase_candVaga = H.Cod_fase
															OUTER APPLY ( SELECT * FROM [hrh-data].[dbo].[HistoricoFasesCand] AS A1 WITH(NOLOCK) 
																		  WHERE A1.CodCand_faseCand = C.CodCand_candVaga 
																				AND A1.CodVaga_faseCand = C.CodVaga_CandVaga 
																				AND A1.CodFase_faseCand = H.Cod_fase ) AS I
				LEFT OUTER JOIN [hrh-data].[dbo].[ITAUUNIBANCO_Pretendente] AS J WITH(NOLOCK) ON C.CPF_Cand = J.CPF_ItauPret
				LEFT OUTER JOIN [hrh-data].[dbo].[ITAUUNIBANCO_PretendenteRequisicao] AS K WITH(NOLOCK) ON J.CPF_ItauPret = K.CPFPret_ItauPretReq AND K.CodReq_ItauPretReq = A.Cod_ItauReq
				LEFT OUTER JOIN [hrh-data].[dbo].[ZZZ_Cliente52932-Fichas-RespCab] AS L WITH(NOLOCK) ON C.Cod_cand = L.CodCand_respCab 
				AND L.CodFicha_respCab = 315166 AND L.MaisRecente_respCab = 1
	WHERE	CAST(A.CtrlDt_ItauReq AS DATE) > '20141218' -- Requisição válida ( não é teste )	
			AND A2.Cod_rvw = @CodReq_vagas

END
/* FIM VARIÁVEL @CodReq_vagas */



/* INÍCIO VARIÁVEL @Cod_vaga */
IF	@Cod_vaga IS NOT NULL
BEGIN

	-- Query:
	SELECT	  A.Cod_ItauReq					AS [Requisição Itaú]
			, A2.Cod_rvw					AS [Requisição VAGAS]
			, C.CodVaga_candVaga			AS [Código da vaga]
			, A.Requisitante_Nome_ItauReq	AS [Nome do Requisitante]
			, D.Nome_func					AS [Nicho]
			, E.[Status_Vaga]				AS [Status da Vaga]
			, parc01.Nome_ItauParc			AS [1ªParceira]
			, parc02.Nome_ItauParc			AS [2ªParceira]
			, parc03.Nome_ItauParc			AS [3ªParceira]
			, parc04.Nome_ItauParc			AS [4ªParceira]
			, parc05.Nome_ItauParc			AS [5ªParceira]
			, parc06.Nome_ItauParc			AS [6ªParceira]
			, C.Cod_cand					AS [Código do candidato]
			, C.Nome_cand					AS [Nome]
			, C.CPF_cand					AS [CPF]
			, C.CEP_cand					AS [CEP]
			, G.[Status_Global_Candidato]	AS [Status Global Candidato]
			, G.[Cliente_Status_Global]		AS [Comentário Status Global]
			, H.Nome_fase					AS [Fase]
			, ISNULL( FORMAT(CONVERT(DATETIME, A.CtrlDt_ItauReq), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')		AS [Data Importação Requisição]
			, CASE WHEN A.CtrlDt_ItauReq IS NULL THEN 0 ELSE 1 END AS [Val_DataImportReq]
			, ISNULL( FORMAT(CONVERT(DATETIME, A2.Data_rvw), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')			AS [Data Abertura Requisição (VAGAS)]
			, CASE WHEN A2.Data_rvw IS NULL THEN 0 ELSE 1 END AS [Val_AbertReqVAGAS]
			, ISNULL( FORMAT(CONVERT(DATETIME, F.DtCriacao_vaga), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')		AS [Data criação Vaga]
			, CASE WHEN F.dtCriacao_vaga IS NULL THEN 0 ELSE 1 END AS [Val_DataCriacaoVaga]
			, ISNULL( FORMAT(CONVERT(DATETIME, E.[Data_Status_Vaga]),'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO') AS [Data Status Vaga]
			, CASE WHEN E.[Data_Status_Vaga] IS NULL THEN 0 ELSE 1 END AS [Val_DataStatusVaga]
			, ISNULL( FORMAT(CONVERT(DATETIME, C.[FonteData_candVaga]), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')	AS [Data Candidatura]
			, CASE WHEN C.FonteData_candVaga IS NULL THEN 0 ELSE 1 END AS [Val_FonteData]
			, ISNULL( FORMAT(CONVERT(DATETIME, L.Data_respCab), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')			AS [Data resposta ficha complementar]
			, CASE WHEN L.Data_respCab IS NULL THEN 0 ELSE 1 END AS [Val_DatarespCab]
			, ISNULL( FORMAT(CONVERT(DATETIME, DtEntrada_faseCand), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')		AS [Data Movimentação Fase]
			, CASE WHEN I.DtEntrada_faseCand IS NULL THEN 0 ELSE 1 END AS [Val_DataMovimentFase]
			, ISNULL( FORMAT(CONVERT(DATETIME, J.CtrlIntDt_ItauPret), 'dd/MM/yyyy HH:mm:ss', 'pt-BR') , 'NÃO REALIZADO')	AS [Data Exportação Pretendente]
			, CASE WHEN J.CtrlIntDt_ItauPret IS NULL THEN 0 ELSE 1 END AS [Val_DataExportPretendent]
			, ISNULL( FORMAT(CONVERT(DATETIME,K.CtrlIntDt_ItauPretReq), 'dd/MM/yyyy HH:mm:ss', 'pt-BR'), 'NÃO REALIZADO')	AS [Data Exportação Pretendente Requisição] 
			, CASE WHEN K.CtrlIntDt_ItauPretReq IS NULL THEN 0 ELSE 1 END AS [Val_DataExportPretendentReq]
	FROM	[hrh-data].[dbo].[ITAUUNIBANCO_Requisicao] AS A	WITH(NOLOCK)	INNER JOIN [hrh-data].[dbo].[ZZZ_Cliente52932-Ficha312337-Resp] AS A1 WITH(NOLOCK) ON A1.CodPerg_resp = 1956915 
																AND A1.TxtLim_resp = A.Cod_ItauReq
			LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Workflow] AS A2 WITH(NOLOCK) ON A2.CodRespCabFic_rvw = A1.CodCab_resp
			LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Controle]	AS A3 WITH(NOLOCK) ON A3.Cod_rvc = A2.CodRVC_rvw
			LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Gestores]	AS A4 WITH(NOLOCK) ON A4.Cod_rv = A3.CodRV_rvc

																OUTER APPLY ( SELECT A.*, B.Cod_Cand, B.Nome_Cand, B.CPF_cand, B.CEP_cand FROM [hrh-data].[dbo].[CandidatoxVagas] AS A	WITH(NOLOCK)																         INNER JOIN [hrh-data].[dbo].[Candidatos] AS B WITH(NOLOCK) ON A.CodCand_CandVaga = B.Cod_cand
																			  WHERE	A2.CodVaga_rvw = A.CodVaga_candVaga ) AS C

																OUTER APPLY ( SELECT A1.* FROM [hrh-data].[dbo].[Funcionarios] AS A1 WITH(NOLOCK)
																			  WHERE A2.CodFuncResp_rvw = A1.Cod_func ) AS D 
			LEFT OUTER JOIN [hrh-data].[dbo].[Vagas] AS F WITH(NOLOCK) ON A2.CodVaga_rvw = F.Cod_vaga
																OUTER APPLY ( SELECT TOP 1 	A1.TxtOpcResp_resp AS [Status_Vaga] , A2.Data_resp AS [Data_Status_Vaga]
																			  FROM [hrh-data].[dbo].[ZZZ_Cliente52932-Ficha312343-Resp] AS A1 WITH(NOLOCK)
																					INNER JOIN [hrh-data].[dbo].[ZZZ_Cliente52932-Ficha312343-Resp] AS A2 WITH(NOLOCK)
																					ON  A1.CodCab_resp = A2.CodCab_resp
																					AND A1.IdxSubFicha_resp = A2.IdxSubFicha_resp
																					AND A1.CodVaga_resp = A2.CodVaga_resp
																					AND A1.CodCand_resp = A2.CodCand_resp
																			  WHERE	A1.CodVaga_resp = F.Cod_vaga 
																					AND A1.CodSubPerg_resp = 1956971
																					AND A2.CodSubPerg_resp = 1956972	
																			  ORDER BY A1.IdxSubFicha_resp DESC) AS E
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc01 WITH(NOLOCK) ON F.CodSubdivCompart_vaga = Parc01.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc02 WITH(NOLOCK) ON F.CodSubdivCompart2_vaga = Parc02.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc03 WITH(NOLOCK) ON F.CodSubdivCompart3_vaga = Parc03.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc04 WITH(NOLOCK) ON F.CodSubdivCompart4_vaga = Parc04.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc05 WITH(NOLOCK) ON F.CodSubdivCompart5_vaga = Parc05.CodSubDivisaoVAGAS_ItauParc
				LEFT OUTER JOIN [hrh-data].[dbo].ITAUUNIBANCO_Parceira Parc06 WITH(NOLOCK) ON F.CodSubdivCompart6_vaga = Parc06.CodSubDivisaoVAGAS_ItauParc														
															OUTER APPLY ( SELECT A2.Descr_stGCand AS [Status_Global_Candidato]
																				, A1.TxtStatus_candCli AS [Cliente_Status_Global]
																		  FROM	[hrh-data].[dbo].[CandidatoxCliente] AS A1 WITH(NOLOCK)
																		  LEFT OUTER JOIN [hrh-data].[dbo].[Cad_stGlobalCand] AS A2 WITH(NOLOCK) ON A2.CodCli_stGCand = A1.CodCliente_candCli																	  AND A1.CodStatus_candCli = A2.Cod_stGCand 
																		  WHERE C.CodCli_candVaga = A1.CodCliente_candCli  
																				AND C.codcand_candvaga = A1.CodCand_candCli ) AS G
				LEFT OUTER JOIN [hrh-data].[dbo].[Cad_fases] AS H WITH(NOLOCK) ON C.CodFase_candVaga = H.Cod_fase
															OUTER APPLY ( SELECT * FROM [hrh-data].[dbo].[HistoricoFasesCand] AS A1 WITH(NOLOCK) 
																		  WHERE A1.CodCand_faseCand = C.CodCand_candVaga 
																				AND A1.CodVaga_faseCand = C.CodVaga_CandVaga 
																				AND A1.CodFase_faseCand = H.Cod_fase ) AS I
				LEFT OUTER JOIN [hrh-data].[dbo].[ITAUUNIBANCO_Pretendente] AS J WITH(NOLOCK) ON C.CPF_Cand = J.CPF_ItauPret
				LEFT OUTER JOIN [hrh-data].[dbo].[ITAUUNIBANCO_PretendenteRequisicao] AS K WITH(NOLOCK) ON J.CPF_ItauPret = K.CPFPret_ItauPretReq AND K.CodReq_ItauPretReq = A.Cod_ItauReq
				LEFT OUTER JOIN [hrh-data].[dbo].[ZZZ_Cliente52932-Fichas-RespCab] AS L WITH(NOLOCK) ON C.Cod_cand = L.CodCand_respCab 
				AND L.CodFicha_respCab = 315166 AND L.MaisRecente_respCab = 1
	WHERE	CAST(A.CtrlDt_ItauReq AS DATE) > '20141218' -- Requisição válida ( não é teste )	
			AND F.Cod_vaga = @Cod_vaga

END

/* FIM VARIÁVEL @Cod_vaga */