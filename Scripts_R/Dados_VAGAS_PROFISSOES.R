args <- commandArgs(trailingOnly = TRUE)
Periodo_Inicial <- args[1]
Periodo_Final <- args[2]

library(RGA)

# Access token
authorize(client.id = "1010691091911-70ahpttmv18b2plejqu3anqo721cn63f.apps.googleusercontent.com",client.secret = "abZHcjJ49ub5XTBkpcWusA1n",cache = "M:/Projetos/Scripts_R/Token_Google")

# set id VAGAS PROFISSOES
id <- 89726274

# get data 
Result <- get_ga(id, start.date = Periodo_Inicial,end.date = Periodo_Final,metrics = "ga:users,ga:pageviews,ga:avgSessionDuration,ga:sessions",dimensions = "ga:date,ga:year,ga:month,ga:day")

# treat data
Import = data.frame(Data = as.character(Result$date),Usuarios = Result$users,PageViews = Result$pageviews,Media_Sessao = Result$avg.session.duration,Sessoes = Result$sessions,Ano = Result$year,Mes = Result$month,Dia = Result$day )

# open connection
library(RODBC)
cn <- odbcDriverConnect(connection = "Driver={SQL Server Native Client 11.0};server=SRV-SQLMIRROR02;database=VAGAS_DW;trusted_connection=yes;",interpretDot = FALSE)

# Save Data
sqlClear(cn,"TMP_GOOGLE_VAGAS_PROFISSOES") # First we clear data
sqlSave(cn,Import,tablename = "TMP_GOOGLE_VAGAS_PROFISSOES",append = TRUE)

# We must Get separeted Data from NewReturningVisitor (ga:30dayUsers)
Result <- get_ga(id, start.date = Periodo_Inicial,end.date = Periodo_Final,metrics = "ga:30dayUsers",dimensions = "ga:date")
Import = data.frame(Data = as.character(Result$date),Usuarios = Result$`30day.users` )

library(sqldf)

# We get only last Date by Month
Import <- data.frame(sqldf("SELECT * FROM Import a WHERE Data = (SELECT MAX(Data) FROM Import b WHERE strftime('%Y-%m',b.Data) =  strftime('%Y-%m',a.Data)  ) "))
sqlClear(cn,"TMP_GOOGLE_VAGAS_PROFISSOES_USUARIOS_ATIVOS") # First we clear data
sqlSave(cn,Import,tablename = "TMP_GOOGLE_VAGAS_PROFISSOES_USUARIOS_ATIVOS",append = TRUE)

# Get data from "New Users"
Result <- get_ga(id, start.date = Periodo_Inicial,end.date = Periodo_Final,metrics = "ga:percentNewSessions",dimensions = "ga:year,ga:month")
Import = data.frame(Ano = as.character(Result$year),Mes = as.character(Result$month),Perc_New_Visitor = Result$percent.new.sessions )
sqlClear(cn,"TMP_GOOGLE_VAGAS_PROFISSOES_NOVOS_USUARIOS") # First we clear data
sqlSave(cn,Import,tablename = "TMP_GOOGLE_VAGAS_PROFISSOES_NOVOS_USUARIOS",append =  TRUE)

