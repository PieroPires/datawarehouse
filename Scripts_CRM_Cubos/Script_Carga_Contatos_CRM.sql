-- ============================================= 
-- Author: Fiama 
-- Create date: 2016-12-08 
-- Description: Query para extração dos dados do CUBO de CONTATOS do sugarcrm. 
-- ============================================= 
 
USE sugarcrm ; 
 
-- Query: 
SELECT  COD_CONTATO , 
		CONVERT(NOME USING latin1) AS NOME , 
		CONVERT(SOBRENOME USING latin1) AS SOBRENOME , 
        DATA_INCLUSAO , 
		DATA_MODIFICACAO , 
        CONVERT(CARGO USING latin1) AS CARGO , 
        CONVERT(DEPARTAMENTO USING latin1) AS DEPARTAMENTO , 
        CONVERT(TELEFONE_CELULAR USING latin1) AS TELEFONE_CELULAR , 
        CONVERT(TELEFONE_CONTATO USING latin1) AS TELEFONE_CONTATO , 
        CONVERT(TELEFONE_OUTRO USING latin1) AS TELEFONE_OUTRO , 
		CONVERT(RUA USING latin1) AS RUA,        
        CONVERT(CIDADE USING latin1) AS CIDADE , 
        CONVERT(ESTADO USING latin1) AS ESTADO , 
        CONVERT(PAÍS USING latin1) AS PAÍS  , 
        CONVERT(EMAIL USING latin1) AS EMAIL , 
        CONVERT(CLIENTE_VAGAS USING latin1) AS CLIENTE_VAGAS , 
        CONVERT(CONTA_CRM USING latin1) AS CONTA_CRM , 
        CONVERT(COD_CONTA_CRM USING latin1) AS COD_CONTA_CRM ,
		ADMIN ,
        CONTATO_PRINCIPAL
FROM  ( 
  SELECT	A.id AS COD_CONTATO , 
			A.first_name AS NOME , 
            LTRIM(RTRIM(REVERSE(SUBSTRING(LTRIM(RTRIM(REVERSE(A.last_name))), 1, LOCATE(' ', CONCAT(LTRIM(RTRIM(REVERSE(A.last_name))), ' ')))))) AS SOBRENOME ,
			CAST(A.date_entered AS DATE) AS DATA_INCLUSAO , 
			CAST(A.date_modified AS DATE) AS DATA_MODIFICACAO , 
            A.title AS CARGO , 
            A.department AS DEPARTAMENTO , 
            A.phone_mobile AS TELEFONE_CELULAR , 
            A.phone_work AS TELEFONE_CONTATO , 
            A.phone_other AS TELEFONE_OUTRO , 
            A.primary_address_street AS RUA , 
            A.primary_address_city AS CIDADE , 
            A.primary_address_state AS ESTADO , 
            A.primary_address_country AS PAÍS  , 
            F.email_address AS EMAIL , 
            G.id_vagas_c AS CLIENTE_VAGAS , 
			D.name AS CONTA_CRM , 
            D.id AS COD_CONTA_CRM ,
			B.usuario_admin_c AS ADMIN,
            B.contato_principal_c AS CONTATO_PRINCIPAL
    FROM	sugarcrm.contacts AS A	INNER JOIN sugarcrm.contacts_cstm AS B ON A.id = B.id_c 
									INNER JOIN sugarcrm.accounts_contacts AS C ON A.id = C.contact_id AND C.deleted = 0 
									INNER JOIN sugarcrm.accounts AS D ON C.account_id = D.id AND D.deleted = 0 
									LEFT OUTER JOIN sugarcrm.email_addr_bean_rel AS E ON A.id = E.bean_id AND E.deleted = 0 AND E.primary_address = '1' AND E.bean_module = 'Contacts'  
									LEFT OUTER JOIN sugarcrm.email_addresses AS F ON F.id = E.email_address_id AND F.deleted = 0  
									INNER JOIN sugarcrm.accounts_cstm AS G ON D.id = G.id_c 
    WHERE  A.deleted = 0  -- Contato não foi removido 
    ) AS CONTATOS_CRM  ;
         
         
        
# Campos do CUBO CONTATOS_CRM: 
 
# [NOME DO CAMPO TARGET] -->    [NOME TABELA SOURCE]  -->    [NOME CAMPO SOURCE]   -->   [TIPO DE DADOS SOURCE] 
#  COD_CONTATO       -->    sugarcrm.contacts    -->    id            -->   char(36) NOT NULL 
#  NOME           -->    sugarcrm.contacts    -->    first_name        -->   varchar(100) NULL 
#  SOBRENOME       -->    sugarcrm.contacts    -->    last_name        -->   varchar(100) NULL 
#  DATA_INCLUSAO     -->    sugarcrm.contacts    -->    date_entered      -->    date NULL 
#  DATA_MODIFICACAO     -->    sugarcrm.contacts    -->    date_modified      -->    date NULL 
#  CARGO         -->    sugarcrm.contacts    -->    title          -->    varchar(100) NULL 
#  DEPARTAMENTO       -->    sugarcrm.contacts    -->    departament        -->    varchar(255) NULL 
#  TELEFONE_CELULAR     -->    sugarcrm.contacts    -->    phone_mobile      -->    varchar(100) NULL 
#  TELEFONE_CONTATO     -->    sugarcrm.contacts    -->    phone_work        -->    varchar(100) NULL 
#  TELEFONE_OUTRO     -->    sugarcrm.contacts    -->    phone_other        -->    varchar(100) NULL 
#  RUA           -->    sugarcrm.contacts    -->    primary_address_street  -->    varchar(150) NULL   
#  CIDADE         -->    sugarcrm.contacts    -->    primary_address_city  -->   varchar(100) NULL 
#  ESTADO          -->    sugarcrm.contacts    -->    primary_address_state  -->    varchar(100) NULL 
#  PAÍS           -->    sugarcrm.contacts    -->    primary_address_country  -->    varchar(255) NULL 
#  EMAIL         -->    sugarcrm.contacts    -->    email_address      -->    varchar(255) NULL 
#  CLIENTE_VAGAS     -->    [hrh-data]..[Clientes]  -->    Ident_cli        -->   varchar(20) NULL 
#  CONTA_CRM       -->    sugarcrm.accounts    -->    name          -->    varchar(150) NULL 
#  COD_CONTA_CRM     -->    sugarcrm.accounts    -->    id            -->    char(36) NOT NULL 