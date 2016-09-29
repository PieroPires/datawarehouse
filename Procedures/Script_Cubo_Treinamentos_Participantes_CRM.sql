# =============================================
# Author:  		Fiama    
# Create date:  2016-09-29
# Description:  Extração dos dados para criação do CUBO TREINAMENTOS_PARTICIPANTES_CRM
# =============================================

USE sugarcrm ;

SHOW FULL TABLES FROM sugarcrm LIKE 'trn%' ;

# Tabelas com informações de participantes:

# trn_config
# trn_config_audit
# trn_participantes
# trn_participantes_audit
# trn_treinamentos
# trn_treinamentos_accounts_c
# trn_treinamentos_audit
# trn_treinamentos_trn_participantes_c


# trn_participantes:
SELECT * FROM sugarcrm.trn_participantes ;

SHOW FULL COLUMNS FROM sugarcrm.trn_participantes ;
# id --> PK da tabela
# name --> Identificação do PARTICIPANTE
# date_entered --> Data da criação
# date_modified --> Data de modificação
# modified_user_id --> Usuário que modificou
# created_by --> Usuário que criou o participante (Criado por)
# description --> Descrição
# assigned_user_id --> 
# status --> status do participante em relação ao treinamento
# contact_id_c --> Contato do cliente que participou do treinamento
# trn_treinamentos_id_c --> ID do treinamento atrelado ao participante
# account_id_c --> Conta do cliente atrelado ao participante

SELECT A.name AS ID_PARTICIPANTE ,
	A.date_entered AS DATA_CRIACAO ,
    A.date_modified AS DATA_MODIFICACAO  ,
	CONCAT(C.first_name, ' ', C.last_name) AS USUARIO_CRIOU ,
    CONCAT(B.first_name ,' ', B.last_name) AS USUARIO_MODIFICOU ,
    A.description AS DESCRICAO ,
    UPPER(A.status) AS STATUS_PARTICIPANTE ,
    CONCAT(D.first_name, ' ', D.last_name) AS CONTATO ,
    F.name AS NOME_TREINAMENTO, 
    G.name AS CONTA
FROM sugarcrm.trn_participantes AS A	LEFT OUTER JOIN sugarcrm.users AS B ON A.modified_user_id = B.id
										LEFT OUTER JOIN sugarcrm.users AS C ON A.created_by = C.id
                                        LEFT OUTER JOIN sugarcrm.contacts AS D ON A.contact_id_c = D.id
                                        LEFT OUTER JOIN sugarcrm.trn_treinamentos_trn_participantes_c AS E ON A.id = E.trn_treinamentos_trn_participantestrn_participantes_idb
                                        LEFT OUTER JOIN sugarcrm.trn_treinamentos AS F ON E.trn_treinamentos_trn_participantestrn_treinamentos_ida = F.id
                                        LEFT OUTER JOIN sugarcrm.accounts AS G ON A.account_id_c = G.id   
                                        
                                        