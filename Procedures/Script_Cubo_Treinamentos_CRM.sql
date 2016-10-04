# =============================================
# Author:  		Fiama    
# Create date:  2016-09-09
# Description:  Extração dos dados para criação da PROCEDURE OLTP 
# =============================================

USE sugarcrm ;


# Extração dos dados de Treinamentos:
SELECT A.id AS ID_TREINAMENTO ,
	A.name AS NOME_TREINAMENTO ,
    A.date_entered AS DATA_ENTRADA ,
    A.date_modified AS DATA_MODIFICACAO ,
    CONCAT(B.first_name, ' ', B.last_name) AS USUARIO_MODIFICOU ,
    CONCAT(C.first_name, ' ', C.last_name) AS USUARIO_CRIOU ,
    CASE WHEN A.deleted = 1 THEN 'SIM' ELSE 'NÃO' END AS REMOVIDO ,
    CONCAT(D.first_name, ' ', D.last_name) AS PROPRIETARIO ,
    UPPER(A.type) AS CATEGORIA ,
    A.account_id_c AS ID_CONTA_CRM ,
    UPPER(A.modulo) AS MODULO ,
    A.data_realizacao_inicio AS DATA_REALIZACAO_INICIO ,
    A.data_realizacao_fim AS DATA_REALIZACAO_FIM ,
    UPPER(A.FORMATO) AS FORMATO ,
    UPPER(A.local) AS LOCAL ,
    UPPER(A.status) AS STATUS ,
    CONCAT(G.first_name, ' ', G.last_name) AS PRIM_INSTRUTOR ,
    IFNULL(CONCAT(F.first_name, ' ', F.last_name), 'N/C') AS SEG_INSTRUTOR ,
    UPPER(A.custo) AS CUSTO ,
    E.id_vagas_c AS CLIENTE_VAGAS ,
    CASE WHEN LTRIM(RTRIM(A.description)) LIKE '%Ecossistema%' OR LTRIM(RTRIM(A.description)) LIKE '#%' OR A.modulo = 'academia_vagas' THEN 'SIM' ELSE 'NÃO' END AS ACADEMIA_VAGAS ,
    CASE WHEN LTRIM(RTRIM(A.description)) LIKE '%Ecossistema%' AND (LTRIM(RTRIM(A.description)) LIKE '%Ecossistema%' OR LTRIM(RTRIM(A.description)) LIKE '#%' OR A.modulo = 'academia_vagas') THEN 'Ecossistema VAGAS' 
		 WHEN LTRIM(RTRIM(A.description)) LIKE '%Plus%' AND (LTRIM(RTRIM(A.description)) LIKE '%Ecossistema%' OR LTRIM(RTRIM(A.description)) LIKE '#%' OR A.modulo = 'academia_vagas') THEN 'VAGAS e-partner Módulo Plus' 
         WHEN LTRIM(RTRIM(A.description)) LIKE '%Essencial%' AND (LTRIM(RTRIM(A.description)) LIKE '%Essencial%' OR LTRIM(RTRIM(A.description)) LIKE '#%' OR A.modulo = 'academia_vagas') THEN 'VAGAS e-partner Módulo Essencial'  
         WHEN LTRIM(RTRIM(A.description)) LIKE '%cabe_a%' AND (LTRIM(RTRIM(A.description)) LIKE '%cabe_a%' OR LTRIM(RTRIM(A.description)) LIKE '#%' OR A.modulo = 'academia_vagas') THEN 'Caindo de Cabeça nos Relatórios' END AS TIPO_ACADEMIA_VAGAS
FROM sugarcrm.trn_treinamentos AS A		LEFT OUTER JOIN sugarcrm.users AS B ON A.modified_user_id = B.id
										LEFT OUTER JOIN sugarcrm.users AS C ON A.created_by = C.id
                                        LEFT OUTER JOIN sugarcrm.users AS D ON A.assigned_user_id = D.id
                                        LEFT OUTER JOIN sugarcrm.accounts_cstm AS E ON A.account_id_c = E.id_c
                                        LEFT OUTER JOIN sugarcrm.users AS F ON A.user_id1_c = F.id
                                        LEFT OUTER JOIN sugarcrm.users AS G ON A.user_id_c = G.id      ;


SHOW FULL COLUMNS FROM sugarcrm.trn_treinamentos ;

#TIPO TREINAMENTO: ONLINE, CLIENTE, VAGAS
#Quando um treinamento é do tipo "Academia VAGAS", é inserido um #NOME_TREINAMENTO no campo descrição
#8 tipos de cursos para clientes externos, e para cliente interno N cursos
# Categoria : Coletivo varias empresas juntas, ou Exclusivo apenas uma empresa com 1 ou mais colaboradores (mesma conta)
# Status mais utilizados: confirmado, agendado, realizado, cancelado
# Formato: apresentação, prático, vídeo aula (pode apenas asstir sem tirar dúvidas)
# custo: não é utilizado hoje
# proprietário: quem criou o treinamento
# realização: início (inserção manual)
# realização: fim (inserção manual)
# os treinamentos sao atrelados as contas dos clientes

# participantes tem status: participou, faltou, etc...
# participante é atrelado a trn

#relatórios: qtd pessoas que participaram, treinamentos cancelados, realizados
#relatórios: qtd treinamentos de treinamento do módulo essencial, do módulo tira dúvida
#relatórios sobre os participantes: qts vezes o participante agendou o treinamento e não veio
#

