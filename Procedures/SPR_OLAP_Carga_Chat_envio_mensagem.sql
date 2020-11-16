USE [vagas_dw] ;
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Chat_envio_mensagem' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Chat_envio_mensagem]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Chat_envio_mensagem]

AS
SET NOCOUNT ON

-- Apaga os registros existentes na olap que existem na oltp:
DELETE FROM [vagas_dw].[VAGAS_DW].[Chat_envio_mensagem]
FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM
WHERE	EXISTS (SELECT *
				FROM	[stage].[VAGAS_DW].[tmp_Chat_envio_mensagem] AS Chat_EM_A1
				WHERE	Chat_EM.Id_mensagem = Chat_EM_A1.id_mensagem) ;


-- Atualiza os registros pelo nível do id_mensagem antes de inserir na tabela OLAP:
UPDATE	[stage].[VAGAS_DW].[tmp_Chat_envio_mensagem]
SET		origem_destino = CONCAT(ISNULL(origem_mensagem, 'Sistema'), ' -> ', destino_mensagem),
		mensagem_lida = IIF(Data_leitura_mensagem IS NULL, 'Não', 'Sim'),
		ambiente_mensagem = CASE
								WHEN (origem_mensagem = 'Empresa' AND destino_mensagem = 'Candidato') 
									 OR (origem_mensagem = 'Candidato' AND destino_mensagem = 'Empresa')
									THEN 'VAGAS.com'
								WHEN (origem_mensagem = 'Empresa' AND destino_mensagem = 'Candidato em navegação exclusiva') 
									 OR (origem_mensagem = 'Candidato em navegação exclusiva' AND destino_mensagem = 'Empresa')
									THEN 'Navegação exclusiva'
								WHEN (origem_mensagem = 'Empresa' AND destino_mensagem = 'Gestor')
									OR (origem_mensagem = 'Gestor' AND destino_mensagem = 'Empresa')
									THEN 'Painel da vaga'
								ELSE 'Outros'
							END,
		tipo_mensagem = 
		IIF(origem_mensagem = 'Sistema' OR tipo_mensagem = 'system', 'Mensagem de sistema',
		IIF(origem_mensagem = 'Empresa' AND destino_mensagem = 'Empresa', 'Mensagem Empresa -> Empresa',
		IIF(origem_mensagem IN ('Candidato','Candidato em navegação exclusiva') AND destino_mensagem IN ('Candidato','Candidato em navegação exclusiva'), 'Mensagem Candidato -> Candidato',
		IIF(origem_mensagem IN ('Empresa', 'Gestor') AND destino_mensagem IN ('Empresa', 'Gestor'), 'Mensagem Empresa -> Gestor', 'Mensagem Empresa -> Candidato')))),
		origem_mensagem = ISNULL(origem_mensagem, 'Sistema')
FROM	[stage].[VAGAS_DW].[tmp_Chat_envio_mensagem] AS Chat_EM
WHERE	 (Chat_EM.origem_destino IS NULL
		 AND Chat_EM.mensagem_lida IS NULL
		 AND Chat_EM.ambiente_mensagem IS NULL) ;

-- Insere novos registros e atualiza os preexistentes:
INSERT INTO [vagas_dw].[VAGAS_DW].[Chat_envio_mensagem]
SELECT	*
FROM	[stage].[VAGAS_DW].[tmp_Chat_envio_mensagem] AS Chat_EM
WHERE	NOT EXISTS (SELECT *
					FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM_A1
					WHERE	Chat_EM.id_mensagem = Chat_EM_A1.Id_mensagem) ;

------------------------------------------------------------
-- Atualiza os registros no nível do id_chat na tabela OLAP:
------------------------------------------------------------
-- Atualiza o campo Resposta_candidato_chat:
UPDATE	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem]
SET		Resposta_candidato_chat = 
		ISNULL(( SELECT	TOP 1 'Sim'
				 FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM_A1
				 WHERE	Chat_EM.Id_mensagem = Chat_EM_A1.Id_mensagem
						AND EXISTS (SELECT *
									FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM_AA1
									WHERE	Chat_EM_A1.Id_chat = Chat_EM_AA1.Id_chat
											AND Chat_EM_AA1.Origem_mensagem IN ('Candidato', 'Candidato em navegação exclusiva'))), 'Não')
FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM
WHERE	Chat_EM.Ambiente_mensagem IN ('VAGAS.com', 'Navegação exclusiva')
		AND ISNULL(( SELECT	TOP 1 'Sim'
					 FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM_A1
					 WHERE	Chat_EM.Id_mensagem = Chat_EM_A1.Id_mensagem
							AND EXISTS (SELECT *
										FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM_AA1
										WHERE	Chat_EM_A1.Id_chat = Chat_EM_AA1.Id_chat
												AND Chat_EM_AA1.Origem_mensagem IN ('Candidato', 'Candidato em navegação exclusiva'))), 'Não') <> ISNULL(Chat_EM.Resposta_candidato_chat, '') ;

-- Atualiza o campo Resposta_usuario_chat:
UPDATE	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem]
SET		Resposta_usuario_chat = 
ISNULL(( SELECT	TOP 1 'Sim'
				 FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM_A1
				 WHERE	Chat_EM.Id_mensagem = Chat_EM_A1.Id_mensagem
						AND EXISTS (SELECT *
									FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM_AA1
									WHERE	Chat_EM_A1.Id_chat = Chat_EM_AA1.Id_chat
											AND Chat_EM_AA1.Origem_destino IN ('Empresa -> Empresa', 'Empresa -> Gestor', 'Gestor -> Empresa')
											AND Chat_EM_A1.Id_origem_mensagem = Chat_EM_AA1.Id_destino_mensagem)), 'Não')
FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM
WHERE	Chat_EM.Ambiente_mensagem IN ('Outros', 'Painel da vaga')
		AND Chat_EM.Origem_destino IN ('Empresa -> Empresa', 'Empresa -> Gestor', 'Gestor -> Empresa')
		AND ISNULL(( SELECT	TOP 1 'Sim'
					 FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM_A1
					 WHERE	Chat_EM.Id_mensagem = Chat_EM_A1.Id_mensagem
							AND EXISTS (SELECT *
										FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM_AA1
										WHERE	Chat_EM_A1.Id_chat = Chat_EM_AA1.Id_chat
												AND Chat_EM_AA1.Origem_destino  IN ('Empresa -> Empresa', 'Empresa -> Gestor', 'Gestor -> Empresa')
												AND Chat_EM_A1.Id_origem_mensagem = Chat_EM_AA1.Id_destino_mensagem)), 'Não') <> ISNULL(Chat_EM.Resposta_usuario_chat, '') ;

-- Atualiza o campo Chat_lido:
UPDATE	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem]
SET		Chat_lido =	ISNULL((SELECT TOP 1 'Não'
							FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM_A1
							WHERE	Chat_EM.Id_mensagem = Chat_EM_A1.Id_mensagem
									AND EXISTS (SELECT *
												FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM_AA1
												WHERE	Chat_EM_A1.Id_Chat = Chat_EM_AA1.Id_chat
														AND Chat_EM_AA1.Data_leitura_mensagem IS NULL)), 'Sim')
FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM
WHERE	Chat_EM.Ambiente_mensagem IN ('VAGAS.com', 'Navegação exclusiva', 'Outros', 'Painel da vaga')
		AND	ISNULL((SELECT TOP 1 'Não'
					FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM_A1
					WHERE	Chat_EM.Id_mensagem = Chat_EM_A1.Id_mensagem
							AND EXISTS (SELECT *
										FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem] AS Chat_EM_AA1
										WHERE	Chat_EM_A1.Id_Chat = Chat_EM_AA1.Id_chat
												AND Chat_EM_AA1.Data_leitura_mensagem IS NULL)), 'Sim') <> ISNULL(Chat_EM.Chat_lido, '') ;

-- Apaga os registros inválidos:
DELETE	FROM [vagas_dw].[VAGAS_DW].[Chat_envio_mensagem]
FROM	[vagas_dw].[VAGAS_DW].[Chat_envio_mensagem]
WHERE	Origem_destino = 'Candidato -> Candidato' ;