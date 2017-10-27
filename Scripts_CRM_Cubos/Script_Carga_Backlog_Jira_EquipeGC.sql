USE jiradb ;

-- ============================================= 
-- Author: Fiama 
-- Create date: 05/10/2017 
-- Description: Carga Backlog Jira Equipe Gestão de Contratos 
-- ============================================= 
 
USE jiradb ; 
 
SELECT A.ID AS ID_DEMANDA, 
       A.issuenum AS NUMERO_DEMANDA, 
       CONVERT(A.SUMMARY USING Latin1) AS NOME_DEMANDA, 
       CONVERT(B.PNAME USING Latin1) AS NOME_PROJETO, 
       CONVERT(A.ASSIGNEE USING Latin1) AS RESPONSAVEL, 
       CONVERT(A.CREATOR USING Latin1) AS CRIADOR, 
       CONVERT(C.PNAME USING Latin1) AS TIPO_DEMANDA, 
       CONVERT(A.PRIORITY USING Latin1) AS PRIORIDADE, 
       CONVERT(D.PNAME USING Latin1) AS STATUS_DEMANDA, 
       A.CREATED AS DATA_CADASTRAMENTO, 
       A.UPDATED AS DATA_ALTERACAO, 
       IFNULL(CONVERT(I.SUMMARY USING Latin1),CONVERT(A.SUMMARY USING Latin1)) AS NOME_DEMANDA_ROOT, 
       CASE WHEN CONVERT(I.SUMMARY USING Latin1) IS NOT NULL THEN 0 ELSE 1 END  AS FLAG_ROOT, 
       CONVERT(CONVERT(IFNULL(J.TEXTVALUE,J1.TEXTVALUE),CHAR(100)) USING Latin1) AS EQUIPE_SOLICITANTE, 
       CONVERT("Gestão de Contratos" USING Latin1) AS EQUIPE_PROJETO, 
       (SELECT  CONVERT(A2.customvalue USING Latin1) AS CONTEXTO 
         FROM  jiradb.customfieldvalue AS A1  LEFT OUTER JOIN jiradb.customfieldoption AS A2 ON A1.CUSTOMFIELD = A2.CUSTOMFIELD AND A2.ID = A1.STRINGVALUE 
         WHERE  A1.ISSUE = A.ID 
        AND A1.CUSTOMFIELD = 13601) AS FILA , #CONTEXTO          
       (SELECT  CONVERT(A1.STRINGVALUE USING Latin1) AS SOLICITANTE 
        FROM  jiradb.customfieldvalue AS A1 
        WHERE  A1.ISSUE = A.ID  
        AND A1.CUSTOMFIELD = 13300) AS SOLICITANTE , 
       (SELECT  CONVERT(IFNULL(A1.STRINGVALUE, A1.TEXTVALUE) USING Latin1) AS CLIENTE 
        FROM  jiradb.customfieldvalue AS A1   
        WHERE  A1.ISSUE = A.ID  
        AND A1.CUSTOMFIELD = 12800) AS CLIENTE , 
#    (SELECT  CONVERT(A1.STRINGVALUE USING Latin1) AS FORNECEDOR_OUTROS 
#     FROM    jiradb.customfieldvalue AS A1 
#     WHERE  A1.ISSUE = A.ID  
#      AND A1.CUSTOMFIELD = 13800) AS TIPO_CLIENTE , #FONECEDOR/OUTROS          
#    (SELECT  A1.STRINGVALUE AS OPORTUNIDADE 
#        FROM  jiradb.customfieldvalue AS A1 
#        WHERE  A1.ISSUE = A.ID  
#        AND A1.CUSTOMFIELD = 13605) AS OPORTUNIDADE , 
    (SELECT  CONVERT(A2.customvalue USING Latin1) AS TIPO_ANALISE 
       FROM    jiradb.customfieldvalue AS A1  LEFT OUTER JOIN jiradb.customfieldoption AS A2 ON A1.CUSTOMFIELD = A2.CUSTOMFIELD AND A2.ID = A1.STRINGVALUE  
       WHERE  A1.ISSUE = A.ID 
        AND A1.CUSTOMFIELD = 13603) AS TIPO_ANALISE 
FROM jiradb.jiraissue A 
INNER JOIN jiradb.project B ON B.ID = A.PROJECT 
INNER JOIN jiradb.issuetype C ON C.ID = A.issuetype 
INNER JOIN jiradb.issuestatus D ON D.ID = A.issuestatus 
LEFT OUTER JOIN jiradb.issuelink E ON E.DESTINATION = A.ID 
LEFT OUTER JOIN jiradb.resolution F ON F.ID = A.RESOLUTION 
LEFT OUTER JOIN jiradb.nodeassociation G ON G.SOURCE_NODE_ID = A.ID 
LEFT OUTER JOIN jiradb.jiraissue I ON I.ID = E.SOURCE 
LEFT OUTER JOIN jiradb.customfieldvalue J ON J.ISSUE = A.ID AND J.CUSTOMFIELD = 12905 # Equipe Solicitante 
LEFT OUTER JOIN jiradb.customfieldvalue J1 ON J1.ISSUE = I.ID AND J1.CUSTOMFIELD = 12905 # Equipe Solicitante (tarefa filho) 
WHERE  A.PROJECT = 14200 ;