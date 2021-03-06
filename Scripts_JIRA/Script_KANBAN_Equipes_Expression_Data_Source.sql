"SELECT A.ID AS ID_DEMANDA,
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
       A.DUEDATE AS DATA_EXPECTATIVA_CONCLUSAO,
       A.RESOLUTIONDATE AS DATA_CONCLUSAO,
       CONVERT(F.PNAME USING Latin1) AS STATUS_RESOLUCAO,
       ((A.TIMEORIGINALESTIMATE / 60 ) / 60 ) AS TEMPO_ESTIMATIVA,
       ((A.TIMESPENT / 60 ) / 60 ) AS TEMPO_GASTO,
       CASE WHEN INSTR(A.SUMMARY,\"#Marco\") OR INSTR(I.SUMMARY,\"#Marco\") THEN 1 ELSE 0 END AS FLAG_ATRELADO_MARCO,       
       IFNULL(CONVERT(I.SUMMARY USING Latin1),CONVERT(A.SUMMARY USING Latin1)) AS NOME_DEMANDA_ROOT,
       
       CASE WHEN CONVERT(I.SUMMARY USING Latin1) IS NOT NULL THEN 0 ELSE 1 END  AS FLAG_ROOT,              
       IFNULL(CONVERT(H.vname USING Latin1),\"Sem Release\") AS NOME_RELEASE,
       CONVERT(CONVERT(IFNULL(J.TEXTVALUE,J1.TEXTVALUE),CHAR(100)) USING Latin1) AS EQUIPE_SOLICITANTE,
       CASE WHEN L.ID IS NOT NULL THEN CONVERT(L1.CUSTOMVALUE USING Latin1) 
                  WHEN M.ID IS NOT NULL THEN CONVERT(M1.CUSTOMVALUE USING Latin1) 
            WHEN N.ID IS NOT NULL THEN CONVERT(N1.CUSTOMVALUE USING Latin1) 
            WHEN O.ID IS NOT NULL THEN CONVERT(O1.CUSTOMVALUE USING Latin1)
       ELSE \"\" END AS TIPO_SUB_TAREFA
,CONVERT(SUBSTRING(H.vname,INSTR(UPPER(H.vname),\"#CICLO\"),7) USING Latin1) AS CICLO, 
CONVERT(R1.CUSTOMVALUE USING Latin1)   AS GRAVIDADE,
       CONVERT(Q1.CUSTOMVALUE USING Latin1)     AS URGENCIA,
       CONVERT(P1.CUSTOMVALUE USING Latin1)     AS ESFORCO,
       NULL     AS TIPO_CLIENTE,
       NULL     AS FATURAVEL,
       CONVERT(\"Intelig?ncia de Neg?cios\" USING Latin1) AS EQUIPE_PROJETO,
       NULL AS DATA_PRM_ASSIGNED,
       NULL AS FERRAMENTA,
       NULL AS SINTOMA,
       NULL AS STORY_POINTS
FROM jiraissue A
INNER JOIN project B ON B.ID = A.PROJECT
INNER JOIN issuetype C ON C.ID = A.issuetype
INNER JOIN issuestatus D ON D.ID = A.issuestatus
LEFT OUTER JOIN issuelink E ON E.DESTINATION = A.ID
LEFT OUTER JOIN resolution F ON F.ID = A.RESOLUTION
LEFT OUTER JOIN nodeassociation G ON G.SOURCE_NODE_ID = A.ID
LEFT OUTER JOIN projectversion H ON H.ID = G.SINK_NODE_ID AND H.PROJECT = 11500 # POR ENQUANTO ESTAMOS CONSIDERANDO APENAS IN
LEFT OUTER JOIN jiraissue I ON I.ID = E.SOURCE
LEFT OUTER JOIN customfieldvalue J ON J.ISSUE = A.ID AND J.CUSTOMFIELD = 12905 # Equipe Solicitante
LEFT OUTER JOIN customfieldvalue J1 ON J1.ISSUE = I.ID AND J1.CUSTOMFIELD = 12905 # Equipe Solicitante (tarefa filho)
LEFT OUTER JOIN customfieldvalue L ON L.ISSUE = A.ID AND A.issuetype = 11308 AND L.CUSTOMFIELD = 12901 # Pesquisa
LEFT OUTER JOIN customfieldoption L1 ON L1.CUSTOMFIELD = L.CUSTOMFIELD AND L1.ID = L.STRINGVALUE
LEFT OUTER JOIN customfieldvalue M ON M.ISSUE = A.ID AND A.issuetype = 12208 AND M.CUSTOMFIELD = 12902 # Relat?rio
LEFT OUTER JOIN customfieldoption M1 ON M1.CUSTOMFIELD = M.CUSTOMFIELD AND M1.ID = M.STRINGVALUE
LEFT OUTER JOIN customfieldvalue N ON N.ISSUE = A.ID AND A.issuetype = 12209 AND N.CUSTOMFIELD = 12903 # Pedido Pontual
LEFT OUTER JOIN customfieldoption N1 ON N1.CUSTOMFIELD = N.CUSTOMFIELD AND N1.ID = N.STRINGVALUE
LEFT OUTER JOIN customfieldvalue O ON O.ISSUE = A.ID AND A.issuetype = 12210 AND O.CUSTOMFIELD = 12904 # Atividades Internas
LEFT OUTER JOIN customfieldoption O1 ON O1.CUSTOMFIELD = O.CUSTOMFIELD AND O1.ID = O.STRINGVALUE
 LEFT OUTER JOIN customfieldvalue P ON P.ISSUE = A.ID AND P.CUSTOMFIELD = 13000 # ESFOR?O
LEFT OUTER JOIN customfieldoption P1 ON P1.CUSTOMFIELD = P.CUSTOMFIELD AND P1.ID = P.STRINGVALUE
LEFT OUTER JOIN customfieldvalue Q ON Q.ISSUE = A.ID AND Q.CUSTOMFIELD = 13001 # URG?NCIA
LEFT OUTER JOIN customfieldoption Q1 ON Q1.CUSTOMFIELD = Q.CUSTOMFIELD AND Q1.ID = Q.STRINGVALUE
LEFT OUTER JOIN customfieldvalue R ON R.ISSUE = A.ID AND R.CUSTOMFIELD = 13002 # GRAVIDADE
LEFT OUTER JOIN customfieldoption R1 ON R1.CUSTOMFIELD = R.CUSTOMFIELD AND R1.ID = R.STRINGVALUE WHERE A.PROJECT = 11500 # POR ENQUANTO ESTAMOS CONSIDERANDO APENAS IN
AND A.CREATED >= \"20160609\"  AND A.UPDATED >= "   +  @[User::DATA_ALTERACAO] +
" UNION ALL 

SELECT A.ID AS ID_DEMANDA,
       A.issuenum AS NUMERO_DEMANDA,
       CONVERT(A.SUMMARY USING Latin1) AS NOME_DEMANDA,
       CONVERT(B.PNAME USING Latin1) AS NOME_PROJETO,
       IFNULL(CONVERT(J.RESPONSAVEL USING Latin1),CONVERT(A.ASSIGNEE USING Latin1)) AS RESPONSAVEL,
       CONVERT(A.CREATOR USING Latin1) AS CRIADOR,
       CONVERT(C.PNAME USING Latin1) AS TIPO_DEMANDA,
       CONVERT(A.PRIORITY USING Latin1) AS PRIORIDADE,
       CONVERT(D.PNAME USING Latin1) AS STATUS_DEMANDA,
       A.CREATED AS DATA_CADASTRAMENTO,
       A.UPDATED AS DATA_ALTERACAO,
       A.DUEDATE AS DATA_EXPECTATIVA_CONCLUSAO,
       A.RESOLUTIONDATE AS DATA_CONCLUSAO,
       CONVERT(F.PNAME USING Latin1) AS STATUS_RESOLUCAO,
       ((A.TIMEORIGINALESTIMATE / 60 ) / 60 ) AS TEMPO_ESTIMATIVA,
       ((A.TIMESPENT / 60 ) / 60 ) AS TEMPO_GASTO,
       NULL AS FLAG_ATRELADO_MARCO,
       IFNULL(CONVERT(M.SUMMARY USING Latin1),CONVERT(A.SUMMARY USING Latin1)) AS NOME_DEMANDA_ROOT,
       CASE WHEN CONVERT(M.SUMMARY USING Latin1) IS NOT NULL THEN 0 ELSE 1 END AS FLAG_ROOT,              
       NULL AS NOME_RELEASE,
       NULL AS EQUIPE_SOLICITANTE,
       CASE WHEN I.ISSUE IS NOT NULL THEN CONVERT(CAST(I.TIPO AS CHAR(250)) USING Latin1) ELSE \"Outros\" END AS TIPO_SUB_TAREFA,
       NULL AS CICLO,
       NULL AS GRAVIDADE,
       NULL AS URGENCIA,
       NULL AS ESFORCO,
       CONVERT(G1.CUSTOMVALUE USING Latin1)     AS TIPO_CLIENTE,
       CONVERT(H1.CUSTOMVALUE USING Latin1)     AS FATURAVEL,
       CONVERT(\"DSM\" USING Latin1) AS EQUIPE_PROJETO,
       NULL AS DATA_PRM_ASSIGNED,
       NULL AS FERRAMENTA,
       NULL AS SINTOMA,
       NULL AS STORY_POINTS
FROM jiraissue A
INNER JOIN project B ON B.ID = A.PROJECT
INNER JOIN issuetype C ON C.ID = A.issuetype
INNER JOIN issuestatus D ON D.ID = A.issuestatus
LEFT OUTER JOIN resolution F ON F.ID = A.RESOLUTION
INNER JOIN customfieldvalue G ON G.ISSUE = A.ID AND G.CUSTOMFIELD = 11406 # Tipo Cliente
INNER JOIN customfieldoption G1 ON G1.CUSTOMFIELD = G.CUSTOMFIELD AND G1.ID = G.STRINGVALUE
LEFT OUTER JOIN customfieldvalue H ON H.ISSUE = A.ID AND H.CUSTOMFIELD = 12700 # Fatur?vel ?
LEFT OUTER JOIN customfieldoption H1 ON H1.CUSTOMFIELD = H.CUSTOMFIELD AND H1.ID = H.STRINGVALUE
LEFT OUTER JOIN ( SELECT ISSUE,GROUP_CONCAT(CONVERT(A2.CUSTOMVALUE USING Latin1) SEPARATOR \" - \") AS TIPO
                          FROM customfieldvalue A1
                          INNER JOIN customfieldoption A2 ON A2.CUSTOMFIELD = A1.CUSTOMFIELD
                                                                          AND A2.ID = A1.STRINGVALUE
                          WHERE A1.CUSTOMFIELD IN (11513,11905)
                 GROUP BY A1.ISSUE) I ON I.ISSUE = A.ID # Tipo de funcionalidade
LEFT OUTER JOIN ( SELECT A.issueid AS ISSUE,
                                   A.AUTHOR AS RESPONSAVEL
                           FROM changegroup A
                           INNER JOIN changeitem B ON B.groupid = A.ID
                           WHERE B.NEWSTRING IN (\"Em Desenvolvimento\", \"Impedida\", \"Homologar\", \"In Progress\",  \"Closed\")
                   AND A.CREATED = ( SELECT MAX(CREATED) 
                                                      FROM changegroup A1
                                                      INNER JOIN changeitem B1 ON B1.groupid = A1.ID
                                                      WHERE A1.issueid = A.issueid
                                                      AND B1.NEWSTRING IN (\"Em Desenvolvimento\", \"Impedida\", \"Homologar\", \"In Progress\",  \"Closed\")  )
                        ) J ON J.ISSUE = A.ID
LEFT OUTER JOIN issuelink L ON L.DESTINATION = A.ID
LEFT OUTER JOIN jiraissue M ON M.ID = L.SOURCE   
WHERE A.PROJECT = 11101 # PROJETO Solu??es & DSM
AND A.CREATED >= \"20160101\"  AND A.UPDATED >= "   +  @[User::DATA_ALTERACAO] +
" UNION ALL 


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
       A.DUEDATE AS DATA_EXPECTATIVA_CONCLUSAO,
       A.RESOLUTIONDATE AS DATA_CONCLUSAO,
       CONVERT(F.PNAME USING Latin1) AS STATUS_RESOLUCAO,
       ((A.TIMEORIGINALESTIMATE / 60 ) / 60 ) AS TEMPO_ESTIMATIVA,
       ((A.TIMESPENT / 60 ) / 60 ) AS TEMPO_GASTO,
       CASE WHEN INSTR(A.SUMMARY,\"#Marco\") THEN 1 ELSE 0 END AS FLAG_ATRELADO_MARCO,       
       NULL AS NOME_DEMANDA_ROOT,       
       NULL AS FLAG_ROOT,              
       NULL AS NOME_RELEASE,
       CONVERT(CONVERT(J.TEXTVALUE,CHAR(100)) USING Latin1) AS EQUIPE_SOLICITANTE,
       NULL AS TIPO_SUB_TAREFA,
       NULL AS CICLO,
       NULL AS GRAVIDADE,
       NULL AS URGENCIA,
       NULL AS ESFORCO,
       NULL AS TIPO_CLIENTE,
       NULL AS FATURAVEL,
       CONVERT(\"Sistemas Corporativos\" USING Latin1) AS EQUIPE_PROJETO,
       ( SELECT MIN(A1.CREATED) 
             FROM changegroup A1
             INNER JOIN changeitem B1 ON B1.groupid = A1.ID
             WHERE A1.issueid = A.ID AND B1.FIELD = \"assignee\" ) AS DATA_PRM_ASSIGNED,
       CONVERT(L1.CUSTOMVALUE USING Latin1)     AS FERRAMENTA,
       CONVERT(M1.CUSTOMVALUE USING Latin1)     AS SINTOMA,
       N.NUMBERVALUE AS STORY_POINTS
FROM jiraissue A
INNER JOIN project B ON B.ID = A.PROJECT
INNER JOIN issuetype C ON C.ID = A.issuetype
INNER JOIN issuestatus D ON D.ID = A.issuestatus
LEFT OUTER JOIN resolution F ON F.ID = A.RESOLUTION
LEFT OUTER JOIN nodeassociation G ON G.SOURCE_NODE_ID = A.ID
LEFT OUTER JOIN projectversion H ON H.ID = G.SINK_NODE_ID AND H.PROJECT = A.PROJECT 
LEFT OUTER JOIN customfieldvalue J ON J.ISSUE = A.ID AND J.CUSTOMFIELD = 12905 # Equipe Solicitante
LEFT OUTER JOIN customfieldvalue L ON L.ISSUE = A.ID AND L.CUSTOMFIELD = 10301 AND L.PARENTKEY IS NULL # Ferramenta
LEFT OUTER JOIN customfieldoption L1 ON L1.CUSTOMFIELD = L.CUSTOMFIELD AND L1.ID = L.STRINGVALUE
LEFT OUTER JOIN customfieldvalue M ON M.ISSUE = A.ID AND M.CUSTOMFIELD = 13101 AND M.PARENTKEY IS NULL # Sintoma
LEFT OUTER JOIN customfieldoption M1 ON M1.CUSTOMFIELD = M.CUSTOMFIELD AND M1.ID = M.STRINGVALUE
LEFT OUTER JOIN customfieldvalue N ON N.ISSUE = A.ID AND N.CUSTOMFIELD = 10002 # STORY POINTS
WHERE A.PROJECT IN (12800,12700,11903,11700,11604,12400,13000,13201) # (PROJETOS SIST. CORPORATIVOS)
AND  (   NOT EXISTS ( SELECT * FROM issuelink WHERE DESTINATION = A.ID AND LINKTYPE <> 10200 )
        OR EXISTS ( SELECT * FROM issuelink WHERE SOURCE = A.ID AND LINKTYPE <> 10200 ) ) # N?O SEJA UMA SUB TAREFA
AND A.UPDATED >= "   +  @[User::DATA_ALTERACAO]