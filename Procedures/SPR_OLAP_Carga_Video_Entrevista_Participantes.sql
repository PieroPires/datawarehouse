USE VAGAS_DW ;

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' AND NAME = 'SPR_OLAP_CARGA_VIDEO_ENTREVISTA_PARTICIPANTES')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_CARGA_VIDEO_ENTREVISTA_PARTICIPANTES
GO

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_CARGA_VIDEO_ENTREVISTA_PARTICIPANTES
AS
SET NOCOUNT ON

-- LIMPA OS REGISTROS EXISTENTES NA TABELA OLAP QUE EXISTEM NA TABELA OLTP:
DELETE	VAGAS_DW.VIDEO_ENTREVISTAS_PARTICIPANTES
FROM	VAGAS_DW.VIDEO_ENTREVISTAS_PARTICIPANTES AS VD
WHERE	EXISTS (SELECT *
				FROM	STAGE.VAGAS_DW.TMP_VIDEO_ENTREVISTAS_PARTICIPANTES AS TP1
				WHERE	VD.IDPARTICIPANTE = TP1.IDPARTICIPANTE) ;

INSERT INTO VAGAS_DW.VIDEO_ENTREVISTAS_PARTICIPANTES
SELECT	 TP.IDPARTICIPANTE
		,TP.IDVIDEOENTREVISTA
		,TP.IDVAGA
		,TP.IDCAND
		,TP.DATA_PARTICIPANTE
		,TP.FLAGATIVO
		,TP.FLAGESTORNADO
		,TP.IDPERGUNTA
		,TP.DESCRICAOPERGUNTA
		,TP.TIPOPERGUNTA
		,TP.TEMPORESPOSTA
FROM	STAGE.VAGAS_DW.TMP_VIDEO_ENTREVISTAS_PARTICIPANTES AS TP
WHERE	NOT EXISTS (SELECT *
					FROM	VAGAS_DW.VIDEO_ENTREVISTAS_PARTICIPANTES AS TP1
					WHERE	TP.IDPARTICIPANTE = TP1.IDPARTICIPANTE) ;