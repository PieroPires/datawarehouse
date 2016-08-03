# Remove all objects
rm(list=ls())

library(rjson)
library(RCurl)
library(httr)
library(XML)
library(RODBC)

# open connection
cn <- odbcDriverConnect(connection = "Driver={SQL Server Native Client 11.0};server=SRV-SQLMIRROR02;database=VAGAS_DW;trusted_connection=yes;",interpretDot = FALSE)

command <- paste("SELECT ID_EMPRESA_CRM AS id_empresa,",
                 " REPLACE(CONTA ,' ','%20') AS nome_empresa",
                 " FROM VAGAS_DW.TMP_ENRIQUECIMENTO_CONTAS_CRM ",
                 " WHERE (FLAG_PROCESSADO IS NULL ",
                 " OR FLAG_PROCESSADO = 0) ORDER BY ID_EMPRESA_CRM ASC",sep = "")

#print(command)
top_empresas <- sqlQuery(cn,command)

# How many companies will be treat
count_empresas = length(top_empresas$nome_empresa)

# Clear variables
empresa = ""
error = FALSE

# Set URL to Google Web Search API
url <- "http://ajax.googleapis.com/ajax/services/search/"

# Clear Log TABLE
sqlClear(cn,"TMP_LOG_ENRIQUECIMENTO_EMPRESAS") # First clear the log data

  for(emp in 1:count_empresas) 
  {
    
    
    empresa <- top_empresas$nome_empresa[emp]
    id_empresa <- top_empresas$id_empresa[emp]
    empresa <- iconv(empresa, to='ASCII//TRANSLIT')
    
    # Begin of linkedin process
    
    #print(empresa)
    
#     keyword <- paste(empresa,"+linkedin+company+brasil",sep="")
#     query <- paste(url, "web", "?v=1.0&key=AIzaSyCiIrEo09EM0P9jCFP668j5VicI4Yho-gY&hl=pt_BR&q=", keyword,sep="")
#     
#     results <-  fromJSON(getURL(query))
#     
#     flagencontrou = FALSE
#     url.cache = ""
#     url.urlprincipal = ""
#     empresa.nome <- ""
#     empresa.tamanho <- ""
#     empresa.industria <- "" 
#     empresa.seguidores <- ""
#     empresa.website <- ""
#     empresa.headquarter <- ""
#     
#     count <- length(results$responseData$results)
#     
#     
#     if (count != 0) {
#       for (i in 1:count) {
#         #print(results$responseData$results[[i]]$url)
#         
#         if(length(grep("company",results$responseData$results[[i]]$url )) > 0 && flagencontrou == FALSE) 
#         { 
#           url.cache <- results$responseData$results[[i]]$cacheUrl
#           url.urlprincipal <- results$responseData$results[[i]]$url
#           flagencontrou = TRUE
#         }
#       }
#     }
#     
#     if(url.urlprincipal != "")
#     {
#       
#       site.source <- content(GET(url.cache))
#       site.htmltext <- paste(capture.output(site.source, file=NULL), collapse="\n")
#       documento <- htmlParse(site.htmltext,asText = TRUE)
#       
#       empresa.nome <- xpathApply(documento,"//span[@itemprop='name']" ,xmlValue)
#       empresa.tamanho <- xpathApply(documento,"//p[@class='company-size']" ,xmlValue)
#       empresa.industria <- xpathApply(documento,"//p[@class='industry']" ,xmlValue)
#       empresa.seguidores <- xpathApply(documento,"//p[@class='followers-count']" ,xmlValue)
#       empresa.website <- xpathApply(documento,"//li[@class='website']" ,xmlValue)
#       empresa.headquarter <- xpathApply(documento,"//li[@class='vcard hq']" ,xmlValue)
#       
#       
#       if(length(empresa.nome) == 0) { empresa.nome <- ""  }
#       if(length(empresa.tamanho) == 0) { empresa.tamanho <- ""  }
#       if(length(empresa.industria) == 0) { empresa.industria <- ""  }
#       if(length(empresa.seguidores) == 0) { empresa.seguidores <- ""  }
#       if(length(empresa.website) == 0) { empresa.website <- ""  }
#       if(length(empresa.headquarter) == 0) { empresa.headquarter <- ""  }
#       
#       import <- data.frame(id_empresa = id_empresa, 
#                            nome_empresa = as.character(empresa.nome), 
#                            tamanho = as.character(empresa.tamanho),
#                            industria = as.character(empresa.industria),
#                            seguidores = as.character(empresa.seguidores),
#                            website = as.character(empresa.website),
#                            headquarter = as.character(empresa.headquarter)
#       )
#       
#       import$nome_empresa = gsub("\n"," ",import$nome_empresa)
#       import$tamanho = gsub("\n"," ",import$tamanho)
#       import$industria = gsub("\n"," ",import$industria)
#       import$seguidores = gsub("\n"," ",import$seguidores)
#       import$website = gsub("\n"," ",import$website)
#       import$headquarter = gsub("\n"," ",import$headquarter)
#       # End of linkedin process
#     }
#       
    
    
      # Begin of Google's natural search
      empresa <- gsub("\t","",empresa)
      empresa <- iconv(empresa, to='ASCII//TRANSLIT')
      
      keyword = paste(empresa,"+brasil",sep="")
      
      query <- paste(url, "web", "?v=1.0&key=AIzaSyCiIrEo09EM0P9jCFP668j5VicI4Yho-gY&hl=pt_BR&q=", keyword,sep="")
      
      import_log <- data.frame(ID_EMPRESA = id_empresa,QUERY = query)
      sqlSave(cn,import_log,tablename = "TMP_LOG_ENRIQUECIMENTO_EMPRESAS",append = TRUE)
      
      #Try get Web
      tryCatch(results <-  fromJSON(getURL(query)),error = function(e) error = TRUE )
      
      url_principal <- ""
      
      if(length(results$responseData$results) == 0){
        tamanho_lista <- 0
      }
      else {
        tamanho_lista <- length(list(results$responseData$results))
        }
      
      #Get first Google's result 
      if (exists("results") == TRUE){
        
        if(tamanho_lista == 0 || error == TRUE){
          if (error == FALSE) { 
            url_principal <- "Not found"}
          else {
            url_principal <- "Error found"
          }
        } # Sometimes Google's API don't find anything
        else  {
          
          #if (!is.null(results$responseData$results[[1]]$url) == TRUE && length(grep("wikipedia",results$responseData$results[[1]]$url)) == 0){
          if (tamanho_lista >= 1 && length(grep("wikipedia",results$responseData$results[[1]]$url)) == 0){
                   # url_principal <- results$responseData$results[[1]]$url
                 url_principal <- results$responseData$results[[1]]$url
                    
          }
          
          # case we get Wikipedia as first result we try the second one
          else{
                
            #if (!is.null(results$responseData$results[[2]]$url) == TRUE && 
            if (tamanho_lista > 1 && 
                length(grep("wikipedia",results$responseData$results[[2]]$url)) == 0){ 
              url_principal <- results$responseData$results[[2]]$url
            }
            
            # Maybe the second one also have Wikipedia so we try a last call
            else {
              if(tamanho_lista > 2) {
              url_principal <- results$responseData$results[[3]]$url}
            }
            
          }
          
        }
      }
      else { url_principal <- "Error found" }
      
      if(length(url_principal) == 0) { url_principal <- ""  }
      
      import_google <- data.frame(id_empresa,site =  url_principal)
      # End of Google's natural search
      
      # Case we haven't found linkedin we must create the empty object 
      if (exists("import") == FALSE) {
        import <- data.frame(nome_empresa = "",tamanho = "",industria = "",seguidores = "",website = "",headquarter = "")
      }
      
      # Replace some text 
      import$website <- gsub("Website","",import$website)
      import$seguidores <- gsub("followers","",import$seguidores)
      import$tamanho <- gsub("employees","",import$tamanho)
      import$headquarter <- gsub("Headquarters","",import$headquarter)
#       
#       sqlupdate <- paste(" UPDATE VAGAS_DW.TMP_1000_MAIORES_EMPRESAS ",
#                           " SET FLAG_PROCESSADO = 1, ", 
#                           " WEBSITE_LINKEDIN = '",import$website,"', ",
#                           " QTD_FUNCIONARIOS = '",import$tamanho,"', ",
#                           " SEGUIDORES_LINKEDIN = '",import$seguidores,"', ",
#                           " WEBSITE_PRINCIPAL = '",import_google$site,"', ",
#                           " HEADQUARTER = '",import$headquarter,"' ",
#                           " WHERE CLASSIFICACAO_2014 = ",id_empresa,sep="" )    
#      
#       
      sqlupdate <- paste(" UPDATE VAGAS_DW.TMP_ENRIQUECIMENTO_CONTAS_CRM ",
                         " SET FLAG_PROCESSADO = 1, ", 
                         " WEBSITE_PRINCIPAL = '",import_google$site,"' ",
                         " WHERE ID_EMPRESA_CRM = ",id_empresa,sep="" ) 
      
      # Update company with found informations 
      sqlQuery(cn, sqlupdate)
      
      #wait for 10 sec. for the next execution
      Sys.sleep(10)
      
      # Clear variables and data frame
      error <- FALSE
      flagencontrou <- FALSE
      rm(import)
      rm(import_google)
      
    
  }  

