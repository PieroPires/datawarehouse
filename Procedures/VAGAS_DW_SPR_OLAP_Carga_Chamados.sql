-- EXEC VAGAS_DW.SPR_OLAP_Carga_Chamados
USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Chamados' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Chamados
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Chamados

AS
SET NOCOUNT ON

-- LIMPAR DA TABELA FATO ATUAL OS DADOS NOVOS/ALTERADOS QUE SERÃO CARREGADOS
DELETE VAGAS_DW.CHAMADOS 
FROM VAGAS_DW.CHAMADOS A
WHERE EXISTS ( SELECT 1 FROM VAGAS_DW.TMP_CHAMADOS 
				WHERE ID_TICKET = A.ID_TICKET )
				
-- CARREGAR CUBO
INSERT INTO VAGAS_DW.CHAMADOS (ID_TICKET,TICKET_NUMBER,FILA,BLOQUEIO_SOURCE,BLOQUEIO,TIPO_SOURCE,TIPO,LOGIN,ASSUNTO,PROPRIETARIO,ESTADO_SOURCE,ESTADO,
DATA_CRIACAO_SOURCE,DATA_CRIACAO,DATA_ALTERACAO_SOURCE,DATA_ALTERACAO,CLIENTE)
SELECT ID_TICKET,
	   TICKET_NUMBER,
	   FILA,
	   BLOQUEIO_SOURCE,
	   CASE WHEN BLOQUEIO_SOURCE = 'lock' THEN 'bloqueado' ELSE 'Desbloqueado' END AS BLOQUEIO,
	   TIPO_SOURCE,
	   TIPO_SOURCE AS TIPO,
	   LOGIN,
	   ASSUNTO,
	   PROPRIETARIO,
	   ESTADO_SOURCE,
	   CASE WHEN ESTADO_SOURCE = 'closed successful' THEN 'Fechado com sucesso'
			WHEN ESTADO_SOURCE = 'closed unsuccessful' THEN 'Fechado sem resolução'
			WHEN ESTADO_SOURCE = 'new' THEN 'Novo'
			WHEN ESTADO_SOURCE = 'open' THEN 'Aberto'
		    ELSE ESTADO_SOURCE END AS ESTADO,
	   DATA_CRIACAO_SOURCE,
	   CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATA_CRIACAO_SOURCE,112)) AS DATA_CRIACAO,
	   DATA_ALTERACAO_SOURCE,
	   CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATA_ALTERACAO_SOURCE,112)) AS DATA_ALTERACAO,
	   ISNULL(CLIENTE,'Não Classificado') AS CLIENTE
FROM VAGAS_DW.TMP_CHAMADOS

-- ATUALIZAR CHAMADOS "ABERTO", "EM ANDAMENTO, "NOVO" 
UPDATE VAGAS_DW.CHAMADOS SET DIAS_ABERTO = DATEDIFF(DAY,DATA_CRIACAO_SOURCE,GETDATE())
FROM VAGAS_DW.CHAMADOS 
WHERE ESTADO IN ('Aberto','Em andamento','Novo')
AND FILA NOT IN ('Junk','Anti-Spam','Não Responda')

-- ATUALIZAR CUBO "CHAMADOS" COM TMA (O pacote "Carga_Chamados_Historico" deve ter sido executado anteriormente)
-- BRAZ - 20160801 : Fizemos a adição do TMR_H e um CASE temporário (até FEV/2017) por conta do horário de trabalha da Caroline
-- Se caso identificarmos que esta situação pode ser definitiva poderemos criar uma nova tabela para este tipo de controle
-- por enquanto não achamos necessário
-- * O Campo TMA (Tempo Médio de Atendimento) "conceitualmente" foi renomeado 
-- para TMR (Tempo Médio de Resposta) (por conta do impacto da alteração fizemos apenas um ALIAS no Analysis Services)
UPDATE VAGAS_DW.CHAMADOS SET TMA = B.TMA,QTD_REABERTURA = B.QTD_REABERTURA,
							 TME = B.TME
FROM VAGAS_DW.CHAMADOS A
INNER JOIN VAGAS_DW.CHAMADOS_TMA B ON B.ID_TICKET = A.ID_TICKET

